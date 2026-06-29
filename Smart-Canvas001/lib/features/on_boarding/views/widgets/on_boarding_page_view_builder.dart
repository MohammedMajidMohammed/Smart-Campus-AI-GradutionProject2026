import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:smart_canvas/features/on_boarding/view_models/cubit/on_boarding_cubit.dart';
import 'package:smart_canvas/features/on_boarding/views/widgets/on_boarding_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnBoardingPageViewBuilder extends StatelessWidget {
  const OnBoardingPageViewBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    var list = AppConstants.onBoardingList;
    return BlocBuilder<OnBoardingCubit, int>(
      builder: (context, state) {
        return PageView.builder(
          controller: context.read<OnBoardingCubit>().pageController,
          itemCount: list.length,
          onPageChanged: (index) =>
              context.read<OnBoardingCubit>().onPageChanged(index),
          itemBuilder: (context, index) =>
              OnBoardingStep(onBoardingStepModel: list[index]),
        );
      },
    );
  }
}
