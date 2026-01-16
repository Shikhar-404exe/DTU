// lib/screens/home_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';

import '../main.dart';
import '../core/utils/responsive_utils.dart';
import 'note_screen.dart';
import 'saved_notes_screen.dart';
import 'timetable_screen.dart';
import 'photomath_screen.dart';
import 'note_scan_qr.dart';
import 'handwritten_scan_screen.dart';
import 'ebook_screen.dart';
import 'home_screen_wrapper.dart';
import 'ai_chatbot_screen.dart';
import 'youtube_browser_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Switch to bottom tab inside HomeScreenWrapper
  void _switchToTab(BuildContext context, int index) {
    try {
      HomeScreenWrapper.of(context).jumpTo(index);
    } catch (_) {
      // fallback (wrapper missing)
      final fallback = <int, Widget>{
        0: const NoteScreen(), // keep as note screen for fallback as well
        1: const SavedNotesScreen(),
        2: const TimetableScreen(),
        3: const PhotomathScreen(),
        4: const NoteScanQR(),
      };

      if (fallback.containsKey(index)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GradientBackground(child: fallback[index]!),
          ),
        );
      }
    }
  }

  /// Opens screens that do NOT belong to bottom nav
  void _openScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GradientBackground(child: screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _greetingText();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Greeting
              Text(
                greeting,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkMode : Colors.black87,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 4),

              /// Subtitle
              Text(
                t(context, 'home.subtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textLightDark : Colors.black54,
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 18),

              /// Main Grid - Responsive layout
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Determine grid columns based on screen width
                    final crossAxisCount =
                        ResponsiveUtils.getGridCrossAxisCount(
                      context,
                      baseColumns: 2,
                      tabletColumns: 3,
                      desktopColumns: 4,
                    );

                    // Adjust child aspect ratio for different screen sizes
                    final aspectRatio =
                        ResponsiveUtils.getDeviceType(context) ==
                                DeviceType.mobile
                            ? 0.95
                            : 1.1;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: aspectRatio,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _GlassCard(
                          icon: Icons.auto_stories_rounded,
                          title: t(context, 'home.card.notes'),
                          subtitle: "AI powered",
                          accentColor:
                              isDark ? AppColors.salmonDark : AppColors.salmon,
                          isDark: isDark,
                          // Open NoteScreen directly (keeps UI consistent)
                          onTap: () => _openScreen(context, const NoteScreen()),
                        ),
                        _GlassCard(
                          icon: Icons.bookmark_added_rounded,
                          title: t(context, 'home.card.saved'),
                          subtitle: "Your library",
                          accentColor:
                              isDark ? AppColors.mintDark : AppColors.mint,
                          isDark: isDark,
                          onTap: () => _switchToTab(context, 1),
                        ),
                        _GlassCard(
                          icon: Icons.calculate_rounded,
                          title: t(context, 'home.card.math'),
                          subtitle: "Scan & solve",
                          accentColor:
                              isDark ? AppColors.mauveDark : AppColors.mauve,
                          isDark: isDark,
                          onTap: () => _switchToTab(context, 3),
                        ),
                        _GlassCard(
                          icon: Icons.event_note_rounded,
                          title: t(context, 'home.card.timetable'),
                          subtitle: "Plan classes",
                          accentColor:
                              isDark ? AppColors.mintDark : AppColors.mint,
                          isDark: isDark,
                          onTap: () => _switchToTab(context, 2),
                        ),
                        _GlassCard(
                          icon: Icons.qr_code_scanner_rounded,
                          title: t(context, 'home.card.scanqr'),
                          subtitle: "Import notes",
                          accentColor:
                              isDark ? AppColors.salmonDark : AppColors.salmon,
                          isDark: isDark,
                          onTap: () => _switchToTab(context, 4),
                        ),
                        _GlassCard(
                          icon: Icons.document_scanner_rounded,
                          title: t(context, 'home.card.scanpdf'),
                          subtitle: "Handwritten notes",
                          accentColor:
                              isDark ? AppColors.mintDark : AppColors.mint,
                          isDark: isDark,
                          onTap: () => _openScreen(
                              context, const HandwrittenScanScreen()),
                        ),
                        _GlassCard(
                          icon: Icons.menu_book_rounded,
                          title: t(context, 'home.card.ebook'),
                          subtitle: "NCERT E-Books",
                          accentColor:
                              isDark ? AppColors.mauveDark : AppColors.mauve,
                          isDark: isDark,
                          onTap: () =>
                              _openScreen(context, const EbookScreen()),
                        ),
                        _GlassCard(
                          icon: Icons.psychology_rounded,
                          title: "AI Assistant",
                          subtitle: "Voice & chat",
                          accentColor: isDark
                              ? AppColors.lavenderDark
                              : AppColors.lavender,
                          isDark: isDark,
                          onTap: () =>
                              _openScreen(context, const AIChatbotScreen()),
                        ),
                        _GlassCard(
                          icon: Icons.video_library_rounded,
                          title: "Videos",
                          subtitle: "Educational",
                          accentColor:
                              isDark ? AppColors.salmonDark : AppColors.salmon,
                          isDark: isDark,
                          onTap: () => _openScreen(
                              context, const YouTubeBrowserScreen()),
                        ),
                      ],
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

  /// greeting text
  String _greetingText() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning 🎓";
    if (h < 17) return "Good afternoon 🎓";
    return "Good evening 🎓";
  }
}

/// Glass card widget with 3D shadow effect
class _GlassCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isDark;

  const _GlassCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          // Enhanced 3D shadow effect
          boxShadow: [
            // Main colored shadow
            BoxShadow(
              color: accentColor.withAlpha(89), // ~0.35 opacity
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: 0,
            ),
            // Secondary dark shadow for depth
            BoxShadow(
              color: Colors.black.withAlpha(38), // ~0.15 opacity
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            // Subtle inner glow effect
            BoxShadow(
              color: accentColor.withAlpha(26), // ~0.1 opacity
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(32),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardDark.withAlpha(230) // ~0.9 opacity
                    : Colors.white.withAlpha(235), // ~0.92 opacity
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? accentColor.withAlpha(102) // ~0.4 opacity
                      : Colors.white.withAlpha(204), // ~0.8 opacity
                  width: 1.5,
                ),
                // Gradient overlay for 3D effect
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.cardDark.withAlpha(242), // ~0.95 opacity
                          AppColors.cardDark.withAlpha(204), // ~0.8 opacity
                        ]
                      : [
                          Colors.white.withAlpha(242), // ~0.95 opacity
                          Colors.white.withAlpha(217), // ~0.85 opacity
                        ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Icon circle with enhanced 3D effect
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withAlpha(128), // ~0.5 opacity
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: accentColor.withAlpha(77), // ~0.3 opacity
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor,
                          Color.lerp(accentColor, Colors.black, 0.15)!,
                        ],
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),

                  const Spacer(),

                  /// Title
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? AppColors.textDarkMode : Colors.black87,
                        ),
                  ),

                  const SizedBox(height: 4),

                  /// Subtitle
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color:
                              isDark ? AppColors.textLightDark : Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
