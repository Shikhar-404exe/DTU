

library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static EncryptionService? _instance;
  static EncryptionService get instance => _instance ??= EncryptionService._();

  EncryptionService._();

  static const String _encryptionKeyPref = 'app_encryption_key';
  static const String _keyCreatedAtPref = 'encryption_key_created_at';
  static const int _keyRotationDays = 90;

  String? _cachedKey;

  Future<void> initialize() async {
    try {
      await _ensureEncryptionKey();
      debugPrint('✓ Encryption service initialized');
    } catch (e) {
      debugPrint('⚠ Encryption service initialization warning: $e');
    }
  }

  Future<String> encrypt(String plainText) async {
    if (plainText.isEmpty) return '';

    try {
      final key = await _getEncryptionKey();
      final encrypted = _xorEncrypt(plainText, key);
      return base64Encode(utf8.encode(encrypted));
    } catch (e) {
      debugPrint('Encryption error: $e');

      return plainText;
    }
  }

  Future<String> decrypt(String encryptedText) async {
    if (encryptedText.isEmpty) return '';

    try {
      final key = await _getEncryptionKey();
      final decoded = utf8.decode(base64Decode(encryptedText));
      return _xorDecrypt(decoded, key);
    } catch (e) {
      debugPrint('Decryption error: $e');

      return encryptedText;
    }
  }

  Future<String> encryptMap(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    return encrypt(jsonString);
  }

  Future<Map<String, dynamic>> decryptMap(String encryptedData) async {
    try {
      final decrypted = await decrypt(encryptedData);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Map decryption error: $e');
      return {};
    }
  }

  String hash(String data) {
    if (data.isEmpty) return '';

    int hash = 0;
    for (int i = 0; i < data.length; i++) {
      hash = ((hash << 5) - hash) + data.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  String generateSecureToken({int length = 32}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  String maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return email;

    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 2) {
      return '${name[0]}***@$domain';
    }

    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }

  String maskPhone(String phone) {
    if (phone.length < 4) return phone;

    final visible = phone.substring(phone.length - 4);
    final masked = '*' * (phone.length - 4);
    return '$masked$visible';
  }

  Future<bool> needsKeyRotation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final createdAtStr = prefs.getString(_keyCreatedAtPref);

      if (createdAtStr == null) return true;

      final createdAt = DateTime.parse(createdAtStr);
      final daysSinceCreation = DateTime.now().difference(createdAt).inDays;

      return daysSinceCreation >= _keyRotationDays;
    } catch (e) {
      return false;
    }
  }

  Future<void> rotateKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newKey = generateSecureToken(length: 32);

      await prefs.setString(_encryptionKeyPref, newKey);
      await prefs.setString(
          _keyCreatedAtPref, DateTime.now().toIso8601String());

      _cachedKey = newKey;
      debugPrint('✓ Encryption key rotated');
    } catch (e) {
      debugPrint('Key rotation error: $e');
    }
  }

  Future<void> secureWipe() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_encryptionKeyPref);
      await prefs.remove(_keyCreatedAtPref);

      _cachedKey = null;
      debugPrint('✓ Secure wipe completed');
    } catch (e) {
      debugPrint('Secure wipe error: $e');
    }
  }

  Future<void> _ensureEncryptionKey() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(_encryptionKeyPref)) {
      final key = generateSecureToken(length: 32);
      await prefs.setString(_encryptionKeyPref, key);
      await prefs.setString(
          _keyCreatedAtPref, DateTime.now().toIso8601String());
      _cachedKey = key;
    }
  }

  Future<String> _getEncryptionKey() async {
    if (_cachedKey != null) return _cachedKey!;

    final prefs = await SharedPreferences.getInstance();
    _cachedKey = prefs.getString(_encryptionKeyPref) ?? generateSecureToken();
    return _cachedKey!;
  }

  String _xorEncrypt(String text, String key) {
    final result = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final charCode = text.codeUnitAt(i) ^ key.codeUnitAt(i % key.length);
      result.writeCharCode(charCode);
    }
    return result.toString();
  }

  String _xorDecrypt(String encrypted, String key) {

    return _xorEncrypt(encrypted, key);
  }
}

enum SensitiveDataType {
  personalIdentifiable,
  financial,
  health,
  location,
  biometric,
  educational,
}

class DataClassification {

  static bool requiresEncryption(SensitiveDataType type) {
    return true;
  }

  static int getRetentionPeriod(SensitiveDataType type) {
    switch (type) {
      case SensitiveDataType.personalIdentifiable:
        return 365 * 3;
      case SensitiveDataType.financial:
        return 365 * 7;
      case SensitiveDataType.health:
        return 365 * 5;
      case SensitiveDataType.location:
        return 90;
      case SensitiveDataType.biometric:
        return 365;
      case SensitiveDataType.educational:
        return 365 * 10;
    }
  }

  static bool canShareWithThirdParty(SensitiveDataType type) {
    switch (type) {
      case SensitiveDataType.biometric:
      case SensitiveDataType.health:
        return false;
      default:
        return true;
    }
  }
}
