import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Caixa com contorno tracejado — a dropzone da tela de conversão
/// (`border: 1.5px dashed var(--color-divider)`).
class DashedBox extends StatelessWidget {
  const DashedBox({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.borderRadius = AppRadius.lgAll,
    this.strokeWidth = 1.5,
    this.color,
    this.highlighted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final Color? color;

  /// Realça o contorno enquanto um arquivo é arrastado sobre a área (desktop).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return CustomPaint(
      painter: _DashedBorderPainter(
        color: highlighted ? c.accent : (color ?? c.divider),
        strokeWidth: strokeWidth,
        radius: borderRadius.topLeft,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          hoverColor: c.accent.withValues(alpha: 0.06),
          splashColor: c.accent.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final Radius radius;

  static const _dash = 6.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            strokeWidth / 2,
            strokeWidth / 2,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          radius,
        ),
      );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius;
}
