/// Privacy Consent Screen
/// GDPR/DPDP Act compliant consent collection UI
/// Must be shown before collecting any user data
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../core/services/privacy_compliance_service.dart';

class PrivacyConsentScreen extends StatefulWidget {
  final VoidCallback onConsentGiven;
  final VoidCallback? onConsentDeclined;

  const PrivacyConsentScreen({
    super.key,
    required this.onConsentGiven,
    this.onConsentDeclined,
  });

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  final _privacyService = PrivacyComplianceService.instance;

  bool _dataProcessingConsent = false;
  bool _analyticsConsent = false;
  bool _marketingConsent = false;
  bool _thirdPartyConsent = false;
  bool _isMinor = false;
  bool _parentalConsent = false;
  bool _hasReadPolicy = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.mint.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.privacy_tip_rounded,
                      color: isDark ? AppColors.mintDark : AppColors.teal,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Privacy Matters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textDarkMode
                                : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please review and provide your consent',
                          style: TextStyle(
                            fontSize: 13,
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
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compliance badges
                    _buildComplianceBadges(isDark),
                    const SizedBox(height: 24),

                    // Data collection summary
                    _buildSection(
                      isDark: isDark,
                      title: 'What Data We Collect',
                      icon: Icons.data_usage_rounded,
                      child: _buildDataCategories(isDark),
                    ),
                    const SizedBox(height: 20),

                    // Consent options
                    _buildSection(
                      isDark: isDark,
                      title: 'Your Consent Choices',
                      icon: Icons.check_circle_outline_rounded,
                      child: _buildConsentOptions(isDark),
                    ),
                    const SizedBox(height: 20),

                    // Age verification
                    _buildSection(
                      isDark: isDark,
                      title: 'Age Verification',
                      icon: Icons.cake_rounded,
                      child: _buildAgeVerification(isDark),
                    ),
                    const SizedBox(height: 20),

                    // Your rights
                    _buildSection(
                      isDark: isDark,
                      title: 'Your Rights',
                      icon: Icons.gavel_rounded,
                      child: _buildRightsSummary(isDark),
                    ),
                    const SizedBox(height: 20),

                    // Policy acknowledgment
                    _buildPolicyAcknowledgment(isDark),
                    const SizedBox(height: 100), // Space for buttons
                  ],
                ),
              ),
            ),

            // Bottom buttons
            _buildBottomButtons(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceBadges(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBadge('GDPR', Colors.blue, isDark),
        const SizedBox(width: 12),
        _buildBadge('IT Act 2000', Colors.orange, isDark),
        const SizedBox(width: 12),
        _buildBadge('DPDP Act 2023', Colors.green, isDark),
      ],
    );
  }

  Widget _buildBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSection({
    required bool isDark,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withAlpha(13),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isDark ? AppColors.mintDark : AppColors.teal,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDataCategories(bool isDark) {
    return Column(
      children: DataCategories.categories.map((category) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.mintDark : AppColors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkMode
                            : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textLightDark
                            : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Purpose: ${category.purpose}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textLightDark.withAlpha(179)
                            : AppColors.textLight.withAlpha(179),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConsentOptions(bool isDark) {
    return Column(
      children: [
        _buildConsentTile(
          isDark: isDark,
          title: 'Essential Data Processing',
          subtitle: 'Required for app functionality',
          value: _dataProcessingConsent,
          required: true,
          onChanged: (v) => setState(() => _dataProcessingConsent = v ?? false),
        ),
        _buildConsentTile(
          isDark: isDark,
          title: 'Analytics',
          subtitle: 'Help us improve the app (anonymous)',
          value: _analyticsConsent,
          onChanged: (v) => setState(() => _analyticsConsent = v ?? false),
        ),
        _buildConsentTile(
          isDark: isDark,
          title: 'Educational Updates',
          subtitle: 'Receive study tips and exam reminders',
          value: _marketingConsent,
          onChanged: (v) => setState(() => _marketingConsent = v ?? false),
        ),
        _buildConsentTile(
          isDark: isDark,
          title: 'Third-Party Sharing',
          subtitle: 'Share with educational partners',
          value: _thirdPartyConsent,
          onChanged: (v) => setState(() => _thirdPartyConsent = v ?? false),
        ),
      ],
    );
  }

  Widget _buildConsentTile({
    required bool isDark,
    required String title,
    required String subtitle,
    required bool value,
    bool required = false,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: required ? null : onChanged,
            activeColor: AppColors.teal,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textDarkMode
                            : AppColors.textDark,
                      ),
                    ),
                    if (required) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(26),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Required',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textLightDark : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeVerification(bool isDark) {
    return Column(
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _isMinor,
          onChanged: (v) => setState(() {
            _isMinor = v ?? false;
            if (!_isMinor) _parentalConsent = false;
          }),
          title: Text(
            'I am under 18 years old',
            style: TextStyle(
              color: isDark ? AppColors.textDarkMode : AppColors.textDark,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.teal,
        ),
        if (_isMinor)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withAlpha(77)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Parental consent required under DPDP Act',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textDarkMode
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _parentalConsent,
                  onChanged: (v) =>
                      setState(() => _parentalConsent = v ?? false),
                  title: const Text(
                    'I have my parent/guardian\'s consent to use this app',
                    style: TextStyle(fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.teal,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRightsSummary(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Under GDPR and DPDP Act, you have the right to:',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textLightDark : AppColors.textLight,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PrivacyRights.userRights.take(4).map((right) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.mintDark.withAlpha(26)
                    : AppColors.mint.withAlpha(77),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                right.title.replaceAll('Right to ', ''),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.mintDark : AppColors.teal,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _showFullRights(isDark),
          icon: Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: isDark ? AppColors.mintDark : AppColors.teal,
          ),
          label: Text(
            'View all your rights',
            style: TextStyle(
              color: isDark ? AppColors.mintDark : AppColors.teal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyAcknowledgment(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.salmonDark.withAlpha(26)
            : AppColors.salmon.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _hasReadPolicy,
            onChanged: (v) => setState(() => _hasReadPolicy = v ?? false),
            title: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                ),
                children: [
                  const TextSpan(text: 'I have read and understood the '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: _openPrivacyPolicy,
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: isDark ? AppColors.mintDark : AppColors.teal,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: _openTermsOfService,
                      child: Text(
                        'Terms of Service',
                        style: TextStyle(
                          color: isDark ? AppColors.mintDark : AppColors.teal,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.teal,
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${PrivacyComplianceService.policyLastUpdated}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textLightDark : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(bool isDark) {
    final canProceed = _dataProcessingConsent &&
        _hasReadPolicy &&
        (!_isMinor || _parentalConsent);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canProceed && !_isLoading ? _handleAccept : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Accept & Continue',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onConsentDeclined,
              child: Text(
                'Decline',
                style: TextStyle(
                  color: isDark ? AppColors.textLightDark : AppColors.textLight,
                ),
              ),
            ),
            if (!canProceed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _getMissingRequirements(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getMissingRequirements() {
    final missing = <String>[];
    if (!_dataProcessingConsent) missing.add('essential data processing');
    if (!_hasReadPolicy) missing.add('policy acknowledgment');
    if (_isMinor && !_parentalConsent) missing.add('parental consent');
    return 'Please provide: ${missing.join(', ')}';
  }

  void _showFullRights(bool isDark) {
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
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withAlpha(13),
                        ),
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
                                fontWeight: FontWeight.w500,
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

  Future<void> _openPrivacyPolicy() async {
    // Replace with your actual privacy policy URL
    const url = 'https://vidyarthi-app.com/privacy-policy';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open privacy policy')),
        );
      }
    }
  }

  Future<void> _openTermsOfService() async {
    // Replace with your actual terms URL
    const url = 'https://vidyarthi-app.com/terms';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open terms of service')),
        );
      }
    }
  }

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);

    try {
      await _privacyService.recordConsent(
        dataProcessing: _dataProcessingConsent,
        analytics: _analyticsConsent,
        marketing: _marketingConsent,
        thirdPartySharing: _thirdPartyConsent,
        isMinor: _isMinor,
        hasParentalConsent: _parentalConsent,
      );

      widget.onConsentGiven();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving consent: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
