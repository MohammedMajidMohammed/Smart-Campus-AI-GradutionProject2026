import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';

class AnimatedDot extends StatefulWidget {
  final int delay;
  const AnimatedDot({super.key, this.delay = 0});

  @override
  State<AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.delay > 0) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: SizeConfig.width * 0.01,
        height: SizeConfig.width * 0.01,
        decoration: BoxDecoration(
          color: isDark ? Colors.white70 : Colors.black87,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}