import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/on_boarding/view_models/cubit/on_boarding_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CustomSmoothPageIndecator extends StatelessWidget {
  const CustomSmoothPageIndecator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: SizeConfig.width * 0.5),
      child: SmoothPageIndicator(
        controller: context.read<OnBoardingCubit>().pageController,
        count: AppConstants.onBoardingList.length,
        effect: SwapEffect(
          spacing: SizeConfig.width * 0.02,
          dotHeight: SizeConfig.height * 0.01,
          dotWidth: SizeConfig.height * 0.07,
          dotColor: Colors.grey[300]!,
          activeDotColor: AppColors.kPrimaryColor,
        ),
      ),
    );
  }
}
