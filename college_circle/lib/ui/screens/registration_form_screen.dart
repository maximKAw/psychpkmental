import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../config/app_config.dart';

/// Анкета Google Forms: на телефоне — во встроенном WebView, иначе — во внешнем браузере.
class RegistrationFormScreen extends StatefulWidget {
  const RegistrationFormScreen({super.key});

  @override
  State<RegistrationFormScreen> createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  WebViewController? _web;

  Uri get _formUri => Uri.parse(kGoogleRegistrationFormUrl.trim());

  bool get _useEmbedded =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_useEmbedded) {
      _web = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(_formUri);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        launchUrl(_formUri, mode: LaunchMode.externalApplication);
      });
    }
  }

  Future<void> _openExternal() =>
      launchUrl(_formUri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        actions: [
          IconButton(
            tooltip: 'Открыть во внешнем браузере',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: _openExternal,
          ),
        ],
      ),
      body: _useEmbedded && _web != null
          ? WebViewWidget(controller: _web!)
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.article_outlined, size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      kIsWeb
                          ? 'Заполните анкету Google Forms во встроенном браузере.'
                          : 'На этом типе устройства форма открывается во внешнем браузере.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _openExternal,
                      icon: const Icon(Icons.launch_rounded),
                      label: const Text('Открыть анкету'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
