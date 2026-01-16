

library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../core/services/privacy_compliance_service.dart';
import '../core/services/encryption_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _privacyService = PrivacyComplianceService.instance;
  final _encryptionService = EncryptionService.instance;

  ConsentStatus? _consentStatus;
  bool _isLoading = true;
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadConsentStatus();
  }

  Future<void> _loadConsentStatus() async {
    final status = await _privacyService.getConsentStatus();
    if (mounted) {
      setState(() {
        _consentStatus = status;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data'),
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        foregroundColor: isDark ? AppColors.textDarkMode : AppColors.textDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _buildConsentStatusCard(isDark),
                  const SizedBox(height: 20),

                  _buildSectionTitle('Consent Preferences', isDark),
                  const SizedBox(height: 12),
                  _buildConsentPreferences(isDark),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Your Data Rights', isDark),
                  const SizedBox(height: 12),
                  _buildDataRightsSection(isDark),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Security', isDark),
                  const SizedBox(height: 12),
                  _buildSecurityInfo(isDark),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Danger Zone', isDark),
                  const SizedBox(height: 12),
                  _buildDangerZone(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textDarkMode : AppColors.textDark,
      ),
    );
  }

  Widget _buildConsentStatusCard(bool isDark) {
    final status = _consentStatus ?? ConsentStatus.empty();
    final isValid = status.isValid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isValid
              ? [AppColors.mint.withAlpha(51), AppColors.mint.withAlpha(26)]
              : [Colors.orange.withAlpha(51), Colors.orange.withAlpha(26)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid ? AppColors.mint : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isValid ? AppColors.teal : Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isValid ? Icons.verified_user_rounded : Icons.warning_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isValid ? 'Privacy Consent Active' : 'Consent Needed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.consentDate != null
                      ? 'Given on ${_formatDate(status.consentDate!)}'
                      : 'No consent recorded',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark ? AppColors.textLightDark : AppColors.textLight,
                  ),
                ),
                if (status.needsRenewal)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Consent renewal required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentPreferences(bool isDark) {
    final status = _consentStatus ?? ConsentStatus.empty();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withAlpha(13),
        ),
      ),
      child: Column(
        children: [
          _buildConsentToggle(
            isDark: isDark,
            title: 'Essential Data Processing',
            subtitle: 'Required for app functionality',
            value: status.dataProcessing,
            enabled: false,
            icon: Icons.storage_rounded,
          ),
          _buildDivider(isDark),
          _buildConsentToggle(
            isDark: isDark,
            title: 'Analytics',
            subtitle: 'Anonymous usage data to improve app',
            value: status.analytics,
            icon: Icons.analytics_rounded,
            onChanged: (v) => _updateConsent(analytics: v),
          ),
          _buildDivider(isDark),
          _buildConsentToggle(
            isDark: isDark,
            title: 'Educational Updates',
            subtitle: 'Study tips and exam notifications',
            value: status.marketing,
            icon: Icons.notifications_rounded,
            onChanged: (v) => _updateConsent(marketing: v),
          ),
          _buildDivider(isDark),
          _buildConsentToggle(
            isDark: isDark,
            title: 'Third-Party Sharing',
            subtitle: 'Share with educational partners',
            value: status.thirdPartySharing,
            icon: Icons.share_rounded,
            onChanged: (v) => _updateConsent(thirdParty: v),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentToggle({
    required bool isDark,
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    bool enabled = true,
    ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.mintDark.withAlpha(26)
              : AppColors.mint.withAlpha(51),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.mintDark : AppColors.teal,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textDarkMode : AppColors.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textLightDark : AppColors.textLight,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeThumbColor: AppColors.teal,
      ),
    );
  }

  Widget _buildDataRightsSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withAlpha(13),
        ),
      ),
      child: Column(
        children: [
          _buildRightTile(
            isDark: isDark,
            title: 'Export My Data',
            subtitle: 'Download all your data in JSON format',
            icon: Icons.download_rounded,
            isLoading: _isExporting,
            onTap: _exportData,
          ),
          _buildDivider(isDark),
          _buildRightTile(
            isDark: isDark,
            title: 'View Data Access Log',
            subtitle: 'See who accessed your data',
            icon: Icons.history_rounded,
            onTap: _viewAccessLog,
          ),
          _buildDivider(isDark),
          _buildRightTile(
            isDark: isDark,
            title: 'Your Privacy Rights',
            subtitle: 'Learn about GDPR & DPDP Act rights',
            icon: Icons.gavel_rounded,
            onTap: _showPrivacyRights,
          ),
          _buildDivider(isDark),
          _buildRightTile(
            isDark: isDark,
            title: 'Data Retention Policy',
            subtitle: 'How long we keep your data',
            icon: Icons.schedule_rounded,
            onTap: _showRetentionPolicy,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withAlpha(13),
        ),
      ),
      child: Column(
        children: [
          _buildSecurityRow(
            isDark: isDark,
            title: 'Data Encryption',
            value: 'AES-256 Compatible',
            icon: Icons.lock_rounded,
          ),
          const SizedBox(height: 12),
          _buildSecurityRow(
            isDark: isDark,
            title: 'Key Rotation',
            value: 'Every 90 days',
            icon: Icons.refresh_rounded,
          ),
          const SizedBox(height: 12),
          _buildSecurityRow(
            isDark: isDark,
            title: 'Secure Storage',
            value: 'Local encrypted storage',
            icon: Icons.security_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityRow({
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isDark ? AppColors.mintDark : AppColors.teal,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? AppColors.textDarkMode : AppColors.textDark,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.mint.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.mintDark : AppColors.teal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withAlpha(51)),
      ),
      child: Column(
        children: [
          _buildRightTile(
            isDark: isDark,
            title: 'Withdraw All Consent',
            subtitle: 'Revoke all data processing permissions',
            icon: Icons.block_rounded,
            color: Colors.orange,
            onTap: _withdrawAllConsent,
          ),
          Divider(
            height: 1,
            color: Colors.red.withAlpha(51),
          ),
          _buildRightTile(
            isDark: isDark,
            title: 'Delete All My Data',
            subtitle: 'Permanently remove all your data',
            icon: Icons.delete_forever_rounded,
            color: Colors.red,
            isLoading: _isDeleting,
            onTap: _deleteAllData,
          ),
        ],
      ),
    );
  }

  Widget _buildRightTile({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    Color? color,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    final tileColor = color ?? (isDark ? AppColors.mintDark : AppColors.teal);

    return ListTile(
      leading: isLoading
          ? SizedBox(
              width: 36,
              height: 36,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tileColor,
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tileColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: tileColor, size: 20),
            ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color:
              color ?? (isDark ? AppColors.textDarkMode : AppColors.textDark),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textLightDark : AppColors.textLight,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? AppColors.textLightDark : AppColors.textLight,
      ),
      onTap: isLoading ? null : onTap,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? Colors.white10 : Colors.black.withAlpha(13),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _updateConsent({
    bool? analytics,
    bool? marketing,
    bool? thirdParty,
  }) async {
    final status = _consentStatus ?? ConsentStatus.empty();

    await _privacyService.recordConsent(
      dataProcessing: status.dataProcessing,
      analytics: analytics ?? status.analytics,
      marketing: marketing ?? status.marketing,
      thirdPartySharing: thirdParty ?? status.thirdPartySharing,
    );

    await _loadConsentStatus();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Privacy preferences updated'),
          backgroundColor: AppColors.teal,
        ),
      );
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final data = await _privacyService.exportUserData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      await Share.share(
        jsonString,
        subject: 'My Vidyarthi App Data Export',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _viewAccessLog() async {
    final logs = await _privacyService.getDataAccessLog();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(77),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Data Access Log',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                  ),
                ),
              ),
              Expanded(
                child: logs.isEmpty
                    ? Center(
                        child: Text(
                          'No access logs yet',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textLightDark
                                : AppColors.textLight,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log =
                              logs[logs.length - 1 - index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.cardDark
                                  : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: isDark
                                      ? AppColors.textLightDark
                                      : AppColors.textLight,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log['data_type'] ?? 'Unknown',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? AppColors.textDarkMode
                                              : AppColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        'Purpose: ${log['purpose'] ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.textLightDark
                                              : AppColors.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyRights() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(77),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Your Privacy Rights',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: PrivacyRights.userRights.length,
                  itemBuilder: (context, index) {
                    final right = PrivacyRights.userRights[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            right.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textDarkMode
                                  : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            right.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textLightDark
                                  : AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.mint.withAlpha(51),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              right.regulation,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.mintDark
                                    : AppColors.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRetentionPolicy() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Data Retention Policy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: DataCategories.categories.length,
                itemBuilder: (context, index) {
                  final category = DataCategories.categories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textDarkMode
                                    : AppColors.textDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(26),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category.retention,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textLightDark
                                : AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Legal basis: ${category.legalBasis}',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.textLightDark.withAlpha(179)
                                : AppColors.textLight.withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _withdrawAllConsent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw All Consent?'),
        content: const Text(
          'This will revoke all data processing permissions except essential ones. '
          'Some features may not work properly.\n\n'
          'You can update your preferences anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _privacyService.withdrawConsent(
        analytics: true,
        marketing: true,
        thirdPartySharing: true,
      );
      await _loadConsentStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consent withdrawn'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete All Data?'),
          ],
        ),
        content: const Text(
          '⚠️ This action is IRREVERSIBLE.\n\n'
          'All your data will be permanently deleted including:\n'
          '• Notes and study materials\n'
          '• Progress and analytics\n'
          '• Preferences and settings\n\n'
          'You will be logged out and need to create a new account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {

      final doubleConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Are you absolutely sure?'),
          content: const Text('Type "DELETE" to confirm permanent deletion.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Delete'),
            ),
          ],
        ),
      );

      if (doubleConfirmed == true) {
        setState(() => _isDeleting = true);

        try {
          await _encryptionService.secureWipe();
          await _privacyService.deleteAllUserData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All data deleted. Logging out...'),
                backgroundColor: Colors.red,
              ),
            );

            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deletion failed: $e')),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isDeleting = false);
          }
        }
      }
    }
  }
}
