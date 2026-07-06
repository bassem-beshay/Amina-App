import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';

/// Dashed-border upload placeholder (Figma "upload-box").
/// Tapping it triggers [onTap] (the screen wires an image picker).
/// Once a file is chosen, [fileName] is shown with a success check.
class UploadBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? fileName;
  final VoidCallback onTap;

  const UploadBox({
    super.key,
    this.icon = Icons.cloud_upload_outlined,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFile = fileName != null;
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: hasFile ? OnboardingTheme.primary : OnboardingTheme.primary.withOpacity(0.4),
          radius: OnboardingTheme.radiusCard,
        ),
        child: Container(
          height: 120,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasFile ? Icons.check_circle : icon,
                size: 28,
                color: OnboardingTheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: OnboardingTheme.inter(
                  size: 16,
                  weight: FontWeight.w600,
                  color: OnboardingTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasFile ? fileName! : subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OnboardingTheme.inter(size: 13, color: OnboardingTheme.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  static const double dashLength = 6;
  static const double gapLength = 5;

  _DashedRRectPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
