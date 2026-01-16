

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/storage_service.dart';
import '../main.dart';

class EbookScreen extends StatefulWidget {
  const EbookScreen({super.key});

  @override
  State<EbookScreen> createState() => _EbookScreenState();
}

class _EbookScreenState extends State<EbookScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  final TextEditingController _urlCtrl =
      TextEditingController(text: "https://ncert.nic.in/textbook.php");
  bool _downloading = false;
  String _currentSource = "NCERT";

  static const Map<String, String> _sources = {
    "NCERT": "https://ncert.nic.in/textbook.php",
    "e-Pathshala": "https://epathshala.nic.in/",
    "NIOS": "https://nios.ac.in/online-course-material.aspx",
    "CBSE": "https://cbseacademic.nic.in/curriculum.html",
    "DigiLocker": "https://www.digilocker.gov.in/",
    "NDL": "https://ndl.iitkgp.ac.in/",
  };

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),

          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            if (url.endsWith('.pdf')) {

              _downloadPdf(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_urlCtrl.text));
  }

  Future<void> _go() async {
    final url = _urlCtrl.text.trim();
    if (url.isNotEmpty) {
      setState(() => _loading = true);
      _controller.loadRequest(Uri.parse(url));
    }
  }

  Future<void> _extractPdfLinks() async {

    const js = """
      (function(){
        const links = Array.from(document.querySelectorAll('a'))
          .map(a => a.href)
          .filter(h => !!h && h.toLowerCase().endsWith('.pdf'));
        return JSON.stringify(links);
      })()
    """;

    try {
      final raw = await _controller.runJavaScriptReturningResult(js);

      List<String> links = [];

      if (raw is String) {

        String str = raw;
        if (str.startsWith('"') && str.endsWith('"')) {
          str = str.substring(1, str.length - 1);

          str = str.replaceAll(r'\"', '"');
        }

        try {
          final decoded = jsonDecode(str);
          if (decoded is List) {
            links = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {

          final urlPattern =
              RegExp(r'https?://[^\s"]+\.pdf', caseSensitive: false);
          links = urlPattern.allMatches(str).map((m) => m.group(0)!).toList();
        }
      } else if (raw is List) {
        links = raw.map((e) => e.toString()).toList();
      }

      links = links.toSet().toList();

      if (links.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "No PDF links found on this page. Try navigating to a page with PDF downloads.")),
        );
        return;
      }

      if (!mounted) return;

      final selected = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red.shade400),
                const SizedBox(width: 10),
                const Text("Select PDF to download"),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: links.length,
                itemBuilder: (_, i) {
                  final link = links[i];
                  final fileName =
                      Uri.parse(link).pathSegments.lastOrNull ?? link;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading:
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: Text(
                        fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        link,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      onTap: () => Navigator.pop(ctx, link),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
            ],
          );
        },
      );

      if (selected != null) {
        await _downloadPdf(selected);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _downloadPdf(String url) async {
    setState(() => _downloading = true);
    try {
      final uri = Uri.parse(url);
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw "Failed to download (HTTP ${res.statusCode})";
      }

      final docs = await getApplicationDocumentsDirectory();
      final fileName = p.basename(uri.path);
      final savePath = p.join(docs.path, fileName);
      final file = File(savePath);
      await file.writeAsBytes(res.bodyBytes, flush: true);

      final notes = await StorageService.loadNotes();
      notes.add({
        "v": 1,
        "type": "ebook",
        "title": fileName,
        "timestamp": DateTime.now().toIso8601String(),
        "filePath": savePath,
        "fileType": "pdf",
      });
      await StorageService.saveNotes(notes);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Downloaded: $fileName")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Download error: $e")));
    } finally {
      if (!mounted) return;
      setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "E-Books",
            style: TextStyle(
              color: isDark ? AppColors.textDarkMode : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: isDark ? AppColors.textDarkMode : Colors.black87,
          iconTheme: IconThemeData(
              color: isDark ? AppColors.textDarkMode : Colors.black87),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                Icons.download_rounded,
                color: isDark ? AppColors.salmonDark : AppColors.salmon,
              ),
              tooltip: "Extract PDF links on page",
              onPressed: _extractPdfLinks,
            ),
          ],
        ),
        body: Column(
          children: [

            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _sources.entries.map((entry) {
                  final isSelected = _currentSource == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        entry.key,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textDarkMode
                                  : Colors.black87),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor:
                          isDark ? AppColors.salmonDark : AppColors.salmon,
                      backgroundColor: isDark
                          ? AppColors.cardDark.withAlpha(204)
                          : Colors.white.withAlpha(230),
                      checkmarkColor: Colors.white,
                      onSelected: (_) {
                        setState(() {
                          _currentSource = entry.key;
                          _urlCtrl.text = entry.value;
                          _loading = true;
                        });
                        _controller.loadRequest(Uri.parse(entry.value));
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark.withAlpha(230)
                            : Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _urlCtrl,
                        style: TextStyle(
                          color:
                              isDark ? AppColors.textDarkMode : Colors.black87,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter URL",
                          hintStyle: TextStyle(
                            color:
                                isDark ? AppColors.textLightDark : Colors.grey,
                          ),
                          prefixIcon: Icon(
                            Icons.link,
                            color: isDark
                                ? AppColors.salmonDark
                                : AppColors.salmon,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (_) => _go(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.salmonDark : AppColors.salmon,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isDark ? AppColors.salmonDark : AppColors.salmon)
                                  .withAlpha(102),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _go,
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(38),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_loading)
                        Container(
                          color: Colors.white.withAlpha(204),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      if (_downloading)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.salmonDark
                                  : AppColors.salmon,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha(51),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Downloading...",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "Tap download icon to extract PDF links from current page",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textLightDark : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
