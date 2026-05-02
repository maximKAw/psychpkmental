## Колледж-круг (`college_circle`)

Кроссплатформенный клиент на Flutter (Android 8+, iOS 14+ по ТЗ). Нативный черновой проект Kotlin в каталоге `../app/` можно оставить как справку или удалить после переноса логики.

### Требования

- [Flutter](https://docs.flutter.dev/get-started/install/windows) (канал stable)
- для Android — Android SDK (через Android Studio)
- для iOS сборки на macOS — Xcode

Проверка: `flutter doctor -v`.

SDK на этой машине установлен в `C:\Users\aleks\dev\flutter`; каталог `bin` добавлен в **PATH пользователя**. В уже открытых терминалах IDE перезапустите сессию или выполните:

```powershell
$env:PATH = "C:\Users\aleks\dev\flutter\bin;$env:PATH"
```

### Платформы

Каталоги `android/` и `ios/` уже сгенерированы (`flutter create ...`). Пересоздавать не нужно, если не меняете имя пакета или организацию.

### Целевые версии по ТЗ

- **Android:** в `android/app/build.gradle.kts` задано `minSdk = maxOf(flutter.minSdkVersion, 26)` (Android 8.0+).
- **iOS:** в `ios/Runner.xcodeproj/project.pbxproj` выставлено `IPHONEOS_DEPLOYMENT_TARGET = 14.0`. На macOS при появлении `Podfile`/`Podfile.lock` при необходимости подтвердите ту же версию там.

После изменений Gradle/CocoaPods:

```powershell
flutter clean
flutter pub get
```

### Запуск

```powershell
flutter devices
flutter run
```

### Сборка APK / iPhone, GitHub и Google Forms

Пошаговая инструкция на русском: **[`docs/COLLEGE_CIRCLE_POLNAYA_INSTRUKCIYA.md`](../docs/COLLEGE_CIRCLE_POLNAYA_INSTRUKCIYA.md)**  
(APK на Windows; для iPhone нужен Mac или облачная сборка.)

### MVP (SQLite + GitHub Pages / JSON)

- **Локально:** профиль пользователя, задания/квесты, прогресс техник, журнал активности для игр и галерея достижений — в **SQLite** (`AppDatabase`, версия **3**: авторизация whitelist + PIN, таблица `sync_outbox` и др.).
- **Очередь ответов:** заметки к заданиям, техники, советы и снимки профиля складываются в `sync_outbox`; отправка одиночным POST на **`OUTBOX_INGEST_URL`** или ручное «принято» в экране «Очередь ответов».
- **Контент:** `assets/data/*.json` и зеркально **`../docs/mvp/*.json`** (+ **`index.html`**) для **GitHub Pages** (см. `docs/mvp/README.md`).
- **Подтягивание с сайта:** кнопка на экране «Сегодня», база URL:

```powershell
flutter run `
  --dart-define=GH_PAGES_BASE=https://<login>.github.io/<repo>/mvp `
  --dart-define=OUTBOX_INGEST_URL=https://your.api.example/receive-college-circle
```
