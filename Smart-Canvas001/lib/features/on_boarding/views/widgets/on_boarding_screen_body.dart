import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/components/custom_elevated_button.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/on_boarding/view_models/cubit/on_boarding_cubit.dart';
import 'package:smart_canvas/features/on_boarding/views/widgets/custom_smoth_page_indecator.dart';
import 'package:smart_canvas/features/on_boarding/views/widgets/on_boarding_page_view_builder.dart';
import 'package:smart_canvas/features/splash/views/widgets/gradient_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnBoardingScreenBody extends StatelessWidget {
  const OnBoardingScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    // Calculate max width for tablet/desktop centering
    final maxContentWidth = SizeConfig.responsive<double>(
      mobile: double.infinity,
      tablet: 600,
      desktop: 700,
    );
    
    return BlocListener<OnBoardingCubit, int>(
      listener: (context, state) {
        if (state == AppConstants.onBoardingList.length) {
          context.pushScreen(RouteNames.signInScreen);
        }
      },
      child: GradientBody(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.responsive<double>(
                    mobile: SizeConfig.width * 0.05,
                    tablet: SizeConfig.width * 0.08,
                    desktop: SizeConfig.width * 0.1,
                  ),
                  vertical: SizeConfig.height * 0.02,
                ),
                child: Column(
                  children: [
                    const CustomSmoothPageIndecator(),
                    SizedBox(height: SizeConfig.height * 0.02),
                    const Expanded(child: OnBoardingPageViewBuilder()),
                    SizedBox(height: SizeConfig.height * 0.03),
                    const NextButton(),
                    SizedBox(height: SizeConfig.height * 0.01),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NextButton extends StatelessWidget {
  const NextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnBoardingCubit, int>(
      buildWhen: (previous, current) =>
          previous == AppConstants.onBoardingList.length - 1 ||
          current == AppConstants.onBoardingList.length - 1,
      builder: (context, state) {
        return CustomElevatedButton(
          name: state == AppConstants.onBoardingList.length - 1
              ? "Get Started"
              : "Next",
          backgroundColor: AppColors.kPrimaryColor,
          width: double.infinity,
          hPadding: SizeConfig.height * 0.02,
          onPressed: () {
            context.read<OnBoardingCubit>().nextPage();
          },
        );
      },
    );
  }
}
