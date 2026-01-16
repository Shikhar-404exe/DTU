

library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

class PieChartData {
  final String label;
  final double value;
  final Color color;

  const PieChartData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class PieChartWidget extends StatelessWidget {
  final List<PieChartData> data;
  final double size;
  final bool showLegend;

  const PieChartWidget({
    super.key,
    required this.data,
    this.size = 200,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    if (total == 0) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _PieChartPainter(data: data, total: total),
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 70),
            child: SingleChildScrollView(
              child: _buildLegend(total),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegend(double total) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: data.map((item) {
        final percentage = (item.value / total * 100).toStringAsFixed(1);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${item.label}: $percentage%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: item.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<PieChartData> data;
  final double total;

  _PieChartPainter({required this.data, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double startAngle = -math.pi / 2;

    for (final item in data) {
      final sweepAngle = (item.value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DonutChartWidget extends StatelessWidget {
  final List<PieChartData> data;
  final double size;
  final bool showLegend;
  final Widget? centerWidget;

  const DonutChartWidget({
    super.key,
    required this.data,
    this.size = 200,
    this.showLegend = true,
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    if (total == 0) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _DonutChartPainter(data: data, total: total),
              ),
            ),
            if (centerWidget != null) centerWidget!,
          ],
        ),
        if (showLegend) ...[
          const SizedBox(height: 16),
          _buildLegend(total),
        ],
      ],
    );
  }

  Widget _buildLegend(double total) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: data.map((item) {
        final percentage = (item.value / total * 100).toStringAsFixed(1);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${item.label} ($percentage%)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<PieChartData> data;
  final double total;

  _DonutChartPainter({required this.data, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final innerRadius = radius * 0.6;

    double startAngle = -math.pi / 2;

    for (final item in data) {
      final sweepAngle = (item.value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      final path = Path();

      path.addArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
      );

      final endAngle = startAngle + sweepAngle;
      path.lineTo(
        center.dx + innerRadius * math.cos(endAngle),
        center.dy + innerRadius * math.sin(endAngle),
      );

      path.addArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        endAngle,
        -sweepAngle,
      );

      path.close();

      canvas.drawPath(path, paint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawPath(path, borderPaint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
