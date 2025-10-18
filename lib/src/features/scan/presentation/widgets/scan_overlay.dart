import 'package:flutter/material.dart';

class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _OverlayPainter(Theme.of(context).colorScheme),
        size: Size.infinite,
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final ColorScheme scheme;
  _OverlayPainter(this.scheme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = scheme.primary;

    final width = size.width;
    final height = size.height;
    final boxW = width * 0.72;
    final boxH = boxW * 0.5;
    final rect = Rect.fromCenter(
      center: Offset(width / 2, height * 0.42),
      width: boxW,
      height: boxH,
    );

    // Outer rounded rect
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    canvas.drawRRect(rrect, paint);

    // Corner accents
    final len = 22.0;
    final sw = 6.0;
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..color = scheme.primary;
    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(len, 0), accent);
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(0, len), accent);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight.translate(-len, 0), accent);
    canvas.drawLine(rect.topRight, rect.topRight.translate(0, len), accent);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(len, 0), accent);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(0, -len), accent);
    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(-len, 0), accent);
    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(0, -len), accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
