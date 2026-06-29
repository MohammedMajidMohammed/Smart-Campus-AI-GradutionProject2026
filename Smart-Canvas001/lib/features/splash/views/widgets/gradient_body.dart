import 'package:flutter/material.dart';

class GradientBody extends StatelessWidget {
  const GradientBody({super.key, required this.child, this.xStop=0.001, this.yStop=.23});
  final Widget child;
  final double? xStop;
  final double? yStop;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Premium theme colors for backgrounds
    final primaryBg = isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F6); // Dark Slate vs Light Ivory
    final secondaryBg = isDark ? const Color(0xFF1E1B10) : const Color(0xFFF5EFE0); // Deep Dark Gold Tint vs Warm Ivory
    final goldGlow = isDark ? const Color(0xFF27AE60) : const Color(0xFFFFECC0); // Gold Glow
    final secondaryGlow = isDark ? const Color(0xFF145A32) : const Color(0xFFD5F5E3); // Deep Gold Glow

    return Scaffold(
      body: Stack(
        children: [
          // Background base gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBg, secondaryBg],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
          
          // Soft golden radial flare in the top right
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    goldGlow.withValues(alpha: isDark ? 0.08 : 0.4),
                    goldGlow.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          
          // Soft green radial flare in the bottom left
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    secondaryGlow.withValues(alpha: isDark ? 0.06 : 0.3),
                    secondaryGlow.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          
          // Subtle grid pattern overlay for that "Canvas" university look
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: CustomPaint(
                painter: GridPainter(isDark),
              ),
            ),
          ),

          // Content
          child,
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final bool isDark;
  GridPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.015)
      ..strokeWidth = 0.8;

    const double step = 30.0;

    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
