import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animated card wrapper with tap scale and fade effects
class AnimatedCard extends StatefulWidget {
  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.delay = Duration.zero,
    this.enableHover = true,
    this.enableTapScale = true,
    this.slideDirection = SlideDirection.fromBottom,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Duration delay;
  final bool enableHover;
  final bool enableTapScale;
  final SlideDirection slideDirection;

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

enum SlideDirection { fromBottom, fromLeft, fromRight, fromTop, none }

class _AnimatedCardState extends State<AnimatedCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  Offset get _slideOffset {
    switch (widget.slideDirection) {
      case SlideDirection.fromBottom:
        return const Offset(0, 30);
      case SlideDirection.fromTop:
        return const Offset(0, -30);
      case SlideDirection.fromLeft:
        return const Offset(-30, 0);
      case SlideDirection.fromRight:
        return const Offset(30, 0);
      case SlideDirection.none:
        return Offset.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.enableHover ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.enableHover ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTapDown: widget.enableTapScale 
            ? (_) => setState(() => _isPressed = true) 
            : null,
        onTapUp: widget.enableTapScale 
            ? (_) => setState(() => _isPressed = false) 
            : null,
        onTapCancel: widget.enableTapScale 
            ? () => setState(() => _isPressed = false) 
            : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: widget.child
              .animate(delay: widget.delay)
              .fadeIn(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              )
              .move(
                begin: _slideOffset,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              ),
        ),
      ),
    );
  }
}

/// Staggered list animation helper
class StaggeredListItem extends StatelessWidget {
  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 50),
  });

  final int index;
  final Widget child;
  final Duration baseDelay;

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      delay: Duration(milliseconds: baseDelay.inMilliseconds * index),
      slideDirection: SlideDirection.fromBottom,
      enableTapScale: false,
      child: child,
    );
  }
}

/// Page transition wrapper for route animations
class AnimatedPageWrapper extends StatelessWidget {
  const AnimatedPageWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideX(
          begin: 0.02,
          end: 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
  }
}
