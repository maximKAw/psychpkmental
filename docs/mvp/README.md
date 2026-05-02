# Каталог JSON для приложения «Колледж‑круг» (MVP)

Файлы в этой папке предназначены для раздачи через **GitHub Pages** без бэкенда.

## Настройка Pages

В репозитории GitHub откройте **Settings → Pages**, источник: ветка `main`, папка **`/docs`**.

Человекочитаемая оглавная страница: **`index.html`** на Pages откроется как  
`https://<login>.github.io/<repo>/mvp/` (или явно `/mvp/index.html`).

После публикации JSON будут доступны по адресам вида:

```text
https://<ВАШ_ЛОГИН>.github.io/<ИМЯ_РЕПО>/mvp/techniques.json
https://<ВАШ_ЛОГИН>.github.io/<ИМЯ_РЕПО>/mvp/psychologist_tips.json
https://<ВАШ_ЛОГИН>.github.io/<ИМЯ_РЕПО>/mvp/quests.json
https://<ВАШ_ЛОГИН>.github.io/<ИМЯ_РЕПО>/mvp/achievements.json
https://<ВАШ_ЛОГИН>.github.io/<ИМЯ_РЕПО>/mvp/users.json
```

## Регистрация через Google Forms (вариант 1)

Цепочка: **Google Form** → связанная **Google Таблица** → экспорт **CSV** → скрипт `scripts/sync_sheet_to_users_github.py` → **`users.json`** в этом репозитории → **GitHub Pages**.

Поля анкеты (пример названий столбцов в таблице ответов): **Имя**, **Курс/группа**, **Интересы** (можно текстом из чекбоксов), **Желаемый кружок**, **Email**.

Ссылку на форму укажите в приложении через `--dart-define=GOOGLE_FORM_URL=...`.

Скрипт ожидает CSV со строкой заголовков; названия столбцов распознаются по ключевым словам («имя», «email», «курс», «интересы», «кружок»). Для каждого нового email генерируется уникальный `id` (`uuid`), при повторной строке того же email — обновление полей, **идентификатор сохраняется**.

Пример синхронизации в репозиторий:

```powershell
$env:GITHUB_TOKEN = "<token с доступом Contents к репо>"
python scripts/sync_sheet_to_users_github.py `
  --csv-url "https://docs.google.com/spreadsheets/d/<SHEET>/export?format=csv&gid=0" `
  --owner <login> --repo psychpkmental --branch main --path docs/mvp/users.json
```

Просмотреть результат без записи на GitHub: `--csv-file .\export.csv --stdout`.

## Формат `users.json`

Публичный список участников (без PIN). Основное поле — **`id`** (стабильный ключ аккаунта в приложении/SQLite), затем **`email`**, **`displayName`**, **`course`**, **`interests`**, **`desiredClub`**. Поле **`login`** поддерживается для совместимости и альтернативного набора текста входа.

## Подключение в приложении Flutter

При запуске сборки добавьте `--dart-define` с **базовым URL без завершающего слэша** (до каталога `mvp` включительно) и опционально ссылку на форму:

```powershell
cd college_circle
flutter run `
  --dart-define=GH_PAGES_BASE=https://<login>.github.io/<repo>/mvp `
  --dart-define=GOOGLE_FORM_URL=https://docs.google.com/forms/d/e/<id>/viewform
```

При пустой базе приложение работает только с встроенными JSON из `assets/data/`.

## Очередь пользовательских ответов (не GitHub Pages)

Статические страницы GH не принимают POST. Выгрузите ответы студентов приёмником на вашем сервере (Cloud Function, маленький API куратора) и укажите URL в приложении:

```powershell
flutter run --dart-define=OUTBOX_INGEST_URL=https://your.api.example/v1/college-circle-ingest
```

Тело запроса у MVP: один JSON с полем `entries` (см. код `AppRepository.syncPendingOutboxViaHttp`).

## Редактирование

При изменении JSON на сайте приложение получит их по кнопке «Подтянуть каталог JSON» на экране **Сегодня** (слияние с локальными идёт по полю `id`).
