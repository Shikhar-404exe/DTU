

library;

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class OfflinePhotoMathService {
  static final OfflinePhotoMathService _instance =
      OfflinePhotoMathService._internal();
  factory OfflinePhotoMathService() => _instance;
  OfflinePhotoMathService._internal();

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _imagePicker = ImagePicker();

  String backendUrl = 'http://localhost:8000';

  Future<File?> captureImage() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return photo != null ? File(photo.path) : null;
    } catch (e) {
      debugPrint('❌ Camera capture error: $e');
      return null;
    }
  }

  Future<File?> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      debugPrint('❌ Gallery pick error: $e');
      return null;
    }
  }

  Future<String> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      debugPrint('📝 Extracted text: ${recognizedText.text}');
      return recognizedText.text;
    } catch (e) {
      debugPrint('❌ Text extraction error: $e');
      return '';
    }
  }

  Future<Map<String, dynamic>> solveMathProblem(File imageFile) async {
    try {

      String extractedText = await extractTextFromImage(imageFile);

      final uri = Uri.parse('$backendUrl/photomath/solve');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      debugPrint('🚀 Sending math problem to backend...');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        debugPrint('✅ Math problem solved: ${result['success']}');
        return result;
      } else {
        debugPrint('❌ Backend error: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
          'extracted_text': extractedText,
        };
      }
    } catch (e) {
      debugPrint('❌ Solve error: $e');
      return {
        'success': false,
        'error': 'Failed to solve: $e',
      };
    }
  }

  Future<bool> checkBackendHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$backendUrl/photomath/health'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ PhotoMath backend: ${data['name']}');
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Backend not reachable: $e');
      return false;
    }
  }

  void setBackendUrl(String url) {
    backendUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    debugPrint('🔧 Backend URL set to: $backendUrl');
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
