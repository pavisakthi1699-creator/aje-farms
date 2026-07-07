import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';

/// Stylized crop-row mark for AJE Farms — furrows with a central sprout.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 48,
    this.color,
    this.backgroundColor,
  });

  final double size;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final markColor = color ?? context.colors.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(
          color: markColor,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter({
    required this.color,
    this.backgroundColor,
  });

  final Color color;
  final Color? backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundColor != null) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2,
        Paint()..color = backgroundColor!,
      );
    }

    final rowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.38 + i * 0.18);
      final path = Path()
        ..moveTo(size.width * 0.12, y)
        ..quadraticBezierTo(
          size.width * 0.5,
          y - size.height * 0.06,
          size.width * 0.88,
          y,
        );
      canvas.drawPath(path, rowPaint);
    }

    final stemPaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.5;
    final baseY = size.height * 0.72;
    canvas.drawLine(Offset(cx, baseY), Offset(cx, size.height * 0.28), stemPaint);

    final leafPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.14, size.height * 0.34),
        width: size.width * 0.22,
        height: size.height * 0.14,
      ),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + size.width * 0.14, size.height * 0.3),
        width: size.width * 0.22,
        height: size.height * 0.14,
      ),
      leafPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
