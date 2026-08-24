import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Símbolo da marca: documento com canto dobrado (marsala) e check (avelã),
/// em traço, redesenhado a partir do SVG de `DiaKit Logo.dc.html`.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 26, this.strokeWidth = 3});

  final double size;

  /// Espessura do traço na escala original de 56x56.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(
          document: c.accent,
          check: c.accent2,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({
    required this.document,
    required this.check,
    required this.strokeWidth,
  });

  final Color document;
  final Color check;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // O desenho original vive num viewBox de 56x56.
    final scale = size.width / 56;
    canvas.scale(scale);

    final documentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..color = document;

    // <rect x="14" y="6" width="28" height="36" rx="3" />
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(14, 6, 28, 36),
        const Radius.circular(3),
      ),
      documentPaint,
    );

    // <path d="M32 6v9h9" /> -- o canto dobrado.
    canvas.drawPath(
      Path()
        ..moveTo(32, 6)
        ..lineTo(32, 15)
        ..lineTo(41, 15),
      documentPaint,
    );

    // <path d="M20 30l5 5 11-13" /> -- o check, no accent 2.
    canvas.drawPath(
      Path()
        ..moveTo(20, 30)
        ..lineTo(25, 35)
        ..lineTo(36, 22),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = check,
    );
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) =>
      old.document != document ||
      old.check != check ||
      old.strokeWidth != strokeWidth;
}

/// Lockup horizontal: símbolo + wordmark. Usado no topo da sidebar desktop.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.markSize = 26, this.wordmarkSize = 20});

  final double markSize;
  final double wordmarkSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize),
        const SizedBox(width: 10),
        Text(
          'DiaKit',
          style: AppText.h6.copyWith(
            fontSize: wordmarkSize,
            color: context.c.text,
          ),
        ),
      ],
    );
  }
}
