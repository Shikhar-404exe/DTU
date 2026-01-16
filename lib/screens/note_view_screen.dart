import 'dart:io';
import 'package:flutter/material.dart';

class NoteViewScreen extends StatelessWidget {
  final String filePath;

  const NoteViewScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    String content = "";

    try {
      content = file.readAsStringSync();
    } catch (e) {
      content = "⚠️ Error reading note file.";
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("View Note"),
        centerTitle: true,
        backgroundColor: Colors.white.withAlpha(217),
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Container(
        color: const Color(0xFFFFDAD0),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SelectableText(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    height: 1.8,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
