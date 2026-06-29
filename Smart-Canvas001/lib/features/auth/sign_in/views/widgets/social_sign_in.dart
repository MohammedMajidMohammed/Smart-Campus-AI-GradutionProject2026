import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_icon_button.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/auth/sign_in/view_models/cubit/sign_in_cubit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialSignIn extends StatelessWidget {
  const SocialSignIn({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CustomIconButton(
          hPadding: SizeConfig.width * 0.04,
          vPadding: SizeConfig.height * 0.02,
          iconSize: SizeConfig.width * 0.07,
          backgroundColor: AppColors.kPrimaryColor,
          iconColor: Colors.white,
          icon: FontAwesomeIcons.facebookF,
          onPressed: () {},
        ),
        BlocBuilder<SignInCubit, SignInState>(
          buildWhen: (previous, current) =>
              current is SignInWithGoogleLoading ||
              previous is SignInWithGoogleLoading,
          builder: (context, state) {
            return state is SignInWithGoogleLoading
                ? const CustomCircularProgresIndecator()
                : CustomIconButton(
                    hPadding: SizeConfig.width * 0.04,
                    vPadding: SizeConfig.height * 0.02,
                    iconSize: SizeConfig.width * 0.07,
                    backgroundColor: AppColors.kPrimaryColor,
                    iconColor: Colors.white,
                    icon: FontAwesomeIcons.google,
                    onPressed: () {
                      context.read<SignInCubit>().signInWithGoogle();
                    },
                  );
          },
        ),
        CustomIconButton(
          hPadding: SizeConfig.width * 0.04,
          vPadding: SizeConfig.height * 0.02,
          iconSize: SizeConfig.width * 0.07,
          backgroundColor: AppColors.kPrimaryColor,
          iconColor: Colors.white,
          icon: Icons.apple,
          onPressed: () {},
        ),
      ],
    );
  }
}
