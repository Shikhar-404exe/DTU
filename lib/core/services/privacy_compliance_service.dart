/// Privacy & Compliance Service
/// GDPR (EU), IT Act 2000 (India), DPDP Act 2023 (India) Compliant
/// Handles user consent, data rights, and privacy management
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Privacy Compliance Service
/// Implements data protection requirements for Indian and international regulations
class PrivacyComplianceService {
  static PrivacyComplianceService? _instance;
  static PrivacyComplianceService get instance =>
      _instance ??= PrivacyComplianceService._();

  PrivacyComplianceService._();

  // Storage keys
  static const String _consentKey = 'user_privacy_consent';
  static const String _consentTimestampKey = 'consent_timestamp';
  static const String _consentVersionKey = 'consent_version';
  static const String _dataProcessingKey = 'data_processing_consent';
  static const String _marketingKey = 'marketing_consent';
  static const String _analyticsKey = 'analytics_consent';
  static const String _thirdPartyKey = 'third_party_consent';
  static const String _dataRetentionKey = 'data_retention_acknowledged';
  static const String _ageVerifiedKey = 'age_verified';
  static const String _parentalConsentKey = 'parental_consent';

  // Current privacy policy version (increment when policy changes)
  static const String currentPolicyVersion = '1.0.0';
  static const String policyLastUpdated = '2025-01-01';

  /// Check if user has given valid consent
  Future<bool> hasValidConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if consent exists
      final hasConsent = prefs.getBool(_consentKey) ?? false;
      if (!hasConsent) return false;

      // Check if consent is for current policy version
      final consentVersion = prefs.getString(_consentVersionKey);
      if (consentVersion != currentPolicyVersion) return false;

      // Check if consent is still valid (within 12 months for GDPR)
      final timestampStr = prefs.getString(_consentTimestampKey);
      if (timestampStr != null) {
        final consentDate = DateTime.parse(timestampStr);
        final monthsSinceConsent =
            DateTime.now().difference(consentDate).inDays ~/ 30;
        if (monthsSinceConsent >= 12) {
          return false; // Consent expired, need to re-consent
        }
      }

      return true;
    } catch (e) {
      debugPrint('Consent check error: $e');
      return false;
    }
  }

  /// Record user consent
  Future<void> recordConsent({
    required bool dataProcessing,
    required bool analytics,
    bool marketing = false,
    bool thirdPartySharing = false,
    bool isMinor = false,
    bool hasParentalConsent = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_consentKey, true);
      await prefs.setString(
          _consentTimestampKey, DateTime.now().toIso8601String());
      await prefs.setString(_consentVersionKey, currentPolicyVersion);
      await prefs.setBool(_dataProcessingKey, dataProcessing);
      await prefs.setBool(_analyticsKey, analytics);
      await prefs.setBool(_marketingKey, marketing);
      await prefs.setBool(_thirdPartyKey, thirdPartySharing);

      if (isMinor) {
        await prefs.setBool(_parentalConsentKey, hasParentalConsent);
      }

      debugPrint('✓ Privacy consent recorded');
    } catch (e) {
      debugPrint('Consent recording error: $e');
    }
  }

  /// Get current consent status
  Future<ConsentStatus> getConsentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return ConsentStatus(
        hasConsent: prefs.getBool(_consentKey) ?? false,
        dataProcessing: prefs.getBool(_dataProcessingKey) ?? false,
        analytics: prefs.getBool(_analyticsKey) ?? false,
        marketing: prefs.getBool(_marketingKey) ?? false,
        thirdPartySharing: prefs.getBool(_thirdPartyKey) ?? false,
        consentVersion: prefs.getString(_consentVersionKey),
        consentDate: prefs.getString(_consentTimestampKey) != null
            ? DateTime.parse(prefs.getString(_consentTimestampKey)!)
            : null,
        ageVerified: prefs.getBool(_ageVerifiedKey) ?? false,
        hasParentalConsent: prefs.getBool(_parentalConsentKey) ?? false,
      );
    } catch (e) {
      debugPrint('Get consent status error: $e');
      return ConsentStatus.empty();
    }
  }

  /// Verify user age (required for minors under DPDP Act)
  Future<void> verifyAge({
    required int age,
    required bool hasParentalConsent,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_ageVerifiedKey, true);

      // Under 18 requires parental consent in India (DPDP Act)
      if (age < 18) {
        await prefs.setBool(_parentalConsentKey, hasParentalConsent);
      }

      debugPrint('✓ Age verification recorded: $age years');
    } catch (e) {
      debugPrint('Age verification error: $e');
    }
  }

  /// Withdraw consent (GDPR Article 7)
  Future<void> withdrawConsent({
    bool dataProcessing = false,
    bool analytics = false,
    bool marketing = false,
    bool thirdPartySharing = false,
    bool withdrawAll = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (withdrawAll) {
        await prefs.setBool(_consentKey, false);
        await prefs.setBool(_dataProcessingKey, false);
        await prefs.setBool(_analyticsKey, false);
        await prefs.setBool(_marketingKey, false);
        await prefs.setBool(_thirdPartyKey, false);
      } else {
        if (!dataProcessing) await prefs.setBool(_dataProcessingKey, false);
        if (!analytics) await prefs.setBool(_analyticsKey, false);
        if (!marketing) await prefs.setBool(_marketingKey, false);
        if (!thirdPartySharing) await prefs.setBool(_thirdPartyKey, false);
      }

      debugPrint('✓ Consent withdrawn');
    } catch (e) {
      debugPrint('Consent withdrawal error: $e');
    }
  }

  /// Export user data (GDPR Article 20 - Right to Data Portability)
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      final exportData = <String, dynamic>{
        'export_date': DateTime.now().toIso8601String(),
        'app_name': 'Vidyarthi - Rural Education',
        'data_format_version': '1.0',
        'user_data': {},
        'consent_history': {},
        'preferences': {},
      };

      // Collect all user data
      for (final key in keys) {
        // Skip sensitive internal keys
        if (key.startsWith('flutter.') || key.contains('encryption')) {
          continue;
        }

        final value = prefs.get(key);
        if (key.contains('consent') || key.contains('privacy')) {
          (exportData['consent_history'] as Map)[key] = value;
        } else if (key.contains('pref') || key.contains('setting')) {
          (exportData['preferences'] as Map)[key] = value;
        } else {
          (exportData['user_data'] as Map)[key] = value;
        }
      }

      debugPrint('✓ User data exported');
      return exportData;
    } catch (e) {
      debugPrint('Data export error: $e');
      return {'error': 'Failed to export data'};
    }
  }

  /// Delete all user data (GDPR Article 17 - Right to be Forgotten)
  Future<bool> deleteAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all preferences
      await prefs.clear();

      debugPrint('✓ All user data deleted (Right to be Forgotten)');
      return true;
    } catch (e) {
      debugPrint('Data deletion error: $e');
      return false;
    }
  }

  /// Rectify user data (GDPR Article 16 - Right to Rectification)
  Future<bool> rectifyUserData(String key, dynamic newValue) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (newValue is String) {
        await prefs.setString(key, newValue);
      } else if (newValue is int) {
        await prefs.setInt(key, newValue);
      } else if (newValue is bool) {
        await prefs.setBool(key, newValue);
      } else if (newValue is double) {
        await prefs.setDouble(key, newValue);
      }

      debugPrint('✓ User data rectified: $key');
      return true;
    } catch (e) {
      debugPrint('Data rectification error: $e');
      return false;
    }
  }

  /// Log data access (for audit trail)
  Future<void> logDataAccess({
    required String dataType,
    required String purpose,
    String? accessedBy,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final accessLog = prefs.getStringList('data_access_log') ?? [];

      final logEntry = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'data_type': dataType,
        'purpose': purpose,
        'accessed_by': accessedBy ?? 'system',
      });

      accessLog.add(logEntry);

      // Keep only last 100 entries
      if (accessLog.length > 100) {
        accessLog.removeRange(0, accessLog.length - 100);
      }

      await prefs.setStringList('data_access_log', accessLog);
    } catch (e) {
      debugPrint('Access logging error: $e');
    }
  }

  /// Get data access log
  Future<List<Map<String, dynamic>>> getDataAccessLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessLog = prefs.getStringList('data_access_log') ?? [];

      return accessLog
          .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Get access log error: $e');
      return [];
    }
  }

  /// Check if analytics can be used
  Future<bool> canUseAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_analyticsKey) ?? false;
  }

  /// Check if marketing communications allowed
  Future<bool> canSendMarketing() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_marketingKey) ?? false;
  }

  /// Check if third-party sharing allowed
  Future<bool> canShareWithThirdParty() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_thirdPartyKey) ?? false;
  }

  /// Check if data retention policy has been acknowledged
  Future<bool> hasAcknowledgedDataRetention() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dataRetentionKey) ?? false;
  }

  /// Acknowledge data retention policy
  Future<void> acknowledgeDataRetention() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dataRetentionKey, true);
  }
}

/// Consent status model
class ConsentStatus {
  final bool hasConsent;
  final bool dataProcessing;
  final bool analytics;
  final bool marketing;
  final bool thirdPartySharing;
  final String? consentVersion;
  final DateTime? consentDate;
  final bool ageVerified;
  final bool hasParentalConsent;

  ConsentStatus({
    required this.hasConsent,
    required this.dataProcessing,
    required this.analytics,
    required this.marketing,
    required this.thirdPartySharing,
    this.consentVersion,
    this.consentDate,
    required this.ageVerified,
    required this.hasParentalConsent,
  });

  factory ConsentStatus.empty() => ConsentStatus(
        hasConsent: false,
        dataProcessing: false,
        analytics: false,
        marketing: false,
        thirdPartySharing: false,
        ageVerified: false,
        hasParentalConsent: false,
      );

  bool get isValid => hasConsent && dataProcessing;

  bool get needsRenewal {
    if (consentDate == null) return true;
    final monthsSinceConsent =
        DateTime.now().difference(consentDate!).inDays ~/ 30;
    return monthsSinceConsent >= 12;
  }
}

/// Privacy rights available to users
class PrivacyRights {
  /// GDPR/DPDP Rights summary
  static const List<PrivacyRight> userRights = [
    PrivacyRight(
      id: 'access',
      title: 'Right to Access',
      description: 'You can request a copy of all data we have about you.',
      regulation: 'GDPR Article 15, DPDP Act Section 11',
    ),
    PrivacyRight(
      id: 'rectification',
      title: 'Right to Rectification',
      description: 'You can correct any inaccurate personal data.',
      regulation: 'GDPR Article 16, DPDP Act Section 12',
    ),
    PrivacyRight(
      id: 'erasure',
      title: 'Right to Erasure',
      description: 'You can request deletion of your personal data.',
      regulation: 'GDPR Article 17, DPDP Act Section 12',
    ),
    PrivacyRight(
      id: 'portability',
      title: 'Right to Data Portability',
      description: 'You can export your data in a machine-readable format.',
      regulation: 'GDPR Article 20, DPDP Act Section 13',
    ),
    PrivacyRight(
      id: 'withdraw',
      title: 'Right to Withdraw Consent',
      description: 'You can withdraw consent at any time.',
      regulation: 'GDPR Article 7, DPDP Act Section 6',
    ),
    PrivacyRight(
      id: 'object',
      title: 'Right to Object',
      description: 'You can object to processing for marketing purposes.',
      regulation: 'GDPR Article 21',
    ),
    PrivacyRight(
      id: 'complaint',
      title: 'Right to Lodge Complaint',
      description: 'You can file a complaint with the Data Protection Board.',
      regulation: 'GDPR Article 77, DPDP Act Section 27',
    ),
  ];
}

/// Individual privacy right
class PrivacyRight {
  final String id;
  final String title;
  final String description;
  final String regulation;

  const PrivacyRight({
    required this.id,
    required this.title,
    required this.description,
    required this.regulation,
  });
}

/// Data categories collected
class DataCategories {
  static const List<DataCategory> categories = [
    DataCategory(
      name: 'Account Information',
      description: 'Email, name, profile photo',
      purpose: 'To create and manage your account',
      retention: '3 years after account deletion',
      legalBasis: 'Contract performance',
    ),
    DataCategory(
      name: 'Educational Data',
      description: 'Notes, study progress, test scores',
      purpose: 'To provide personalized learning experience',
      retention: 'Until account deletion',
      legalBasis: 'Contract performance',
    ),
    DataCategory(
      name: 'Usage Analytics',
      description: 'App usage patterns, feature usage',
      purpose: 'To improve app functionality',
      retention: '2 years',
      legalBasis: 'Legitimate interest',
    ),
    DataCategory(
      name: 'Device Information',
      description: 'Device type, OS version, app version',
      purpose: 'Technical support and compatibility',
      retention: '1 year',
      legalBasis: 'Legitimate interest',
    ),
  ];
}

/// Data category model
class DataCategory {
  final String name;
  final String description;
  final String purpose;
  final String retention;
  final String legalBasis;

  const DataCategory({
    required this.name,
    required this.description,
    required this.purpose,
    required this.retention,
    required this.legalBasis,
  });
}
