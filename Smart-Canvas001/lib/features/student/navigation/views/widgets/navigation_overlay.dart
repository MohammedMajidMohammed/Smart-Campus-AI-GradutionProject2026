import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/student/navigation/view_models/cubit/navigation_cubit.dart';
import 'package:easy_localization/easy_localization.dart';

class NavigationOverlay extends StatelessWidget {
  const NavigationOverlay({super.key, required this.onStop});
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        if (state is! NavigationActive) return const SizedBox.shrink();

        return Positioned(
          top: 50,
          left: 76,
          right: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _buildVoiceIndicator(state.isSpeaking),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "smart_assistant".tr(),
                            style: const TextStyle(
                              color: AppColors.kPrimaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onStop,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.red, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.instruction,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (state.isSpeaking) ...[ 
                      const SizedBox(height: 16),
                      // Animated Voice Waveform (Simplified visual)
                      SizedBox(
                        height: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return _AnimatedBar(index: index);
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceIndicator(bool isSpeaking) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSpeaking ? AppColors.kPrimaryColor : Colors.grey[200],
        shape: BoxShape.circle,
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: AppColors.kPrimaryColor.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Icon(
        isSpeaking ? Icons.mic : Icons.mic_none,
        color: isSpeaking ? Colors.white : Colors.grey,
        size: 20,
      ),
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  final int index;
  const _AnimatedBar({required this.index});

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (widget.index * 100)),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 2.0, end: 15.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 4,
          height: _animation.value,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
