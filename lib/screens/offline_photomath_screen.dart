

library;

import 'package:flutter/material.dart';
import 'dart:io';
import '../services/offline_photomath_service.dart';
import '../main.dart';

class OfflinePhotoMathScreen extends StatefulWidget {
  const OfflinePhotoMathScreen({super.key});

  @override
  State<OfflinePhotoMathScreen> createState() => _OfflinePhotoMathScreenState();
}

class _OfflinePhotoMathScreenState extends State<OfflinePhotoMathScreen> {
  final _photoMathService = OfflinePhotoMathService();

  File? _selectedImage;
  String _extractedText = '';
  Map<String, dynamic>? _solution;
  bool _isProcessing = false;
  bool _backendAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    final available = await _photoMathService.checkBackendHealth();
    setState(() => _backendAvailable = available);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Solver'),
        backgroundColor: isDark ? AppColors.cardDark : Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(
              _backendAvailable ? Icons.cloud_done : Icons.cloud_off,
              color: _backendAvailable ? Colors.green : Colors.orange,
            ),
            onPressed: _checkBackend,
            tooltip: _backendAvailable ? 'Backend Online' : 'Backend Offline',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImageSection(isDark),
            const SizedBox(height: 20),
            _buildActionButtons(isDark),
            if (!_backendAvailable) ...[
              const SizedBox(height: 16),
              _buildBackendWarning(isDark),
            ],
            if (_extractedText.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildExtractedText(isDark),
            ],
            if (_solution != null) ...[
              const SizedBox(height: 20),
              _buildSolution(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isDark) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.cardDark : Colors.grey[100],
      ),
      child: _selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_selectedImage!, fit: BoxFit.cover),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No image selected',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a photo of a math problem',
                    style: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.salmonDark : AppColors.salmon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isProcessing ? null : _captureImage,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.blue[700] : Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isProcessing ? null : _pickImage,
          ),
        ),
      ],
    );
  }

  Widget _buildBackendWarning(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Backend server not reachable. Make sure server is running on localhost:8000',
              style: TextStyle(
                color: isDark ? AppColors.textLightDark : AppColors.textLight,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedText(bool isDark) {
    return Card(
      color: isDark ? AppColors.cardDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.text_fields,
                  color: isDark ? Colors.blue[300] : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Extracted Text:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _extractedText,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textLightDark : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolution(bool isDark) {
    if (_solution == null) return const SizedBox.shrink();

    if (_solution!['success'] != true) {
      return Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Error',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _solution?['error'] ?? 'Failed to solve problem',
                style: const TextStyle(color: Colors.red),
              ),
              if (_solution?['suggestion'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  '💡 ${_solution!['suggestion']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final solutions = _solution!['solutions'] as List? ?? [];

    return Card(
      color: isDark ? AppColors.cardDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Solution:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (solutions.isEmpty)
              Text(
                'No mathematical expressions found in image',
                style: TextStyle(
                  color: isDark ? AppColors.textLightDark : AppColors.textLight,
                ),
              )
            else
              ...solutions.map((sol) => _buildSolutionCard(sol, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionCard(Map<String, dynamic> solution, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue[900]!.withOpacity(0.3) : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.purple[800] : Colors.purple[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  solution['type']?.toString().toUpperCase() ?? 'MATH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.purple[200] : Colors.purple[700],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  solution['problem'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? AppColors.textDarkMode : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (solution['solution'] != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.green[900]!.withOpacity(0.3)
                    : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Answer:',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.green[300] : Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatSolution(solution['solution']),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.green[200] : Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (solution['steps'] != null &&
              (solution['steps'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Steps:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDarkMode : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            ...(solution['steps'] as List).asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blue[800] : Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.blue[200] : Colors.blue[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textLightDark
                              : AppColors.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (solution['error'] != null) ...[
            const SizedBox(height: 8),
            Text(
              '❌ ${solution['error']}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatSolution(dynamic solution) {
    if (solution is Map) {

      if (solution['result'] != null) return solution['result'].toString();
      if (solution['solution'] != null) return solution['solution'].toString();
      if (solution['decimal'] != null) return solution['decimal'].toString();
      if (solution['roots'] != null) return solution['roots'].toString();
      return solution.toString();
    }
    return solution.toString();
  }

  Future<void> _captureImage() async {
    setState(() {
      _isProcessing = true;
      _solution = null;
      _extractedText = '';
    });

    final image = await _photoMathService.captureImage();
    if (image != null) {
      setState(() => _selectedImage = image);
      await _processImage(image);
    }

    setState(() => _isProcessing = false);
  }

  Future<void> _pickImage() async {
    setState(() {
      _isProcessing = true;
      _solution = null;
      _extractedText = '';
    });

    final image = await _photoMathService.pickImage();
    if (image != null) {
      setState(() => _selectedImage = image);
      await _processImage(image);
    }

    setState(() => _isProcessing = false);
  }

  Future<void> _processImage(File image) async {

    final text = await _photoMathService.extractTextFromImage(image);
    setState(() => _extractedText = text);

    final solution = await _photoMathService.solveMathProblem(image);
    setState(() => _solution = solution);
  }

  @override
  void dispose() {
    _photoMathService.dispose();
    super.dispose();
  }
}
