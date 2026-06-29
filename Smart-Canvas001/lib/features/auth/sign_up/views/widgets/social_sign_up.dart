import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_icon_button.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/auth/sign_up/view_models/cubit/sign_up_cubit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialSingUp extends StatelessWidget {
  const SocialSingUp({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CustomIconButton(
          iconSize: SizeConfig.width * 0.07,
          iconColor: Colors.white,
          backgroundColor: AppColors.kPrimaryColor,
          icon: FontAwesomeIcons.facebookF,
          onPressed: () {},
        ),
        BlocBuilder<SignUpCubit, SignUpState>(
          buildWhen: (previous, current) =>
              current is SignUpWithGoogleLoading ||
              previous is SignUpWithGoogleLoading,
          builder: (context, state) {
            return state is SignUpWithGoogleLoading
                ? const CustomCircularProgresIndecator()
                : CustomIconButton(
                    iconSize: SizeConfig.width * 0.07,
                    iconColor: Colors.white,
                    backgroundColor: AppColors.kPrimaryColor,
                    icon: FontAwesomeIcons.google,
                    onPressed: () {
                      context.read<SignUpCubit>().signUpWithGoogle();
                    },
                  );
          },
        ),
        CustomIconButton(
          iconSize: SizeConfig.width * 0.07,
          iconColor: Colors.white,
          backgroundColor: AppColors.kPrimaryColor,
          icon: Icons.apple,
          onPressed: () {},
        ),
      ],
    );
  }
}
