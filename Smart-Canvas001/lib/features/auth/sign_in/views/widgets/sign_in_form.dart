

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_text_form_field_with_title.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/features/auth/sign_in/view_models/cubit/sign_in_cubit.dart';

class SignInForm extends StatelessWidget {
  const SignInForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<SignInCubit>();
    return Form(
      key: cubit.formKey,
      child: Column(
        children: [
          CustomTextFormFieldWithTitle(
            title: EasyLocalization.of(context)?.currentLocale?.languageCode == 'ar'
                ? "الرقم الجامعي أو البريد الإلكتروني"
                : "ID or Email",
            hintText: EasyLocalization.of(context)?.currentLocale?.languageCode == 'ar'
                ? "أدخل الرقم الجامعي أو البريد الإلكتروني"
                : "Enter ID or email",
            prefixIcon: CupertinoIcons.person,
            controller: cubit.emailController,
          ),
          SizedBox(height: SizeConfig.height * 0.01),
          CustomTextFormFieldWithTitle(
            title: "password".tr(),
            hintText: "enter password".tr(),
            controller: cubit.passwordController,
            prefixIcon: CupertinoIcons.padlock,
            isPassword: true,
          ),
          SizedBox(height: SizeConfig.height * 0.01),
        ],
      ),
    );
  }
}
