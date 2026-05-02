/// Базовый URL каталога JSON на GitHub Pages (HTTPS, без завершающего `/`).
///
/// После включения Pages для ветки `main` и папки `/docs` файлы будут доступны как:
/// `https://<user>.github.io/<repo>/mvp/quests.json`
///
/// Передайте свой URL через `--dart-define=GH_PAGES_BASE=https://example.github.io/repo/mvp`
/// или временно измените значение ниже для отладки.
const String kGithubPagesJsonBase = String.fromEnvironment(
  'GH_PAGES_BASE',
  defaultValue: '',
);

bool get hasRemoteCatalog => kGithubPagesJsonBase.trim().isNotEmpty;

String remoteUrl(String filename) =>
    '${kGithubPagesJsonBase.trim().replaceAll(RegExp(r'/$'), '')}/$filename';

/// Полная HTTPS-ссылка на вашу анкету Google Forms («Вариант 1» регистрация).
///
/// Передайте через `--dart-define=GOOGLE_FORM_URL=https://docs.google.com/forms/d/e/<id>/viewform`
/// или временно подставьте значение здесь для отладки.
const String kGoogleRegistrationFormUrl = String.fromEnvironment('GOOGLE_FORM_URL', defaultValue: '');

bool get hasRegistrationFormUrl => kGoogleRegistrationFormUrl.trim().isNotEmpty;

/// URL приёма офлайн-очереди (POST JSON). Пример: ваш Cloud Function или сервер колледжа.
/// Пустое значение — только локальное накопление и ручное «принято» из экрана очереди.
const String kOutboxIngestUrl = String.fromEnvironment('OUTBOX_INGEST_URL', defaultValue: '');

bool get hasOutboxIngestUrl => kOutboxIngestUrl.trim().isNotEmpty;
