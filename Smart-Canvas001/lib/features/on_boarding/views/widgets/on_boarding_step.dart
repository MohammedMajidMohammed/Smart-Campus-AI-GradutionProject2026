import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/on_boarding/models/on_boarding_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

class OnBoardingStep extends StatelessWidget {
  const OnBoardingStep({super.key, required this.onBoardingStepModel});

  final OnBoardingStepModel onBoardingStepModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: SizeConfig.height * 0.01),
        Text(
          onBoardingStepModel.title,
          style: AppTextStyles.title28PrimaryColorW500,
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 600.ms, delay: 200.ms).move(
            begin: const Offset(0, 15),
            end: Offset.zero,
            curve: Curves.easeOut),
        SizedBox(height: SizeConfig.height * 0.01),
        Expanded(
          flex: 4,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageHeight = constraints.maxHeight * 0.8;
              return Center(
                child: Lottie.asset(
                  onBoardingStepModel.image,
                  height: imageHeight,
                  fit: BoxFit.contain,
                  delegates: LottieDelegates(
                    values: [
                      ValueDelegate.colorFilter(
                        const ['**'],
                        value: const ColorFilter.mode(
                          AppColors.kPrimaryColor,
                          BlendMode.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: SizeConfig.height * 0.02),
        Text(
          onBoardingStepModel.subTitle,
          style: AppTextStyles.title18Grey.copyWith(height: 1.4),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 700.ms, delay: 350.ms).move(
            begin: const Offset(0, 15),
            end: Offset.zero,
            curve: Curves.easeOut),
        SizedBox(height: SizeConfig.height * 0.02),
      ],
    );
  }
}
