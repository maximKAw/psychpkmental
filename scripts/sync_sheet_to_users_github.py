#!/usr/bin/env python3
"""
Синхронизация ответов Google Forms из Google Sheet (экспорт CSV) в users.json на GitHub.

1) Создайте форму (Имя, Курс/группа, Интересы, Желаемый кружок, Email) и привяжите ответы к таблице.
2) Возьмите ссылку экспорта CSV: в таблице «Файл → Поделиться → доступ по ссылке» или экспорт через URL:
     https://docs.google.com/spreadsheets/d/<SHEET_ID>/export?format=csv&gid=<GID>

3) Коммит в репозиторий (личный доступ token или fine-grained с правом Contents: Read/Write):
     set GITHUB_TOKEN=...
     python scripts/sync_sheet_to_users_github.py --csv-url "<CSV_URL>" --owner YOU --repo REPO --branch main

Только напечатать результат:
     python scripts/sync_sheet_to_users_github.py --csv-file answers.csv --stdout

Зависимости: только стандартная библиотека Python 3.10+
"""
from __future__ import annotations

import argparse
import base64
import csv
import io
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
from typing import Dict, Iterable, List, Mapping, MutableMapping, Optional, Tuple

ALIASES: Dict[str, Tuple[str, ...]] = {
    "name": ("имя", "name", "фио"),
    "email": ("email", "e-mail", "почта", "электронная почта"),
    "course": ("курс", "группа", "курс/группа", "course"),
    "interests": ("интересы", "interests", "увлечения"),
    "club": ("желаемый кружок", "кружок", "desired club", "club", "desired_club"),
}


def normalize_header(s: str) -> str:
    return re.sub(r"\s+", " ", (s or "").strip().lower())


def slug_email(email: str) -> str:
    return email.strip().lower()


class SheetRow:
    __slots__ = ("name", "course", "interests", "club", "email")

    def __init__(self, name: str, course: str, interests: str, club: str, email: str):
        self.name = name.strip()
        self.course = course.strip()
        self.interests = interests.strip()
        self.club = club.strip()
        self.email = slug_email(email)


def fetch_text(url: str, timeout: int = 60) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": "college-circle-sync/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read()
    enc = getattr(resp.headers, "get_content_charset", lambda: None)() or "utf-8"
    try:
        return raw.decode(enc)
    except UnicodeDecodeError:
        return raw.decode("utf-8", errors="replace")


def resolve_columns(fieldnames: List[str]) -> Dict[str, int]:
    normed = [normalize_header(f) for f in fieldnames]
    out: Dict[str, int] = {}
    for key, synonyms in ALIASES.items():
        idx = None
        for i, h in enumerate(normed):
            if any(syn == h or syn in h or h.endswith(syn) for syn in synonyms):
                idx = i
                break
        if idx is None:
            sys.exit(f"Не найден столбец для «{key}». Заголовки: {fieldnames}")
        out[key] = idx
    return out


def read_sheet_rows(text: str) -> List[SheetRow]:
    stream = io.StringIO(text.lstrip("\ufeff"))
    r = csv.reader(stream)
    headers = next(r, None)
    if not headers:
        return []
    col = resolve_columns(headers)
    rows: List[SheetRow] = []
    for line in r:
        if not line or not any((c or "").strip() for c in line):
            continue

        def cell(k: str) -> str:
            i = col[k]
            return line[i] if i < len(line) else ""

        mail = cell("email").strip()
        if not mail:
            continue
        rows.append(
            SheetRow(cell("name"), cell("course"), cell("interests"), cell("club"), mail),
        )
    return rows


def load_existing(blob: Mapping[str, object]) -> Tuple[List[MutableMapping[str, object]], Dict[str, str]]:
    items_raw = blob.get("items")
    items_out: List[MutableMapping[str, object]] = []
    email_to_id: Dict[str, str] = {}
    if not isinstance(items_raw, list):
        return items_out, email_to_id
    for raw in items_raw:
        if not isinstance(raw, dict):
            continue
        row: MutableMapping[str, object] = dict(raw)
        oid = str(row.get("id", "")).strip().lower()
        em = slug_email(str(row.get("email", "")))
        if em and oid:
            email_to_id[em] = oid
        if not oid:
            oid = fallback_id(em) if em else str(uuid.uuid4())
            row["id"] = oid
        if em and em not in email_to_id:
            email_to_id[em] = oid
        items_out.append(row)
    return items_out, email_to_id


def fallback_id(email: str) -> str:
    h = 0
    for c in email:
        h = ((h * 131) ^ ord(c)) & 0x7FFFFFFF
    return f"em_{abs(hash(email))}_{h:x}"


def merge_sheet_into_items(
    sheet: Iterable[SheetRow],
    items: List[MutableMapping[str, object]],
    email_to_id: Dict[str, str],
) -> None:
    by_email = {slug_email(str(x.get("email", ""))): x for x in items if str(x.get("email", "")).strip()}

    for sr in sheet:
        existing = by_email.get(sr.email)
        uid = email_to_id.get(sr.email)
        if existing is not None:
            ex_id = str(existing.get("id", "")).strip().lower()
            if ex_id:
                uid = ex_id
        if not uid:
            uid = str(uuid.uuid4())
        email_to_id[sr.email] = uid

        patch = {
            "id": uid,
            "email": sr.email,
            "displayName": sr.name,
            "course": sr.course,
            "interests": sr.interests,
            "desiredClub": sr.club,
        }

        cur = by_email.get(sr.email)
        if cur is None:
            cur = dict(patch)
            items.append(cur)
            by_email[sr.email] = cur
        else:
            cur.update(patch)


def q_github_path(path: str) -> str:
    return "/".join(urllib.parse.quote(p, safe="") for p in path.strip("/").split("/"))


def github_headers(token: str) -> Dict[str, str]:
    return {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
        "X-GitHub-Api-Version": "2022-11-28",
    }


def github_get_json(url: str, token: str) -> Tuple[int, dict]:
    req = urllib.request.Request(url, headers=github_headers(token))
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            body = resp.read().decode()
            return resp.status, json.loads(body or "{}")
    except urllib.error.HTTPError as he:
        err_body = he.read().decode(errors="replace")
        try:
            return he.code, json.loads(err_body or "{}")
        except json.JSONDecodeError:
            return he.code, {"message": err_body}


def gh_contents_url(owner: str, repo: str, path: str, ref: Optional[str]) -> str:
    q = q_github_path(path)
    base = f"https://api.github.com/repos/{urllib.parse.quote(owner, safe='')}/{urllib.parse.quote(repo, safe='')}/contents/{q}"
    return f"{base}?ref={urllib.parse.quote(ref)}" if ref else base


def fetch_remote_users_json(token: str, owner: str, repo: str, path: str, branch: str) -> Tuple[Optional[str], dict]:
    """Возвращает (sha или None если файла нет), объект JSON."""
    code, data = github_get_json(
        gh_contents_url(owner, repo, path, branch),
        token,
    )
    if code == 404:
        return None, {"schemaVersion": 2, "items": []}
    if code >= 400:
        sys.exit(f"GitHub GET users.json HTTP {code}: {data}")

    sha = data.get("sha") if isinstance(data, dict) else None
    b64 = (data.get("content") or "") if isinstance(data, dict) else ""
    raw = base64.b64decode("".join(b64.split())).decode("utf-8") if b64 else "{}"
    try:
        return str(sha) if sha else None, json.loads(raw)
    except json.JSONDecodeError:
        print("Warning: удалённый users.json не JSON — перезаписываем с нуля.", file=sys.stderr)
        return str(sha) if sha else None, {"schemaVersion": 2, "items": []}


def gh_put(owner: str, repo: str, path: str, branch: str, token: str, message: str, body: bytes, sha: Optional[str]) -> None:
    q = q_github_path(path)
    url = f"https://api.github.com/repos/{urllib.parse.quote(owner, safe='')}/{urllib.parse.quote(repo, safe='')}/contents/{q}"
    payload = {
        "message": message,
        "content": base64.b64encode(body).decode("ascii"),
        "branch": branch,
    }
    if sha:
        payload["sha"] = sha
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        url,
        data=data,
        headers={**github_headers(token), "Content-Type": "application/json"},
        method="PUT",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        if resp.status not in (200, 201):
            sys.exit(f"GitHub PUT failed HTTP {resp.status}")


def main() -> None:
    ap = argparse.ArgumentParser(description="CSV (Google Sheet) → users.json → GitHub")
    ap.add_argument("--csv-url", help="URL экспорта Google Sheet CSV")
    ap.add_argument("--csv-file", help="Локальный CSV файл")
    ap.add_argument("--stdout", action="store_true")
    ap.add_argument("--owner", default="")
    ap.add_argument("--repo", default="")
    ap.add_argument("--branch", default="main")
    ap.add_argument("--path", default="docs/mvp/users.json")
    ap.add_argument("--commit-message", default="chore: sync users.json from Google Sheet CSV")
    args = ap.parse_args()

    import os

    if not args.csv_url and not args.csv_file:
        ap.error("Нужно указать --csv-url или --csv-file")

    if args.stdout and (args.csv_file is None and args.csv_url is None):
        ap.error("--stdout нужен источник CSV")

    text = (
        fetch_text(args.csv_url)
        if args.csv_url
        else open(args.csv_file, encoding="utf-8").read()  # type: ignore[arg-type]
    )
    sheet_rows = read_sheet_rows(text)

    blob: Mapping[str, object] = {"schemaVersion": 2, "items": []}
    remote_sha: Optional[str] = None

    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if not args.stdout:
        if not token or not args.owner or not args.repo:
            ap.error("Для загрузки в GitHub нужны GITHUB_TOKEN, --owner и --repo (или --stdout).")
        remote_sha, blob = fetch_remote_users_json(token, args.owner.strip(), args.repo.strip(), args.path, args.branch)

    items, email_map = load_existing(blob)
    merge_sheet_into_items(sheet_rows, items, email_map)
    ordered = sorted(items, key=lambda x: str(x.get("id", "")))

    out = {"schemaVersion": 2, "items": ordered}
    body_bytes = json.dumps(out, ensure_ascii=False, indent=2).encode("utf-8")

    if args.stdout:
        sys.stdout.buffer.write(body_bytes)
        return

    gh_put(
        owner=args.owner.strip(),
        repo=args.repo.strip(),
        path=args.path,
        branch=args.branch.strip(),
        token=token,
        message=args.commit_message,
        body=body_bytes,
        sha=remote_sha,
    )
    print(f"OK → {args.owner}/{args.repo} {args.path} ({len(ordered)} строк). После сборки Pages обновится users.json.")


if __name__ == "__main__":
    main()
