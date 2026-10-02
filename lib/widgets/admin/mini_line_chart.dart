import 'package:flutter/material.dart';

/// Лёгкий линейный график для admin-карточек (без внешних зависимостей).
class MiniLineChart extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;
  const MiniLineChart({super.key, required this.values, required this.color, this.height = 86});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('Нет данных для графика', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color.withOpacity(0.5))),
        ),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _MiniLineChartPainter(values: values, color: color)),
    );
  }
}

class _MiniLineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _MiniLineChartPainter({required this.values, required this.color});

  Offset _pointAt(int i, Size size, double minV, double range, double stepX) {
    final x = values.length > 1 ? stepX * i : size.width / 2;
    final normalized = (values[i] - minV) / range;
    final y = size.height - normalized * size.height * 0.82 - size.height * 0.09;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);
    final stepX = values.length > 1 ? size.width / (values.length - 1) : size.width;

    final linePath = Path();
    for (var i = 0; i < values.length; i++) {
      final p = _pointAt(i, size, minV, range, stepX);
      if (i == 0) {
        linePath.moveTo(p.dx, p.dy);
      } else {
        linePath.lineTo(p.dx, p.dy);
      }
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.20), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final lastPoint = _pointAt(values.length - 1, size, minV, range, stepX);
    canvas.drawCircle(lastPoint, 6, Paint()..color = color.withOpacity(0.16));
    canvas.drawCircle(lastPoint, 3.4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MiniLineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
