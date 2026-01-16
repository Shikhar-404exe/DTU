import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import '../main.dart';

/// Advanced Math Solver - PhotoMath Clone
/// Supports: Arithmetic, Algebra, Calculus, Trigonometry, Logarithms, Statistics

// Step types for categorizing solution steps
enum StepType {
  problem, // Original problem statement
  simplify, // Simplification step
  substitute, // Substitution step
  calculate, // Calculation step
  rule, // Rule application (power rule, chain rule, etc.)
  result, // Final result
  error, // Error message
  note, // Additional notes/explanations
}

// Represents a single step in the solution
class MathStep {
  final String expression;
  final String explanation;
  final StepType type;

  MathStep(this.expression, this.explanation, this.type);

  @override
  String toString() => '$explanation: $expression';
}

class PhotomathScreen extends StatefulWidget {
  const PhotomathScreen({super.key});

  @override
  State<PhotomathScreen> createState() => _PhotomathScreenState();
}

class _PhotomathScreenState extends State<PhotomathScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _recognizedText = '';
  String _solution = '';
  List<MathStep> _steps = [];
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Calculator state
  String _calculatorInput = '';
  bool _showCalculator = true;
  String _lastAnswer = '';

  // Crosshair size for adjustable capture area
  final double _crosshairWidth = 0.9; // percentage of screen width
  double _crosshairHeight = 100.0; // fixed height in pixels

  // Results panel state
  bool _isResultsExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();

        // Turn off flash by default
        if (_cameraController!.value.isInitialized) {
          await _cameraController!.setFlashMode(FlashMode.off);
        }

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile image = await _cameraController!.takePicture();

      // Crop image to crosshair area for better OCR accuracy
      final File croppedFile = await _cropImageToCrosshair(image.path);

      final inputImage = InputImage.fromFilePath(croppedFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      String rawText = recognizedText.text;
      String normalized = _normalizeMathExpression(rawText);

      setState(() {
        _recognizedText = normalized;
      });

      if (normalized.isNotEmpty) {
        _solveMathProblem(normalized);
      } else {
        setState(() {
          _solution = 'No math expression detected. Try again.';
          _steps = [];
        });
      }

      // Clean up temp files
      try {
        await File(image.path).delete();
        await croppedFile.delete();
      } catch (_) {}
    } catch (e) {
      debugPrint('Error processing image: $e');
      setState(() {
        _solution = 'Error processing image. Please try again.';
        _steps = [];
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Crop image to crosshair area for focused OCR
  Future<File> _cropImageToCrosshair(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return File(imagePath);
      }

      // Calculate crop area based on crosshair position
      // Crosshair is centered, width is _crosshairWidth of screen, height is _crosshairHeight
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height *
          0.4; // Camera takes 40% (flex 2 of 5)

      // Scale factors between camera preview and actual image
      final scaleX = image.width / screenWidth;
      final scaleY = image.height / screenHeight;

      // Crosshair dimensions in image coordinates
      final crosshairWidthPx = (screenWidth * _crosshairWidth) * scaleX;
      final crosshairHeightPx = _crosshairHeight * scaleY;

      // Center position
      final centerX = image.width / 2;
      final centerY = image.height / 2;

      // Crop bounds
      final cropX =
          (centerX - crosshairWidthPx / 2).clamp(0, image.width - 1).toInt();
      final cropY =
          (centerY - crosshairHeightPx / 2).clamp(0, image.height - 1).toInt();
      final cropWidth = crosshairWidthPx.clamp(1, image.width - cropX).toInt();
      final cropHeight =
          crosshairHeightPx.clamp(1, image.height - cropY).toInt();

      // Crop the image
      final croppedImage = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      // Apply image enhancements for better OCR
      final enhanced = img.adjustColor(
        croppedImage,
        contrast: 1.3,
        brightness: 1.1,
      );

      // Save cropped image
      final tempDir = Directory.systemTemp;
      final croppedPath =
          '${tempDir.path}/cropped_math_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(img.encodeJpg(enhanced, quality: 95));

      return croppedFile;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return File(imagePath);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT NORMALIZATION & OCR CORRECTION
  // ═══════════════════════════════════════════════════════════════════════════

  String _normalizeMathExpression(String text) {
    String normalized = text.trim();

    // Remove extra spaces and newlines
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    // Common OCR corrections for math symbols
    normalized = normalized
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(''', '')
        .replaceAll(''', '')
        .replaceAll('"', '')
        .replaceAll('º', '')
        .replaceAll('°', '')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll('⁴', '^4')
        .replaceAll('⁵', '^5')
        .replaceAll('⁶', '^6')
        .replaceAll('⁷', '^7')
        .replaceAll('⁸', '^8')
        .replaceAll('⁹', '^9')
        .replaceAll('⁰', '^0')
        .replaceAll('₀', '0')
        .replaceAll('₁', '1')
        .replaceAll('₂', '2')
        .replaceAll('₃', '3')
        .replaceAll('√', 'sqrt')
        .replaceAll('∫', 'integral ')
        .replaceAll('∑', 'sum ')
        .replaceAll('∏', 'product ')
        .replaceAll('π', 'pi')
        .replaceAll('θ', 'theta')
        .replaceAll('α', 'alpha')
        .replaceAll('β', 'beta')
        .replaceAll('∞', 'infinity')
        .replaceAll('≤', '<=')
        .replaceAll('≥', '>=')
        .replaceAll('≠', '!=')
        .replaceAll('±', '+-')
        .replaceAll('∓', '-+');

    // Replace 'x' with '*' only when between two numbers
    normalized = normalized.replaceAllMapped(
      RegExp(r'(\d)\s*[xX]\s*(\d)'),
      (m) => '${m[1]}*${m[2]}',
    );

    // Fix common OCR misreads
    normalized = normalized
        .replaceAll(RegExp(r'[oO](?=\d)'), '0')
        .replaceAll(RegExp(r'(?<=\d)[oO]'), '0')
        .replaceAll(RegExp(r'[lI](?=\d)'), '1')
        .replaceAll(RegExp(r'(?<=\d)[lI]'), '1');

    // Fix function names that might be split
    normalized = normalized
        .replaceAll(RegExp(r's\s*i\s*n\s*h', caseSensitive: false), 'sinh')
        .replaceAll(RegExp(r'c\s*o\s*s\s*h', caseSensitive: false), 'cosh')
        .replaceAll(RegExp(r't\s*a\s*n\s*h', caseSensitive: false), 'tanh')
        .replaceAll(
            RegExp(r'a\s*r\s*c\s*s\s*i\s*n', caseSensitive: false), 'arcsin')
        .replaceAll(
            RegExp(r'a\s*r\s*c\s*c\s*o\s*s', caseSensitive: false), 'arccos')
        .replaceAll(
            RegExp(r'a\s*r\s*c\s*t\s*a\s*n', caseSensitive: false), 'arctan')
        .replaceAll(RegExp(r's\s*i\s*n', caseSensitive: false), 'sin')
        .replaceAll(RegExp(r'c\s*o\s*s', caseSensitive: false), 'cos')
        .replaceAll(RegExp(r't\s*a\s*n', caseSensitive: false), 'tan')
        .replaceAll(RegExp(r's\s*e\s*c', caseSensitive: false), 'sec')
        .replaceAll(RegExp(r'c\s*s\s*c', caseSensitive: false), 'csc')
        .replaceAll(RegExp(r'c\s*o\s*t', caseSensitive: false), 'cot')
        .replaceAll(RegExp(r'l\s*o\s*g', caseSensitive: false), 'log')
        .replaceAll(RegExp(r's\s*q\s*r\s*t', caseSensitive: false), 'sqrt')
        .replaceAll(RegExp(r'c\s*b\s*r\s*t', caseSensitive: false), 'cbrt')
        .replaceAll(RegExp(r'a\s*b\s*s', caseSensitive: false), 'abs')
        .replaceAll(RegExp(r'f\s*a\s*c\s*t', caseSensitive: false), 'fact')
        .replaceAll(RegExp(r'l\s*i\s*m', caseSensitive: false), 'lim');

    // Fix spacing around operators
    normalized = normalized
        .replaceAll(RegExp(r'\s*\+\s*'), '+')
        .replaceAll(RegExp(r'\s*-\s*'), '-')
        .replaceAll(RegExp(r'\s*\*\s*'), '*')
        .replaceAll(RegExp(r'\s*/\s*'), '/')
        .replaceAll(RegExp(r'\s*\^\s*'), '^')
        .replaceAll(RegExp(r'\s*=\s*'), '=');

    return normalized.trim();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN PROBLEM SOLVER
  // ═══════════════════════════════════════════════════════════════════════════

  void _solveMathProblem(String problem) {
    _steps = [];
    _solution = '';

    // Normalize the problem
    String originalProblem = problem;
    problem = problem.toLowerCase().trim();

    try {
      // Detect problem type and solve accordingly
      if (_isDerivative(problem)) {
        _solveDerivativeAdvanced(problem);
      } else if (_isIntegral(problem)) {
        _solveIntegralAdvanced(problem);
      } else if (_isLimit(problem)) {
        _solveLimit(problem);
      } else if (_isTrigEquation(problem)) {
        _solveTrigEquation(problem);
      } else if (_isSystemOfEquations(problem)) {
        _solveSystemOfEquations(problem);
      } else if (_isCubicEquation(problem)) {
        _solveCubicEquation(problem);
      } else if (_isQuadraticEquation(problem)) {
        _solveQuadraticAdvanced(problem);
      } else if (problem.contains('=')) {
        _solveEquation(problem);
      } else if (_hasTrigFunction(problem)) {
        _solveTrigonometryAdvanced(problem);
      } else if (problem.contains('log') || problem.contains('ln')) {
        _solveLogarithmAdvanced(problem);
      } else if (problem.contains('!') || problem.contains('fact')) {
        _solveFactorial(problem);
      } else if (problem.contains('ncr') ||
          problem.contains('npr') ||
          problem.contains('choose')) {
        _solveCombinatorics(problem);
      } else if (problem.contains('sqrt') ||
          problem.contains('cbrt') ||
          problem.contains('^')) {
        _solveExponentOrRootAdvanced(problem);
      } else if (problem.contains('%')) {
        _solvePercentage(problem);
      } else {
        _evaluateExpressionAdvanced(problem);
      }

      setState(() {
        // Collapse results panel after solving to show collapsed summary
        _isResultsExpanded = false;
      });
    } catch (e) {
      setState(() {
        _solution = 'Could not solve: $originalProblem';
        _steps = [MathStep('Error', e.toString(), StepType.error)];
        _isResultsExpanded = false;
      });
    }
  }

  // Problem type detection helpers
  bool _isDerivative(String p) =>
      p.contains('derivative') ||
      p.contains('d/dx') ||
      p.contains("f'") ||
      p.contains('differentiate') ||
      p.contains("dy/dx");

  bool _isIntegral(String p) =>
      p.contains('integral') ||
      p.contains('integrate') ||
      p.contains('∫') ||
      p.contains('antiderivative');

  bool _isLimit(String p) =>
      p.contains('lim') ||
      p.contains('limit') ||
      p.contains('→') ||
      p.contains('->');

  bool _isTrigEquation(String p) => p.contains('=') && (_hasTrigFunction(p));

  bool _hasTrigFunction(String p) =>
      p.contains('sin') ||
      p.contains('cos') ||
      p.contains('tan') ||
      p.contains('cot') ||
      p.contains('sec') ||
      p.contains('csc') ||
      p.contains('sinh') ||
      p.contains('cosh') ||
      p.contains('tanh');

  bool _isSystemOfEquations(String p) =>
      p.contains(';') || (p.contains('and') && p.contains('='));

  bool _isCubicEquation(String p) => p.contains('^3') || p.contains('x³');

  bool _isQuadraticEquation(String p) =>
      p.contains('^2') || p.contains('x²') || p.contains('x*x');

  // ═══════════════════════════════════════════════════════════════════════════
  // ADVANCED SOLVER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _solveDerivativeAdvanced(String problem) {
    // Use the existing _solveDerivative for now, can enhance later
    _solveDerivative(problem);
  }

  void _solveIntegralAdvanced(String problem) {
    // Use the existing _solveIntegral for now
    _solveIntegral(problem);
  }

  void _solveLimit(String problem) {
    _steps.add(MathStep(problem, 'Evaluating limit', StepType.problem));

    // Extract limit expression: lim x->a f(x)
    RegExp limitPattern =
        RegExp(r'lim\s*(?:x\s*(?:->|→)\s*(\d+|infinity|∞))?\s*(.+)');
    var match = limitPattern.firstMatch(problem);

    if (match != null) {
      String? approach = match.group(1) ?? '0';
      String expr = match.group(2) ?? problem;

      _steps.add(
          MathStep('x → $approach', 'Approaching value', StepType.simplify));

      // Direct substitution for simple cases
      if (approach == 'infinity' || approach == '∞') {
        _steps.add(MathStep(
            'As x → ∞', 'Analyzing behavior at infinity', StepType.calculate));
        // Check if polynomial
        if (expr.contains('^')) {
          _steps.add(MathStep('For polynomials, highest degree term dominates',
              'Limit rule', StepType.rule));
        }
        _solution = 'Limit = ∞ (or analyze highest degree term)';
      } else {
        _steps.add(MathStep('Substitute x = $approach', 'Direct substitution',
            StepType.substitute));

        // Try simple evaluation
        String evalExpr = expr.replaceAll('x', '($approach)');
        try {
          double result = _calculate(evalExpr);
          _steps.add(MathStep(
              '= ${_formatNumber(result)}', 'Evaluation', StepType.calculate));
          _solution = 'lim = ${_formatNumber(result)}';
        } catch (e) {
          _solution =
              'Limit requires L\'Hôpital\'s rule or algebraic manipulation';
          _steps.add(
              MathStep('0/0 or ∞/∞ form', 'Indeterminate form', StepType.note));
        }
      }
    } else {
      _solution = 'Could not parse limit expression';
    }

    _steps.add(MathStep(_solution, 'Final answer', StepType.result));
  }

  void _solveTrigEquation(String problem) {
    _steps.add(
        MathStep(problem, 'Solving trigonometric equation', StepType.problem));

    // Common trig equations
    if (problem.contains('sin') && problem.contains('=')) {
      var parts = problem.split('=');
      String rightSide = parts.length > 1 ? parts[1].trim() : '0';
      double value = double.tryParse(rightSide) ?? 0;

      if (value >= -1 && value <= 1) {
        double angle = math.asin(value) * 180 / math.pi;
        _steps.add(
            MathStep('sin(x) = $value', 'Given equation', StepType.simplify));
        _steps.add(MathStep(
            'x = arcsin($value)', 'Taking inverse sine', StepType.calculate));
        _steps.add(MathStep('x = ${_formatNumber(angle)}° + 360°n',
            'Principal + period', StepType.calculate));
        _steps.add(MathStep('x = ${_formatNumber(180 - angle)}° + 360°n',
            'Second solution', StepType.calculate));
        _solution =
            'x = ${_formatNumber(angle)}° or ${_formatNumber(180 - angle)}° + 360°n';
      } else {
        _solution = 'No real solution (|sin(x)| ≤ 1)';
      }
    } else if (problem.contains('cos') && problem.contains('=')) {
      var parts = problem.split('=');
      String rightSide = parts.length > 1 ? parts[1].trim() : '0';
      double value = double.tryParse(rightSide) ?? 0;

      if (value >= -1 && value <= 1) {
        double angle = math.acos(value) * 180 / math.pi;
        _steps.add(
            MathStep('cos(x) = $value', 'Given equation', StepType.simplify));
        _steps.add(MathStep(
            'x = arccos($value)', 'Taking inverse cosine', StepType.calculate));
        _steps.add(MathStep('x = ±${_formatNumber(angle)}° + 360°n',
            'Solutions', StepType.calculate));
        _solution = 'x = ±${_formatNumber(angle)}° + 360°n';
      } else {
        _solution = 'No real solution (|cos(x)| ≤ 1)';
      }
    } else if (problem.contains('tan') && problem.contains('=')) {
      var parts = problem.split('=');
      String rightSide = parts.length > 1 ? parts[1].trim() : '0';
      double value = double.tryParse(rightSide) ?? 0;

      double angle = math.atan(value) * 180 / math.pi;
      _steps.add(
          MathStep('tan(x) = $value', 'Given equation', StepType.simplify));
      _steps.add(MathStep(
          'x = arctan($value)', 'Taking inverse tangent', StepType.calculate));
      _steps.add(MathStep('x = ${_formatNumber(angle)}° + 180°n',
          'Solution with period', StepType.calculate));
      _solution = 'x = ${_formatNumber(angle)}° + 180°n';
    } else {
      _solution = 'Complex trig equation - try manual solving';
    }

    _steps.add(MathStep(_solution, 'Final answer', StepType.result));
  }

  void _solveSystemOfEquations(String problem) {
    _steps.add(
        MathStep(problem, 'Solving system of equations', StepType.problem));

    // Split by semicolon or 'and'
    List<String> equations =
        problem.contains(';') ? problem.split(';') : problem.split(' and ');

    if (equations.length == 2) {
      _steps.add(MathStep(
          'Eq 1: ${equations[0].trim()}', 'First equation', StepType.simplify));
      _steps.add(MathStep('Eq 2: ${equations[1].trim()}', 'Second equation',
          StepType.simplify));
      _steps.add(MathStep('Using substitution or elimination method',
          'Approach', StepType.rule));

      // Simple case: try to extract and solve
      // For now, provide guidance
      _solution =
          'System requires manual solving:\n1. Solve one equation for x or y\n2. Substitute into the other\n3. Solve for remaining variable';
    } else {
      _solution = 'Please enter two equations separated by semicolon';
    }

    _steps.add(MathStep(_solution, 'Guidance', StepType.note));
  }

  void _solveCubicEquation(String problem) {
    _steps.add(MathStep(problem, 'Solving cubic equation', StepType.problem));
    _steps.add(
        MathStep('ax³ + bx² + cx + d = 0', 'Standard form', StepType.rule));

    // For now, provide factoring guidance
    _steps
        .add(MathStep('Try rational root theorem', 'Method 1', StepType.note));
    _steps.add(MathStep('Possible roots: ±(factors of d)/(factors of a)',
        'Finding roots', StepType.calculate));
    _steps.add(MathStep('After finding one root, use polynomial division',
        'Reduce to quadratic', StepType.note));

    _solution =
        'Cubic equations: Try x = ±1, ±2, ±3... to find a root, then factor';
    _steps.add(MathStep(_solution, 'Guidance', StepType.result));
  }

  void _solveQuadraticAdvanced(String problem) {
    // Use the existing quadratic solver
    _solveQuadratic(problem);
  }

  void _solveTrigonometryAdvanced(String problem) {
    // Use existing trig solver
    _solveTrigonometry(problem);
  }

  void _solveLogarithmAdvanced(String problem) {
    // Use existing log solver
    _solveLogarithm(problem);
  }

  void _solveFactorial(String problem) {
    _steps.add(MathStep(problem, 'Calculating factorial', StepType.problem));

    RegExp factPattern = RegExp(r'(\d+)[!]|fact\(?(\d+)\)?');
    var match = factPattern.firstMatch(problem);

    if (match != null) {
      int n = int.parse(match.group(1) ?? match.group(2) ?? '0');

      if (n > 20) {
        _solution = 'Factorial too large (n ≤ 20 supported)';
        return;
      }

      _steps.add(MathStep('n! = n × (n-1) × (n-2) × ... × 2 × 1',
          'Factorial definition', StepType.rule));

      int result = 1;
      String expansion = '';
      for (int i = n; i >= 1; i--) {
        result *= i;
        expansion += i.toString() + (i > 1 ? ' × ' : '');
      }

      _steps.add(MathStep('$n! = $expansion', 'Expanding', StepType.calculate));
      _steps.add(MathStep('= $result', 'Calculating', StepType.calculate));

      _solution = '$n! = $result';
      _lastAnswer = result.toString();
    } else {
      _solution = 'Could not parse factorial';
    }

    _steps.add(MathStep(_solution, 'Final answer', StepType.result));
  }

  void _solveCombinatorics(String problem) {
    _steps.add(MathStep(problem, 'Solving combinatorics', StepType.problem));

    // nCr = n! / (r! * (n-r)!)
    RegExp ncrPattern =
        RegExp(r'(\d+)\s*(?:c|choose)\s*(\d+)', caseSensitive: false);
    // nPr = n! / (n-r)!
    RegExp nprPattern = RegExp(r'(\d+)\s*p\s*(\d+)', caseSensitive: false);

    var ncrMatch = ncrPattern.firstMatch(problem);
    var nprMatch = nprPattern.firstMatch(problem);

    if (ncrMatch != null) {
      int n = int.parse(ncrMatch.group(1)!);
      int r = int.parse(ncrMatch.group(2)!);

      _steps.add(MathStep(
          'nCr = n! / (r! × (n-r)!)', 'Combination formula', StepType.rule));
      _steps.add(MathStep('${n}C$r = $n! / ($r! × ${n - r}!)', 'Substituting',
          StepType.substitute));

      int result = _factorial(n) ~/ (_factorial(r) * _factorial(n - r));

      _solution = '${n}C$r = $result';
      _lastAnswer = result.toString();
    } else if (nprMatch != null) {
      int n = int.parse(nprMatch.group(1)!);
      int r = int.parse(nprMatch.group(2)!);

      _steps.add(
          MathStep('nPr = n! / (n-r)!', 'Permutation formula', StepType.rule));
      _steps.add(MathStep(
          '${n}P$r = $n! / ${n - r}!', 'Substituting', StepType.substitute));

      int result = _factorial(n) ~/ _factorial(n - r);

      _solution = '${n}P$r = $result';
      _lastAnswer = result.toString();
    } else {
      _solution = 'Use format: nCr (e.g., 5C2) or nPr (e.g., 5P2)';
    }

    _steps.add(MathStep(_solution, 'Final answer', StepType.result));
  }

  int _factorial(int n) {
    if (n <= 1) return 1;
    int result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  void _solveExponentOrRootAdvanced(String problem) {
    // Use existing solver
    _solveExponentOrRoot(problem);
  }

  void _solvePercentage(String problem) {
    _steps.add(MathStep(problem, 'Calculating percentage', StepType.problem));

    // Pattern: X% of Y or X% * Y
    RegExp percentOfPattern = RegExp(r'(\d+\.?\d*)%\s*(?:of|\*)\s*(\d+\.?\d*)');
    var match = percentOfPattern.firstMatch(problem);

    if (match != null) {
      double percent = double.parse(match.group(1)!);
      double value = double.parse(match.group(2)!);

      _steps.add(MathStep('$percent% of $value', 'Given', StepType.simplify));
      _steps.add(MathStep(
          '= ($percent/100) × $value', 'Converting %', StepType.calculate));

      double result = (percent / 100) * value;

      _steps.add(
          MathStep('= ${_formatNumber(result)}', 'Result', StepType.calculate));
      _solution = '$percent% of $value = ${_formatNumber(result)}';
      _lastAnswer = _formatNumber(result);
    } else {
      // Just convert percentage to decimal
      RegExp simplePercent = RegExp(r'(\d+\.?\d*)%');
      var simpleMatch = simplePercent.firstMatch(problem);
      if (simpleMatch != null) {
        double percent = double.parse(simpleMatch.group(1)!);
        double decimal = percent / 100;
        _steps.add(MathStep('$percent% = $percent/100', 'Converting to decimal',
            StepType.calculate));
        _solution = '$percent% = ${_formatNumber(decimal)}';
        _lastAnswer = _formatNumber(decimal);
      } else {
        _solution = 'Could not parse percentage';
      }
    }

    _steps.add(MathStep(_solution, 'Final answer', StepType.result));
  }

  void _evaluateExpressionAdvanced(String problem) {
    // Use existing expression evaluator
    _evaluateExpression(problem);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BASIC SOLVER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _solveEquation(String equation) {
    _steps.add(MathStep(equation, 'Solving equation', StepType.problem));

    // Split by equals sign
    final parts = equation.split('=');
    if (parts.length != 2) {
      _solution = 'Invalid equation format';
      return;
    }

    String left = parts[0].trim();
    String right = parts[1].trim();

    // Check for quadratic equation (contains x^2 or x*x)
    if (equation.contains('^2') ||
        equation.contains('x*x') ||
        equation.contains('x²')) {
      _solveQuadratic(equation);
      return;
    }

    // Linear equation solving
    _solveLinear(left, right);
  }

  void _solveLinear(String left, String right) {
    _steps.add(MathStep(
        '$left = $right', 'This is a linear equation', StepType.problem));
    _steps.add(MathStep('Move x terms left, constants right', 'Rearranging',
        StepType.simplify));

    try {
      // Parse coefficients
      double leftCoeff = _extractCoefficient(left, 'x');
      double leftConst = _extractConstant(left);
      double rightCoeff = _extractCoefficient(right, 'x');
      double rightConst = _extractConstant(right);

      _steps.add(MathStep('Left: ${leftCoeff}x + $leftConst',
          'Parsing left side', StepType.calculate));
      _steps.add(MathStep('Right: ${rightCoeff}x + $rightConst',
          'Parsing right side', StepType.calculate));

      // Combine: (leftCoeff - rightCoeff)x = rightConst - leftConst
      double finalCoeff = leftCoeff - rightCoeff;
      double finalConst = rightConst - leftConst;

      _steps.add(MathStep('${finalCoeff}x = $finalConst',
          'Combining like terms', StepType.simplify));

      if (finalCoeff == 0) {
        if (finalConst == 0) {
          _solution = 'Infinite solutions (identity equation)';
        } else {
          _solution = 'No solution (contradiction)';
        }
      } else {
        double result = finalConst / finalCoeff;
        _steps.add(MathStep('x = $finalConst ÷ $finalCoeff',
            'Dividing both sides by $finalCoeff', StepType.calculate));
        _steps.add(MathStep(
            'x = ${_formatNumber(result)}', 'Final answer', StepType.result));
        _solution = 'x = ${_formatNumber(result)}';
        _lastAnswer = _formatNumber(result);
      }
    } catch (e) {
      _solution = 'Could not solve linear equation';
      _steps.add(MathStep(
          'Error', 'Error parsing equation coefficients', StepType.error));
    }
  }

  void _solveQuadratic(String equation) {
    _steps.add(
        MathStep(equation, 'This is a quadratic equation', StepType.problem));
    _steps.add(MathStep(
        'x = (-b ± √(b²-4ac)) / 2a', 'Using quadratic formula', StepType.rule));

    try {
      // Parse ax² + bx + c = 0
      double a = 0, b = 0, c = 0;

      // Normalize equation to standard form
      String normalized = equation.replaceAll(' ', '').toLowerCase();

      // Move everything to left side if needed
      if (normalized.contains('=')) {
        var parts = normalized.split('=');
        String leftSide = parts[0];
        String rightSide = parts[1];

        // If right side is not just 0, we need to handle it
        if (rightSide != '0') {
          // For simplicity, assume standard form ax^2+bx+c=0
        }
        normalized = leftSide;
      }

      // Extract coefficient of x^2
      RegExp aPattern = RegExp(r'([+-]?\d*\.?\d*)[x]\^?2');
      var aMatch = aPattern.firstMatch(normalized);
      if (aMatch != null) {
        String coeff = aMatch.group(1) ?? '1';
        if (coeff.isEmpty || coeff == '+') coeff = '1';
        if (coeff == '-') coeff = '-1';
        a = double.tryParse(coeff) ?? 1;
      } else {
        a = 1;
      }

      // Extract coefficient of x (not x^2)
      RegExp bPattern = RegExp(r'([+-]?\d*\.?\d*)x(?!\^)');
      var bMatch = bPattern.firstMatch(normalized);
      if (bMatch != null) {
        String coeff = bMatch.group(1) ?? '0';
        if (coeff.isEmpty || coeff == '+') coeff = '1';
        if (coeff == '-') coeff = '-1';
        b = double.tryParse(coeff) ?? 0;
      }

      // Extract constant term - numbers not followed by x
      RegExp cPattern = RegExp(r'([+-]?\d+\.?\d*)(?![x\d])');
      var cMatches = cPattern.allMatches(normalized);
      for (var match in cMatches) {
        String val = match.group(1) ?? '0';
        // Make sure it's not part of x^2 or coefficient
        if (!normalized.substring(0, match.start).endsWith('x') &&
            !normalized.substring(0, match.start).endsWith('^')) {
          c += double.tryParse(val) ?? 0;
        }
      }

      // If we couldn't parse properly, try simpler approach
      if (a == 0) a = 1;

      _steps.add(MathStep('a = $a, b = $b, c = $c', 'Identified coefficients',
          StepType.simplify));

      // Calculate discriminant
      double discriminant = b * b - 4 * a * c;
      _steps.add(MathStep('Δ = b² - 4ac = ${_formatNumber(discriminant)}',
          'Calculate discriminant', StepType.calculate));

      if (discriminant < 0) {
        double realPart = -b / (2 * a);
        double imaginaryPart = math.sqrt(-discriminant) / (2 * a);
        _steps.add(MathStep(
            'Δ < 0, complex roots', 'Discriminant is negative', StepType.note));
        _solution =
            'x₁ = ${_formatNumber(realPart)} + ${_formatNumber(imaginaryPart)}i\n'
            'x₂ = ${_formatNumber(realPart)} - ${_formatNumber(imaginaryPart)}i';
      } else if (discriminant == 0) {
        double x = -b / (2 * a);
        _steps.add(MathStep('x = -b / 2a = ${_formatNumber(x)}',
            'Discriminant is zero (double root)', StepType.calculate));
        _steps.add(MathStep(
            'x = ${_formatNumber(x)}', 'Final answer', StepType.result));
        _solution = 'x = ${_formatNumber(x)} (double root)';
        _lastAnswer = _formatNumber(x);
      } else {
        double x1 = (-b + math.sqrt(discriminant)) / (2 * a);
        double x2 = (-b - math.sqrt(discriminant)) / (2 * a);
        _steps.add(MathStep('x₁ = (-b + √Δ) / 2a = ${_formatNumber(x1)}',
            'First root', StepType.calculate));
        _steps.add(MathStep('x₂ = (-b - √Δ) / 2a = ${_formatNumber(x2)}',
            'Second root', StepType.calculate));
        _solution = 'x₁ = ${_formatNumber(x1)}\nx₂ = ${_formatNumber(x2)}';
        _lastAnswer = _formatNumber(x1);
      }
    } catch (e) {
      _solution = 'Could not solve quadratic equation';
      _steps.add(MathStep('Error', e.toString(), StepType.error));
    }
  }

  void _solveDerivative(String problem) {
    _steps.add(MathStep(problem, 'Finding derivative', StepType.problem));

    // Extract the expression to differentiate
    String expr = problem
        .replaceAll('derivative', '')
        .replaceAll('d/dx', '')
        .replaceAll("f'(x)", '')
        .replaceAll("f'", '')
        .replaceAll('of', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .trim();

    _steps.add(MathStep(
        'f(x) = $expr', 'Expression to differentiate', StepType.simplify));

    // Power rule: d/dx(x^n) = n*x^(n-1)
    RegExp powerPattern = RegExp(r'(\d*)x\^(\d+)');
    var match = powerPattern.firstMatch(expr);
    if (match != null) {
      double coeff = double.tryParse(match.group(1) ?? '1') ?? 1;
      if (match.group(1)?.isEmpty ?? true) coeff = 1;
      int power = int.parse(match.group(2)!);

      double newCoeff = coeff * power;
      int newPower = power - 1;

      _steps.add(MathStep('d/dx(xⁿ) = n·xⁿ⁻¹', 'Power Rule', StepType.rule));
      _steps.add(MathStep('n = $power, coefficient = ${coeff.toInt()}',
          'Identifying values', StepType.calculate));
      _steps.add(MathStep(
          '$power × ${coeff == 1 ? '' : '${coeff.toInt()} = '}${newCoeff.toInt()}',
          'New coefficient',
          StepType.calculate));

      if (newPower == 0) {
        _solution = "f'(x) = ${_formatNumber(newCoeff)}";
      } else if (newPower == 1) {
        _solution = "f'(x) = ${newCoeff == 1 ? '' : _formatNumber(newCoeff)}x";
      } else {
        _solution =
            "f'(x) = ${newCoeff == 1 ? '' : _formatNumber(newCoeff)}x^$newPower";
      }
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      _lastAnswer = _solution;
      return;
    }

    // Check for just x^n without coefficient
    RegExp simplePattern = RegExp(r'x\^(\d+)');
    var simpleMatch = simplePattern.firstMatch(expr);
    if (simpleMatch != null) {
      int power = int.parse(simpleMatch.group(1)!);
      int newPower = power - 1;

      _steps.add(MathStep('d/dx(xⁿ) = n·xⁿ⁻¹', 'Power Rule', StepType.rule));

      if (newPower == 0) {
        _solution = "f'(x) = $power";
      } else if (newPower == 1) {
        _solution = "f'(x) = ${power}x";
      } else {
        _solution = "f'(x) = ${power}x^$newPower";
      }
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      _lastAnswer = _solution;
      return;
    }

    // Trigonometric derivatives
    if (expr.contains('sin')) {
      _steps.add(MathStep(
          'd/dx(sin(x)) = cos(x)', 'Sine derivative rule', StepType.rule));
      _solution = "f'(x) = cos(x)";
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    if (expr.contains('cos')) {
      _steps.add(MathStep(
          'd/dx(cos(x)) = -sin(x)', 'Cosine derivative rule', StepType.rule));
      _solution = "f'(x) = -sin(x)";
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    if (expr.contains('tan')) {
      _steps.add(MathStep(
          'd/dx(tan(x)) = sec²(x)', 'Tangent derivative rule', StepType.rule));
      _solution = "f'(x) = sec²(x)";
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    if (expr.contains('ln') || expr.contains('log')) {
      _steps.add(MathStep(
          'd/dx(ln(x)) = 1/x', 'Natural log derivative', StepType.rule));
      _solution = "f'(x) = 1/x";
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    if (expr.contains('e^x')) {
      _steps.add(
          MathStep('d/dx(eˣ) = eˣ', 'Exponential derivative', StepType.rule));
      _solution = "f'(x) = e^x";
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    // If just x
    if (expr.trim() == 'x') {
      _steps.add(MathStep('d/dx(x) = 1', 'Derivative of x', StepType.rule));
      _solution = "f'(x) = 1";
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    // If constant
    if (double.tryParse(expr.trim()) != null) {
      _steps.add(MathStep(
          'd/dx(c) = 0', 'Derivative of constant is 0', StepType.rule));
      _solution = "f'(x) = 0";
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    _solution = 'Could not find derivative of: $expr';
    _steps.add(MathStep('Supported: xⁿ, sin(x), cos(x), tan(x), ln(x), eˣ',
        'Tip', StepType.note));
  }

  void _solveIntegral(String problem) {
    _steps.add(MathStep(
        problem, 'Finding integral (antiderivative)', StepType.problem));

    String expr = problem
        .replaceAll('integral', '')
        .replaceAll('∫', '')
        .replaceAll('dx', '')
        .replaceAll('of', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .trim();

    _steps.add(
        MathStep('∫$expr dx', 'Expression to integrate', StepType.simplify));

    // Power rule: ∫x^n dx = x^(n+1)/(n+1) + C
    RegExp powerPattern = RegExp(r'(\d*)x\^(\d+)');
    var match = powerPattern.firstMatch(expr);
    if (match != null) {
      double coeff = double.tryParse(match.group(1) ?? '1') ?? 1;
      if (match.group(1)?.isEmpty ?? true) coeff = 1;
      int power = int.parse(match.group(2)!);

      int newPower = power + 1;

      _steps.add(MathStep('∫xⁿ dx = xⁿ⁺¹/(n+1) + C', 'Power Rule for integrals',
          StepType.rule));
      _steps.add(MathStep('n = $power, new power = $newPower',
          'Calculating new power', StepType.calculate));

      if (coeff == 1) {
        _solution = '∫x^$power dx = x^$newPower/$newPower + C';
      } else {
        _solution =
            '∫${coeff.toInt()}x^$power dx = (${coeff.toInt()}/$newPower)x^$newPower + C';
      }
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    // Simple x^n
    RegExp simplePattern = RegExp(r'x\^(\d+)');
    var simpleMatch = simplePattern.firstMatch(expr);
    if (simpleMatch != null) {
      int power = int.parse(simpleMatch.group(1)!);
      int newPower = power + 1;

      _steps.add(
          MathStep('∫xⁿ dx = xⁿ⁺¹/(n+1) + C', 'Power Rule', StepType.rule));
      _solution = '∫x^$power dx = x^$newPower/$newPower + C';
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    if (expr.trim() == 'x') {
      _steps.add(
          MathStep('∫x dx = x²/2 + C', 'Power rule with n=1', StepType.rule));
      _solution = '∫x dx = x²/2 + C';
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    if (double.tryParse(expr.trim()) != null) {
      double c = double.parse(expr.trim());
      _steps.add(
          MathStep('∫k dx = kx + C', 'Integral of constant', StepType.rule));
      _solution = '∫${_formatNumber(c)} dx = ${_formatNumber(c)}x + C';
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    if (expr.contains('sin')) {
      _steps.add(MathStep(
          '∫sin(x) dx = -cos(x) + C', 'Sine integral rule', StepType.rule));
      _solution = '∫sin(x) dx = -cos(x) + C';
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    if (expr.contains('cos')) {
      _steps.add(MathStep(
          '∫cos(x) dx = sin(x) + C', 'Cosine integral rule', StepType.rule));
      _solution = '∫cos(x) dx = sin(x) + C';
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    if (expr.contains('e^x')) {
      _steps.add(MathStep(
          '∫eˣ dx = eˣ + C', 'Exponential integral rule', StepType.rule));
      _solution = '∫e^x dx = e^x + C';
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    if (expr.contains('1/x')) {
      _steps.add(MathStep(
          '∫(1/x) dx = ln|x| + C', 'Reciprocal integral rule', StepType.rule));
      _solution = '∫(1/x) dx = ln|x| + C';
      _steps.add(MathStep(_solution, 'Final answer', StepType.result));
      return;
    }

    _solution = 'Could not find integral of: $expr';
    _steps.add(MathStep('Supported: xⁿ, sin(x), cos(x), eˣ, 1/x, constants',
        'Tip', StepType.note));
  }

  void _solveTrigonometry(String problem) {
    _steps.add(MathStep(
        problem, 'Evaluating trigonometric expression', StepType.problem));

    try {
      // Extract angle value
      RegExp anglePattern = RegExp(r'(a?sin|a?cos|a?tan)\(?(\d+\.?\d*)\)?');
      var match = anglePattern.firstMatch(problem);

      if (match != null) {
        String func = match.group(1)!;
        double angle = double.parse(match.group(2)!);

        // Assume degrees if angle > 2π ≈ 6.28
        bool isDegrees = angle > 6.28;
        double radians = isDegrees ? angle * math.pi / 180 : angle;

        _steps.add(MathStep(
            '${_formatNumber(angle)} ${isDegrees ? "degrees" : "radians"}',
            'Input angle',
            StepType.simplify));
        if (isDegrees) {
          _steps.add(MathStep('${_formatNumber(radians)} rad',
              'Converting to radians', StepType.calculate));
        }

        double result;
        String funcDisplay = func;

        switch (func) {
          case 'sin':
            result = math.sin(radians);
            _steps.add(MathStep(
                'sin(${_formatNumber(angle)}${isDegrees ? "°" : ""}) = ${_formatNumber(result)}',
                'Calculating sine',
                StepType.calculate));
            break;
          case 'cos':
            result = math.cos(radians);
            _steps.add(MathStep(
                'cos(${_formatNumber(angle)}${isDegrees ? "°" : ""}) = ${_formatNumber(result)}',
                'Calculating cosine',
                StepType.calculate));
            break;
          case 'tan':
            result = math.tan(radians);
            _steps.add(MathStep(
                'tan(${_formatNumber(angle)}${isDegrees ? "°" : ""}) = ${_formatNumber(result)}',
                'Calculating tangent',
                StepType.calculate));
            break;
          case 'asin':
            if (angle < -1 || angle > 1) {
              _solution = 'Error: arcsin is only defined for -1 ≤ x ≤ 1';
              return;
            }
            result = math.asin(angle) * 180 / math.pi;
            _steps.add(MathStep(
                'arcsin(${_formatNumber(angle)}) = ${_formatNumber(result)}°',
                'Calculating arcsine',
                StepType.calculate));
            funcDisplay = 'arcsin';
            break;
          case 'acos':
            if (angle < -1 || angle > 1) {
              _solution = 'Error: arccos is only defined for -1 ≤ x ≤ 1';
              return;
            }
            result = math.acos(angle) * 180 / math.pi;
            _steps.add(MathStep(
                'arccos(${_formatNumber(angle)}) = ${_formatNumber(result)}°',
                'Calculating arccosine',
                StepType.calculate));
            funcDisplay = 'arccos';
            break;
          case 'atan':
            result = math.atan(angle) * 180 / math.pi;
            _steps.add(MathStep(
                'arctan(${_formatNumber(angle)}) = ${_formatNumber(result)}°',
                'Calculating arctangent',
                StepType.calculate));
            funcDisplay = 'arctan';
            break;
          default:
            result = 0;
        }

        _solution =
            '$funcDisplay(${_formatNumber(angle)}) = ${_formatNumber(result)}${func.startsWith('a') ? '°' : ''}';
        _steps.add(MathStep(_solution, 'Final answer', StepType.result));
        _lastAnswer = _formatNumber(result);
        return;
      }

      // Trig identities
      if (problem.contains('sin^2') && problem.contains('cos^2')) {
        _steps.add(MathStep('sin²(θ) + cos²(θ)',
            'Recognizing Pythagorean identity', StepType.rule));
        _steps
            .add(MathStep('= 1 for all θ', 'Identity result', StepType.result));
        _solution = 'sin²(x) + cos²(x) = 1';
        return;
      }

      // Try to evaluate as expression
      _evaluateExpression(problem);
    } catch (e) {
      _solution = 'Error evaluating trigonometry';
      _steps.add(MathStep(e.toString(), 'Error', StepType.error));
    }
  }

  void _solveLogarithm(String problem) {
    _steps.add(MathStep(problem, 'Evaluating logarithm', StepType.problem));

    try {
      RegExp logPattern = RegExp(r'(log|ln)\(?(\d+\.?\d*)\)?');
      var match = logPattern.firstMatch(problem);

      if (match != null) {
        String func = match.group(1)!;
        double value = double.parse(match.group(2)!);

        if (value <= 0) {
          _solution = 'Error: Logarithm is undefined for x ≤ 0';
          _steps.add(MathStep(
              'Domain: x > 0', 'Logarithm domain restriction', StepType.note));
          return;
        }

        double result;
        if (func == 'ln') {
          result = math.log(value);
          _steps.add(MathStep(
              'ln($value)', 'Natural logarithm (base e)', StepType.simplify));
          _steps.add(MathStep('ln($value) = ${_formatNumber(result)}',
              'Calculating', StepType.calculate));
          _solution = 'ln(${_formatNumber(value)}) = ${_formatNumber(result)}';
        } else {
          result = math.log(value) / math.ln10;
          _steps.add(MathStep(
              'log₁₀($value)', 'Logarithm base 10', StepType.simplify));
          _steps.add(MathStep('log₁₀($value) = ${_formatNumber(result)}',
              'Calculating', StepType.calculate));
          _solution = 'log(${_formatNumber(value)}) = ${_formatNumber(result)}';
        }

        _steps.add(MathStep(_solution, 'Final answer', StepType.result));
        _lastAnswer = _formatNumber(result);
        return;
      }

      // Log rules explanation
      if (problem.contains('log') && problem.contains('*')) {
        _steps.add(MathStep(
            'log(a·b) = log(a) + log(b)', 'Product rule', StepType.rule));
        _solution = 'log(a × b) = log(a) + log(b)';
        return;
      }

      if (problem.contains('log') && problem.contains('/')) {
        _steps.add(MathStep(
            'log(a/b) = log(a) - log(b)', 'Quotient rule', StepType.rule));
        _solution = 'log(a ÷ b) = log(a) - log(b)';
        return;
      }

      _evaluateExpression(problem);
    } catch (e) {
      _solution = 'Error evaluating logarithm';
      _steps.add(MathStep(e.toString(), 'Error', StepType.error));
    }
  }

  void _solveExponentOrRoot(String problem) {
    _steps.add(MathStep(problem, 'Evaluating expression', StepType.problem));

    try {
      // Square root
      if (problem.contains('sqrt')) {
        RegExp sqrtPattern = RegExp(r'sqrt\(?(\d+\.?\d*)\)?');
        var match = sqrtPattern.firstMatch(problem);
        if (match != null) {
          double value = double.parse(match.group(1)!);
          if (value < 0) {
            _solution = 'Error: Cannot take square root of negative number';
            _steps.add(MathStep('√$value is undefined in real numbers',
                'Domain error', StepType.error));
            return;
          }
          double result = math.sqrt(value);
          _steps.add(MathStep(
              '√${_formatNumber(value)}', 'Square root', StepType.simplify));
          _steps.add(MathStep(
              '= ${_formatNumber(result)}', 'Result', StepType.calculate));
          _solution = '√${_formatNumber(value)} = ${_formatNumber(result)}';
          _steps.add(MathStep(_solution, 'Final answer', StepType.result));
          _lastAnswer = _formatNumber(result);
          return;
        }
      }

      // Power
      if (problem.contains('^')) {
        RegExp powerPattern = RegExp(r'(\d+\.?\d*)\^(\d+\.?\d*)');
        var match = powerPattern.firstMatch(problem);
        if (match != null) {
          double base = double.parse(match.group(1)!);
          double exp = double.parse(match.group(2)!);
          double result = math.pow(base, exp).toDouble();
          _steps.add(MathStep('${_formatNumber(base)}^${_formatNumber(exp)}',
              'Exponentiation', StepType.simplify));
          _steps.add(MathStep(
              '${_formatNumber(base)} raised to power ${_formatNumber(exp)}',
              'Calculating',
              StepType.calculate));
          _steps.add(MathStep(
              '= ${_formatNumber(result)}', 'Result', StepType.calculate));
          _solution =
              '${_formatNumber(base)}^${_formatNumber(exp)} = ${_formatNumber(result)}';
          _steps.add(MathStep(_solution, 'Final answer', StepType.result));
          _lastAnswer = _formatNumber(result);
          return;
        }
      }

      _evaluateExpression(problem);
    } catch (e) {
      _solution = 'Error: ${e.toString()}';
      _steps.add(MathStep(e.toString(), 'Error', StepType.error));
    }
  }

  void _evaluateExpression(String expression) {
    _steps.add(MathStep(expression, 'Evaluating expression', StepType.problem));

    try {
      // Replace pi and e with values
      expression = expression
          .replaceAll('pi', '3.14159265359')
          .replaceAll('e', '2.71828182846');

      double result = _calculate(expression);
      _solution = '= ${_formatNumber(result)}';
      _lastAnswer = _formatNumber(result);
      _steps.add(MathStep(_formatNumber(result), 'Result', StepType.result));
    } catch (e) {
      _solution = 'Could not evaluate expression';
      _steps.add(
          MathStep('Make sure the expression is valid', 'Tip', StepType.note));
    }
  }

  double _calculate(String expression) {
    expression = expression.replaceAll(' ', '');

    // Handle empty expression
    if (expression.isEmpty) return 0;

    // Handle parentheses first (innermost first)
    while (expression.contains('(')) {
      RegExp parenPattern = RegExp(r'\(([^()]+)\)');
      var match = parenPattern.firstMatch(expression);
      if (match != null) {
        double innerResult = _calculate(match.group(1)!);
        expression =
            expression.replaceFirst(match.group(0)!, innerResult.toString());
      } else {
        break;
      }
    }

    // Handle power (^) - right to left
    if (expression.contains('^')) {
      int lastPow = expression.lastIndexOf('^');
      if (lastPow > 0 && lastPow < expression.length - 1) {
        String left = expression.substring(0, lastPow);
        String right = expression.substring(lastPow + 1);

        // Find the base (last number before ^)
        RegExp basePattern = RegExp(r'(\d+\.?\d*)$');
        var baseMatch = basePattern.firstMatch(left);
        if (baseMatch != null) {
          double base = double.parse(baseMatch.group(1)!);

          // Find the exponent (first number/expression after ^)
          RegExp expPattern = RegExp(r'^(\d+\.?\d*)');
          var expMatch = expPattern.firstMatch(right);
          if (expMatch != null) {
            double exp = double.parse(expMatch.group(1)!);
            double result = math.pow(base, exp).toDouble();

            String newExpr = left.substring(0, baseMatch.start) +
                result.toString() +
                right.substring(expMatch.end);
            return _calculate(newExpr);
          }
        }
      }
    }

    // Parse addition and subtraction (lowest precedence)
    List<double> numbers = [];
    List<String> operators = [];

    String currentNum = '';
    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];

      if ((char == '+' || char == '-') &&
          i > 0 &&
          !RegExp(r'[+\-*/^]').hasMatch(expression[i - 1])) {
        if (currentNum.isNotEmpty) {
          numbers.add(_evaluateMulDiv(currentNum));
          currentNum = '';
        }
        operators.add(char);
      } else {
        currentNum += char;
      }
    }
    if (currentNum.isNotEmpty) {
      numbers.add(_evaluateMulDiv(currentNum));
    }

    // If no operators, just evaluate as multiplication/division
    if (operators.isEmpty && numbers.length == 1) {
      return numbers[0];
    }

    // Calculate result with + and -
    double result = numbers.isNotEmpty ? numbers[0] : 0;
    for (int i = 0; i < operators.length && i + 1 < numbers.length; i++) {
      if (operators[i] == '+') {
        result += numbers[i + 1];
      } else if (operators[i] == '-') {
        result -= numbers[i + 1];
      }
    }

    return result;
  }

  double _evaluateMulDiv(String expression) {
    if (expression.isEmpty) return 0;

    // Handle leading negative
    bool negative = false;
    if (expression.startsWith('-')) {
      negative = true;
      expression = expression.substring(1);
    } else if (expression.startsWith('+')) {
      expression = expression.substring(1);
    }

    List<double> numbers = [];
    List<String> operators = [];

    String currentNum = '';
    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];
      if (char == '*' || char == '/') {
        if (currentNum.isNotEmpty) {
          numbers.add(double.tryParse(currentNum) ?? 0);
          currentNum = '';
        }
        operators.add(char);
      } else {
        currentNum += char;
      }
    }
    if (currentNum.isNotEmpty) {
      numbers.add(double.tryParse(currentNum) ?? 0);
    }

    if (numbers.isEmpty) return 0;

    double result = numbers[0];
    for (int i = 0; i < operators.length && i + 1 < numbers.length; i++) {
      if (operators[i] == '*') {
        result *= numbers[i + 1];
      } else if (operators[i] == '/') {
        if (numbers[i + 1] != 0) {
          result /= numbers[i + 1];
        } else {
          throw Exception('Division by zero');
        }
      }
    }

    return negative ? -result : result;
  }

  double _extractCoefficient(String expr, String variable) {
    double coeff = 0;
    expr = expr.replaceAll(' ', '');

    // Match patterns like 2x, -3x, +x, -x, x
    RegExp pattern = RegExp('([+-]?\\d*\\.?\\d*)$variable');
    for (var match in pattern.allMatches(expr)) {
      String c = match.group(1) ?? '1';
      if (c.isEmpty || c == '+') c = '1';
      if (c == '-') c = '-1';
      coeff += double.tryParse(c) ?? 0;
    }

    return coeff;
  }

  double _extractConstant(String expr) {
    double constant = 0;
    expr = expr.replaceAll(' ', '');

    // Remove all terms with x
    String withoutX = expr.replaceAll(RegExp(r'[+-]?\d*\.?\d*x'), '');

    // Sum remaining numbers
    RegExp pattern = RegExp(r'[+-]?\d+\.?\d*');
    for (var match in pattern.allMatches(withoutX)) {
      constant += double.tryParse(match.group(0)!) ?? 0;
    }

    return constant;
  }

  // Helper to get step color based on type
  Color _getStepColor(StepType type, Color primaryColor) {
    switch (type) {
      case StepType.problem:
        return Colors.blue;
      case StepType.rule:
        return Colors.purple;
      case StepType.simplify:
        return Colors.orange;
      case StepType.calculate:
        return Colors.teal;
      case StepType.result:
        return Colors.green;
      case StepType.error:
        return Colors.red;
      case StepType.note:
        return Colors.grey;
      case StepType.substitute:
        return Colors.indigo;
    }
  }

  // Helper to format steps as text for clipboard
  String _stepsToString() {
    return _steps
        .map((step) => '${step.explanation}: ${step.expression}')
        .join('\n');
  }

  String _formatNumber(double n) {
    if (n.isNaN || n.isInfinite) return n.toString();
    if (n == n.roundToDouble() && n.abs() < 1e10) {
      return n.toInt().toString();
    }
    String formatted = n.toStringAsFixed(6);
    // Remove trailing zeros
    formatted = formatted.replaceAll(RegExp(r'0+$'), '');
    formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    return formatted;
  }

  // Calculator methods
  void _onCalculatorKey(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _calculatorInput = '';
          _solution = '';
          _steps = [];
          break;
        case '⌫':
          if (_calculatorInput.isNotEmpty) {
            _calculatorInput =
                _calculatorInput.substring(0, _calculatorInput.length - 1);
          }
          break;
        case '=':
          if (_calculatorInput.isNotEmpty) {
            _solveMathProblem(_calculatorInput);
          }
          break;
        case 'ANS':
          if (_lastAnswer.isNotEmpty) {
            _calculatorInput += _lastAnswer;
          }
          break;
        default:
          _calculatorInput += key;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.salmonDark : AppColors.salmon;
    final bgColor = isDark ? AppColors.backgroundDark : Colors.grey[50];

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: primaryColor.withValues(alpha: 0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PhotoMath',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Toggle results panel
          if (_solution.isNotEmpty)
            IconButton(
              icon: Icon(
                _isResultsExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isResultsExpanded = !_isResultsExpanded;
                });
              },
              tooltip:
                  _isResultsExpanded ? 'Collapse Results' : 'Expand Results',
            ),
          IconButton(
            icon: Icon(
              _showCalculator ? Icons.camera_alt : Icons.calculate,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showCalculator = !_showCalculator;
              });
            },
            tooltip:
                _showCalculator ? 'Switch to Camera' : 'Switch to Calculator',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Spacer for AppBar
            SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight),

            // Camera or Calculator view - takes more space when results collapsed
            Expanded(
              flex: _isResultsExpanded ? 3 : 5,
              child: _showCalculator ? _buildCalculator() : _buildCameraView(),
            ),

            // Results section - collapsible
            if (_isResultsExpanded && _solution.isNotEmpty)
              Expanded(
                flex: 4,
                child: _buildResultsSection(),
              )
            else if (_solution.isNotEmpty)
              // Collapsed results - just show solution summary
              _buildCollapsedResults(),
          ],
        ),
      ),
    );
  }

  // Collapsed results widget showing just the answer
  Widget _buildCollapsedResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.salmonDark : AppColors.salmon;
    final cardColor = isDark ? AppColors.cardDark : Colors.white;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isResultsExpanded = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.functions, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _solution,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.salmonDark : AppColors.salmon;

    if (!_isInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              const Text(
                'Initializing camera...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview - full width
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(20)),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _cameraController!.value.previewSize?.height ?? 1,
                height: _cameraController!.value.previewSize?.width ?? 1,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
        ),

        // Dark overlay outside crosshair to focus on capture area
        Positioned.fill(
          child: CustomPaint(
            painter: _CrosshairOverlayPainter(
              crosshairWidth:
                  MediaQuery.of(context).size.width * _crosshairWidth,
              crosshairHeight: _crosshairHeight,
            ),
          ),
        ),

        // Adjustable crosshair with resize handles
        Center(
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _crosshairHeight =
                    (_crosshairHeight + details.delta.dy).clamp(60.0, 200.0);
              });
            },
            child: Container(
              width: MediaQuery.of(context).size.width * _crosshairWidth,
              height: _crosshairHeight,
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Corner markers
                  Positioned(
                      top: 0, left: 0, child: _buildCornerMarker(primaryColor)),
                  Positioned(
                      top: 0,
                      right: 0,
                      child: _buildCornerMarker(primaryColor, flipX: true)),
                  Positioned(
                      bottom: 0,
                      left: 0,
                      child: _buildCornerMarker(primaryColor, flipY: true)),
                  Positioned(
                      bottom: 0,
                      right: 0,
                      child: _buildCornerMarker(primaryColor,
                          flipX: true, flipY: true)),

                  // Hint text
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Position math expression here',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // Resize hint at bottom
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Capture button
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _isProcessing ? null : _captureAndProcess,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _isProcessing
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(
                        Icons.camera,
                        color: Colors.white,
                        size: 35,
                      ),
              ),
            ),
          ),
        ),

        // Instructions
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Point camera at math problem',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a corner marker for the crosshair
  Widget _buildCornerMarker(Color color,
      {bool flipX = false, bool flipY = false}) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scale(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0),
      child: SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(
          painter: _CornerMarkerPainter(color: color),
        ),
      ),
    );
  }

  Widget _buildCalculator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : Colors.white;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _calculatorInput.isEmpty ? '0' : _calculatorInput,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_lastAnswer.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ans = $_lastAnswer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Scientific function row
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildScientificKey('sin'),
                _buildScientificKey('cos'),
                _buildScientificKey('tan'),
                _buildScientificKey('log'),
                _buildScientificKey('ln'),
                _buildScientificKey('√'),
                _buildScientificKey('π'),
                _buildScientificKey('e'),
                _buildScientificKey('abs'),
                _buildScientificKey('!'),
              ],
            ),
          ),

          // Keypad
          Expanded(
            child: GridView.count(
              crossAxisCount: 5,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.3,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildKey('C', isAction: true),
                _buildKey('('),
                _buildKey(')'),
                _buildKey('⌫', isAction: true),
                _buildKey('/'),
                _buildKey('7'),
                _buildKey('8'),
                _buildKey('9'),
                _buildKey('*'),
                _buildKey('^'),
                _buildKey('4'),
                _buildKey('5'),
                _buildKey('6'),
                _buildKey('-'),
                _buildKey('%'),
                _buildKey('1'),
                _buildKey('2'),
                _buildKey('3'),
                _buildKey('+'),
                _buildKey('Ans',
                    onTap: () => _onCalculatorKey(
                        _lastAnswer.isNotEmpty ? _lastAnswer : '0')),
                _buildKey('0'),
                _buildKey('.'),
                _buildKey('x'),
                _buildKey('=', isPrimary: true),
                _buildKey('±', onTap: _toggleSign),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String label,
      {bool isAction = false, bool isPrimary = false, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.salmonDark : AppColors.salmon;

    Color bgColor;
    Color textColor;

    if (isPrimary) {
      bgColor = primaryColor;
      textColor = Colors.white;
    } else if (isAction) {
      bgColor = isDark ? Colors.red.shade700 : Colors.red.shade100;
      textColor = isDark ? Colors.white : Colors.red.shade700;
    } else {
      bgColor = isDark ? AppColors.cardDark : Colors.white;
      textColor = isDark ? Colors.white : Colors.black87;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      child: InkWell(
        onTap: onTap ?? () => _onCalculatorKey(label),
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: label.length > 2 ? 14 : 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Scientific function key builder for the scrollable row
  Widget _buildScientificKey(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.salmonDark : AppColors.salmon;

    // Map display labels to actual function inputs
    String getInputValue() {
      switch (label) {
        case 'sin':
          return 'sin(';
        case 'cos':
          return 'cos(';
        case 'tan':
          return 'tan(';
        case 'log':
          return 'log(';
        case 'ln':
          return 'ln(';
        case '√':
          return 'sqrt(';
        case 'π':
          return '3.14159';
        case 'e':
          return '2.71828';
        case 'abs':
          return 'abs(';
        case '!':
          return '!';
        default:
          return label;
      }
    }

    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: Material(
        color: primaryColor.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _onCalculatorKey(getInputValue()),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Toggle sign of the current input (positive/negative)
  void _toggleSign() {
    if (_calculatorInput.isEmpty) return;

    setState(() {
      if (_calculatorInput.startsWith('-')) {
        _calculatorInput = _calculatorInput.substring(1);
      } else {
        _calculatorInput = '-$_calculatorInput';
      }
    });
  }

  Widget _buildResultsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.salmonDark : AppColors.salmon;
    final secondaryColor = isDark ? AppColors.mintDark : AppColors.mint;
    final cardColor = isDark ? AppColors.cardDark : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle - tap to collapse
          GestureDetector(
            onTap: () {
              setState(() {
                _isResultsExpanded = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recognized text
                  if (_recognizedText.isNotEmpty) ...[
                    Text(
                      'Detected Expression:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: secondaryColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: secondaryColor),
                      ),
                      child: Text(
                        _recognizedText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Solution
                  if (_solution.isNotEmpty) ...[
                    Text(
                      'Solution:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withAlpha(204)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _solution,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Steps
                  if (_steps.isNotEmpty) ...[
                    Text(
                      'Step-by-Step Solution:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._steps.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _getStepColor(
                                    entry.value.type, primaryColor),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value.explanation,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.value.expression,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          entry.value.type == StepType.result
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color: entry.value.type == StepType.result
                                          ? primaryColor
                                          : (isDark
                                              ? Colors.white
                                              : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // Empty state
                  if (_solution.isEmpty && _steps.isEmpty) ...[
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showCalculator
                                ? Icons.calculate
                                : Icons.camera_alt,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showCalculator
                                ? 'Enter a math expression\nand press = to solve'
                                : 'Point your camera at a\nmath problem to solve it',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '📚 Supported Problems:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• Basic: +, -, ×, ÷\n'
                                  '• Equations: 2x+5=15\n'
                                  '• Quadratic: x²+5x+6=0\n'
                                  '• Trig: sin(30), cos(60)\n'
                                  '• Calculus: derivative x^3\n'
                                  '• Integrals: integral x^2\n'
                                  '• Log: log(100), ln(10)\n'
                                  '• Powers: 2^8, sqrt(144)',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Compact action buttons just above navbar
          if (_solution.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text:
                                  '$_recognizedText\n$_solution\n\nSteps:\n${_stepsToString()}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  const Text('Solution copied to clipboard!'),
                              backgroundColor: primaryColor,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label:
                            const Text('Copy', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _recognizedText = '';
                            _solution = '';
                            _steps = [];
                            _calculatorInput = '';
                          });
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label:
                            const Text('New', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
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
}

/// Custom painter for the crosshair overlay with a transparent hole
class _CrosshairOverlayPainter extends CustomPainter {
  final double crosshairWidth;
  final double crosshairHeight;

  _CrosshairOverlayPainter({
    required this.crosshairWidth,
    required this.crosshairHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(128)
      ..style = PaintingStyle.fill;

    // Calculate crosshair rectangle position (centered)
    final crosshairLeft = (size.width - crosshairWidth) / 2;
    final crosshairTop = (size.height - crosshairHeight) / 2;
    final crosshairRect = Rect.fromLTWH(
      crosshairLeft,
      crosshairTop,
      crosshairWidth,
      crosshairHeight,
    );

    // Create path for the entire canvas
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Subtract the crosshair area to create a hole
    final holePath = Path()
      ..addRRect(
          RRect.fromRectAndRadius(crosshairRect, const Radius.circular(8)));

    // Combine paths to create overlay with hole
    final combinedPath = Path.combine(PathOperation.difference, path, holePath);

    canvas.drawPath(combinedPath, paint);

    // Draw border around the crosshair hole
    final borderPaint = Paint()
      ..color = Colors.white.withAlpha(204)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(crosshairRect, const Radius.circular(8)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrosshairOverlayPainter oldDelegate) {
    return crosshairWidth != oldDelegate.crosshairWidth ||
        crosshairHeight != oldDelegate.crosshairHeight;
  }
}

/// Custom painter for corner markers
class _CornerMarkerPainter extends CustomPainter {
  final Color color;

  _CornerMarkerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.6, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerMarkerPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
