import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

String _saltBytesToHex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Генерация соли и хэш PIN для офлайн‑хранилища SQLite.
class PinCrypto {
  static String generateSaltHex() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return _saltBytesToHex(bytes);
  }

  /// Детерминированный SHA-256 над солью, стабильным ключом аккаунта (`id` из roster) и PIN.
  static String hashPin({
    required String saltHex,
    required String credentialKey,
    required String normalizedPin,
  }) {
    final key = credentialKey.trim().toLowerCase();
    final raw = utf8.encode('$saltHex|$key|$normalizedPin');
    return sha256.convert(raw).toString();
  }

  /// Только цифры; минимум 4 символа.
  static String? normalizeDigits(String pin) {
    final digitsOnly = pin.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 4 ? digitsOnly : null;
  }
}
