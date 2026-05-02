# «Колледж‑круг» — полная инструкция: APK, iPhone, GitHub, Google Forms

Вся логика приложения — во **Flutter-проекте** `college_circle/`. Корневой модуль `psychpkmental/app` (Java, «Hello World») к этому приложению **не относится**.

---

## 1. Сборка APK (Android)

Откройте терминал и выполните:

```powershell
cd C:\Users\aleks\AndroidStudioProjects\psychpkmental\college_circle
flutter pub get
flutter build apk --release
```

Готовый файл:

`college_circle\build\app\outputs\flutter-apk\app-release.apk`

Его можно отправить студентам по почте/мессенджеру или выложить на диск. При установке Android может спросить разрешение установки **из неизвестных источников** — это нормально для APK не из Google Play.

Опционально: **уменьшенный размер** — отдельный APK под архитектуры:

```powershell
flutter build apk --split-per-abi
```

Появятся файлы `app-armeabi-v7a-release.apk`, `app-arm64-v8a-release.apk` и т.п.

### Если сборка APK упала с ошибкой Kotlin / «Could not delete caches-jvm»

Часто из‑за **двух одновременных** сборок Gradle. Закройте лишние терминалы/IDE-сборки и выполните:

```powershell
cd college_circle\android
.\gradlew.bat --stop
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Если нужен магазин Google Play

Собирают не APK, а **App Bundle**:

```powershell
flutter build appbundle --release
```

Файл: `build\app\outputs\bundle\release\app-release.aab` — его загружают в [Google Play Console](https://play.google.com/console).

---

## 2. «Формат для айфона» (iOS)

На **Windows** собрать установочный файл для iPhone **нельзя**. Apple требует **macOS**, **Xcode** и участие в **Apple Developer Program** (платная подписка), если выкладываете в App Store или раздаёте через TestFlight.

На **Mac**, в папке проекта:

```bash
cd college_circle
flutter pub get
flutter build ipa
```

Дальше загрузка в App Store Connect (Xcode → Organizer или `altool`/`notarytool`). Для теста на своих iPhone обычно используют **TestFlight**.

Альтернативы без своего Mac:

- облачные CI (**Codemagic**, GitHub Actions на macOS-раннере и т.п.) — платно/по тарифам;
- попросить кого‑то с Mac собрать релиз.

Итого: APK вы делаете сами на Windows; **IPA/iOS** — планируйте Mac + Apple-аккаунт или сервис сборки.

---

## 3. Вшить адреса каталога и анкеты в приложение

Приложение читает JSON с сайта только если передать базовый URL при **сборке** (они «вшиваются» в бинарник):

| Параметр | Зачем |
|----------|--------|
| `GH_PAGES_BASE` | Без слэша в конце: `https://ВАШ_ЛОГИН.github.io/ИМЯ_РЕПО/mvp` — отсюда качаются `users.json`, квесты и т.д. |
| `GOOGLE_FORM_URL` | Полная ссылка на **просмотр** формы регистрации (страница, которую открывают студенты). |

Пример сборки APK **с параметрами**:

```powershell
cd college_circle
flutter build apk --release `
  --dart-define=GH_PAGES_BASE=https://login.github.io/repo/mvp `
  --dart-define=GOOGLE_FORM_URL=https://docs.google.com/forms/d/e/XXXXXXXX/viewform
```

Если параметры не задать:

- приложение всё равно работает с **локальными** JSON из `assets/data/` (демо‑данные);
- кнопка анкеты скажет, что не задан `GOOGLE_FORM_URL`;
- удалённый каталог с Pages не подтянется без `GH_PAGES_BASE`.

---

## 4. Разворачивание на GitHub (пошагово, «с нуля»)

### Шаг А. Репозиторий

1. Зайти на https://github.com → **New repository** → создать (например `psychpkmental`).
2. На компьютере в корне проекта (где уже лежит папка `docs`):

   ```powershell
   cd C:\Users\aleks\AndroidStudioProjects\psychpkmental
   git init
   git add .
   git commit -m "Initial college circle MVP"
   git branch -M main
   git remote add origin https://github.com/ВАШ_ЛОГИН/psychpkmental.git
   git push -u origin main
   ```

(Если `git init` уже делали — просто `git add`, `commit`, `push`.)

### Шаг Б. Включить сайт Pages (раздача JSON)

1. Репозиторий на GitHub → **Settings** → **Pages**.
2. **Build and deployment**: Source — **Deploy from a branch**.
3. Branch: **main**, folder: **`/docs`**, Save.

Через 1–3 минуты сайт будет по адресу вида:

`https://ВАШ_ЛОГИН.github.io/psychpkmental/`

Каталог для приложения лежит в **`/mvp/`** (папка `docs/mvp` в репозитории). Проверка в браузере:

`https://ВАШ_ЛОГИН.github.io/psychpkmental/mvp/users.json`

Если JSON открывается — для `GH_PAGES_BASE` используйте **ровно** (без слэша в конце):

`https://ВАШ_ЛОГИН.github.io/psychpkmental/mvp`

### Шаг В. Обновление данных после правок

Любое изменение файлов в `docs/mvp/*.json` в ветке `main` → GitHub пересоберёт Pages → приложение при «Подтянуть каталог» на экране **Сегодня** получит новые данные.

---

## 5. Google Forms — объяснение «для не в теме»

### Что это

**Google Формы** — бесплатный сервис: вы делаете страницу с вопросами, даёте ссылку студентам, они отвечают с телефона или компьютера. Ответы **сами складываются** в **Google Таблицу** (как Excel онлайн). Вам не нужен свой сервер, чтобы **собрать заявки**.

### Зачем это приложению

Приложение **не читает** таблицу напрямую. Цепочка такая:

1. Студент жмёт в приложении **«Заполнить анкету»** → открывается **та же** форма, что вы создали (ссылка `GOOGLE_FORM_URL`).
2. Студент отправил ответ → строка появилась в **таблице**.
3. **Куратор** (вы или техспец) периодически запускает **скрипт** `scripts/sync_sheet_to_users_github.py`: он читает таблицу как **CSV**, формирует **`users.json`**, пушит в GitHub → после публикации Pages приложение видит нового человека в списке.
4. Студент в приложении: **подтянуть каталог** → **войти** по email/имени и задать PIN на устройстве.

Пароли в Google Form **не нужны** для входа в приложение: там только **PIN на телефоне** + проверка, что человек есть в `users.json`.

### Как сделать форму (кратко)

1. https://forms.google.com → **Пустая форма**.
2. Добавьте вопросы (тип «краткий ответ» или «абзац» там, где нужен длинный текст):
   - **Имя** (как в паспорте / как хотите видеть в приложении),
   - **Курс / группа**,
   - **Интересы** (можно один вопрос с вариантами-чекбоксами или текстом),
   - **Желаемый кружок**,
   - **Email** (обязательно — по нему проще однозначно входить).
3. Вкладка **Ответы** → значок **зелёной таблицы** «Создать таблицу» → привязать новый лист. Теперь каждый ответ = строка таблицы.
4. Меню **Отправить** → скопировать **ссылку на форму** — это и есть типичный **`GOOGLE_FORM_URL`** для `--dart-define` (страница с вопросами).

### Откуда взять CSV для скрипта

Варианты:

- В открытой **таблице**: **Файл → Загрузить → CSV** (ручное скачивание), затем  
  `python scripts/sync_sheet_to_users_github.py --csv-file ответы.csv ...`
- Или постоянная ссылка экспорта (зависит от настроек доступа Google). В комментарии внутри файла `sync_sheet_to_users_github.py` описан общий вид URL.

Скрипт ищет столбцы по словам в заголовках: «имя», «email», «курс», «интересы», «кружок» (русские и английские варианты).

### GitHub-токен для скрипта

Создайте **Personal Access Token** (или fine-grained) с правом менять содержимое репозитория (контент файлов), положите в переменную окружения **`GITHUB_TOKEN`**, затем запуск скрипта с `--owner`, `--repo`, `--path docs/mvp/users.json`, как в `docs/mvp/README.md`.

Это нужно **одному человеку** с правами на репозиторий, не студентам.

---

## 6. Краткий чеклист «всё завелось»

- [ ] Репозиторий на GitHub, в нём есть `docs/mvp/*.json`.
- [ ] Pages включены, в браузере открывается `.../mvp/users.json`.
- [ ] Собран APK с верными `--dart-define=GH_PAGES_BASE=...` и при необходимости `GOOGLE_FORM_URL`.
- [ ] Форма создана, ответы идут в таблицу, ссылка на форму совпадает с тем, что вшита в приложение.
- [ ] После новых анкет куратор обновляет `users.json` скриптом (или вручную правит JSON и пушит).
- [ ] Студент в приложении: анкета → потом «Подтянуть каталог» на **Сегодня** → вход.

---

Если что‑то из шагов «ломается», обычно проверяют: правиль ли скопирован `GH_PAGES_BASE` (без лишнего слэша), открылся ли `users.json` в браузере, попала ли новая строка в таблицу после отправки формы.
