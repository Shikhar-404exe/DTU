import 'package:flutter/material.dart';

/// 📑 Note Detail Screen
/// Displays details of a generated or selected note.
class NoteDetailScreen extends StatelessWidget {
  final String title;
  final String content;

  const NoteDetailScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: Colors.white.withAlpha(217), // ~0.85 opacity
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Container(
        color: const Color(0xFFFFDAD0), // solid pastel salmon
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230), // ~0.9 opacity
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 17,
                    height: 1.5,
                    color: Colors.black87,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
