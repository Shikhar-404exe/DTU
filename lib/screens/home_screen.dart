

import 'dart:ui';
import 'package:flutter/material.dart';

import '../main.dart';
import '../core/utils/responsive_utils.dart';
import 'note_screen.dart';
import 'saved_notes_screen.dart';
import 'doubts_screen.dart';
import 'photomath_screen.dart';
import 'note_scan_qr.dart';
import 'handwritten_scan_screen.dart';
import 'home_screen_wrapper.dart';
import 'ai_chatbot_screen.dart';
import 'youtube_browser_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _switchToTab(BuildContext context, int index) {
    try {
      HomeScreenWrapper.of(context).jumpTo(index);
    } catch (_) {

      final fallback = <int, Widget>{
        0: const NoteScreen(),
        1: const SavedNotesScreen(),
        2: const DoubtsScreen(),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                greeting,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                t(context, 'home.subtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight,
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount =
                        ResponsiveUtils.getGridCrossAxisCount(
                      context,
                      baseColumns: 2,
                      tabletColumns: 3,
                      desktopColumns: 4,
                    );

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
                          accentColor: AppColors.salmon,
                          onTap: () => _openScreen(context, const NoteScreen()),
                        ),
                        _GlassCard(
                          icon: Icons.bookmark_added_rounded,
                          title: t(context, 'home.card.saved'),
                          subtitle: "Your library",
                          accentColor: AppColors.mint,
                          onTap: () => _switchToTab(context, 1),
                        ),
                        _GlassCard(
                          icon: Icons.calculate_rounded,
                          title: t(context, 'home.card.math'),
                          subtitle: "Scan & solve",
                          accentColor: AppColors.mauve,
                          onTap: () => _switchToTab(context, 3),
                        ),
                        _GlassCard(
                          icon: Icons.help_outline_rounded,
                          title: "Doubts",
                          subtitle: "Ask & share",
                          accentColor: AppColors.lavender,
                          onTap: () => _switchToTab(context, 2),
                        ),
                        _GlassCard(
                          icon: Icons.qr_code_scanner_rounded,
                          title: t(context, 'home.card.scanqr'),
                          subtitle: "Import notes",
                          accentColor: AppColors.peach,
                          onTap: () => _switchToTab(context, 4),
                        ),
                        _GlassCard(
                          icon: Icons.document_scanner_rounded,
                          title: t(context, 'home.card.scanpdf'),
                          subtitle: "Scan documents",
                          accentColor: AppColors.sky,
                          onTap: () => _openScreen(
                              context, const HandwrittenScanScreen()),
                        ),
                        _GlassCard(
                          icon: Icons.psychology_rounded,
                          title: "AI Assistant",
                          subtitle: "Voice & chat",
                          accentColor: AppColors.lilac,
                          onTap: () =>
                              _openScreen(context, const AIChatbotScreen()),
                        ),
                        _GlassCard(
                          icon: Icons.video_library_rounded,
                          title: "Videos",
                          subtitle: "Educational",
                          accentColor: AppColors.teal,
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

  String _greetingText() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning 🎓";
    if (h < 17) return "Good afternoon 🎓";
    return "Good evening 🎓";
  }
}

class _GlassCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _GlassCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: accentColor.withAlpha(77),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(28),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(245),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: accentColor.withAlpha(77),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withAlpha(250),
                    accentColor.withAlpha(26),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor,
                          Color.lerp(accentColor, Colors.white, 0.2)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withAlpha(102),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),

                  const Spacer(),

                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: AppColors.textLight,
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
