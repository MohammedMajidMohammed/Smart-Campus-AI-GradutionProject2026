import 'package:flutter/material.dart';
import 'package:smart_canvas/core/components/custom_text_button.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/auth/sign_in/view_models/cubit/sign_in_cubit.dart';

class FaceIdAndForgotPassword extends StatelessWidget {
  const FaceIdAndForgotPassword({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = EasyLocalization.of(context)?.currentLocale?.languageCode == 'ar';
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => context.read<SignInCubit>().signInWithFaceID(),
          icon: const Icon(
            Icons.face_retouching_natural,
            color: AppColors.kPrimaryColor,
            size: 20,
          ),
          label: Text(
            isArabic ? "بصمة الوجه" : "Face ID",
            style: AppTextStyles.title14PrimaryColor.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const Spacer(),
        CustomTextButton(
          title: "forgot_password".tr(),
          style: AppTextStyles.title14PrimaryColor,
        ),
      ],
    );
  }
}
