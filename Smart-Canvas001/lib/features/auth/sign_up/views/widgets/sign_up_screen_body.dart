import 'package:smart_canvas/core/components/custom_professional_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/auth/sign_in/views/widgets/have_account_or_not.dart';
import 'package:smart_canvas/features/auth/sign_in/views/widgets/or_sign_with.dart';
import 'package:smart_canvas/features/auth/sign_up/view_models/cubit/sign_up_cubit.dart';
import 'package:smart_canvas/features/auth/sign_up/views/widgets/pick_image.dart';
import 'package:smart_canvas/features/auth/sign_up/views/widgets/sign_up_form.dart';
import 'package:smart_canvas/features/auth/sign_up/views/widgets/social_sign_up.dart';

class SignUpScreenBody extends StatelessWidget {
  const SignUpScreenBody({super.key});

  static const Color primary = AppColors.kPrimaryColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF031A0C) : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // الخلفية الزرقاء المنحنية
            Container(
              height: SizeConfig.h(38),
              decoration: const BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                  bottomRight: Radius.circular(80),
                ),
              ),
            ),

            // كل المحتوى داخل السكرول (بما فيه الصورة)
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // مسافة من فوق عشان الصورة تطلع فوق المنحنى
                  SizedBox(height: SizeConfig.h(5)),

                  // صورة المستخدم (بتطلع فوق الكارت وداخل السكرول)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF031A0C) : Colors.white,
                        border: Border.all(color: isDark ? const Color(0xFF031A0C) : Colors.white, width: 6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const PickImage(), // حجمك الأصلي
                    ),
                  ),

                  SizedBox(height: SizeConfig.h(4)),

                  // الكارت الأبيض
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: SizeConfig.w(8),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      SizeConfig.w(6),
                      SizeConfig.h(4), // قللتها من 0.10 لـ 0.04
                      SizeConfig.w(6),
                      SizeConfig.h(5),
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0C2E17) : Colors.white,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 40,
                          offset: const Offset(0, -12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // العنوان
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: SizeConfig.fontSize(28),
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Fill your details to get started",
                          style: TextStyle(
                            fontSize: SizeConfig.fontSize(15),
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: SizeConfig.h(4)),

                        // الفورم + BlocListener
                        BlocListener<SignUpCubit, SignUpState>(
                          listener: (context, state) {
                            if (state is SignUpSuccess ||
                                state is SignUpWithGoogleSuccess) {
                              context.popScreen();
                              CustomProfessionalDialog.showSuccess(
                                context,
                                title: 'Welcome!',
                                message: 'Account created successfully!',
                              );
                            } else if (state is SignUpFailure) {
                              CustomProfessionalDialog.showError(
                                context,
                                title: 'Error',
                                message: state.errorMessage,
                              );
                            } else if (state is PickImageFailure) {
                              CustomProfessionalDialog.showSuccess(
                                context,
                                title: 'Info',
                                message: state.errorMessage,
                              );
                            } else if (state is GetCollegesFailure) {
                              CustomProfessionalDialog.showError(
                                context,
                                title: 'Error',
                                message: state.errorMessage,
                              );
                            }
                          },
                          child: const SignUpForm(),
                        ),

                        SizedBox(height: SizeConfig.h(3.5)),

                        // زر Sign Up
                        BlocBuilder<SignUpCubit, SignUpState>(
                          buildWhen: (p, c) =>
                              c is SignUpLoading ||
                              c is SignUpSuccess ||
                              c is SignUpFailure,
                          builder: (context, state) {
                            return state is SignUpLoading
                                ? const CustomCircularProgresIndecator()
                                : SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          context.read<SignUpCubit>().signUp(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                        ),
                                        elevation: 8,
                                        shadowColor: primary.withValues(alpha: 0.4),
                                      ),
                                      child: Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          fontSize: SizeConfig.fontSize(17),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                          },
                        ),

                        const OrSignWith(),
                        const SocialSingUp(),

                        SizedBox(height: SizeConfig.h(3)),

                        HaveAccountOrNot(
                          title: "Already have an account? ",
                          value: "Sign In",
                          onPressed: () => context.popScreen(),
                        ),

                        SizedBox(
                          height: SizeConfig.h(3),
                        ), // للـ safe area من تحت
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
