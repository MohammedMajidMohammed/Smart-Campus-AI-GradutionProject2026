import 'package:smart_canvas/core/components/custom_professional_dialog.dart';
import 'package:smart_canvas/core/components/glass_box.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_circular_progress_indecator.dart';
import 'package:smart_canvas/core/utilies/assets/images/app_images.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/auth/sign_in/view_models/cubit/sign_in_cubit.dart';
import 'package:smart_canvas/features/auth/sign_in/views/widgets/remember_me.dart';
import 'package:smart_canvas/features/auth/sign_in/views/widgets/sign_in_form.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

class SignInScreenBody extends StatelessWidget {
  const SignInScreenBody({super.key});

  static const Color primary = AppColors.kPrimaryColor;

  Future<void> _launchMaps() async {
    final Uri url = Uri.parse("https://maps.app.goo.gl/xKbdX2yw1j4cZkE36");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(url);
      } catch (_) {}
    }
  }

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse("https://mnu.menofia.education/");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(url);
      } catch (_) {}
    }
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.black.withValues(alpha: 0.4) 
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.kPrimaryColor, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by parent
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.w(6)),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      // Glass Form
                      Padding(
                        padding: EdgeInsets.only(top: SizeConfig.w(13)),
                        child: GlassBox(
                          borderRadius: 30,
                          blur: 25,
                          borderOpacity: isDark ? 0.12 : 0.3,
                          color: isDark 
                              ? Colors.black.withValues(alpha: 0.3) 
                              : Colors.white.withValues(alpha: 0.8),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: SizeConfig.w(6),
                              right: SizeConfig.w(6),
                              top: SizeConfig.w(15),
                              bottom: SizeConfig.h(4),
                            ),
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: isDark 
                                        ? [const Color(0xFFC8E6C9), const Color(0xFF4CAF50)]
                                        : [const Color(0xFF145A32), const Color(0xFF1E8449)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: Text(
                                    "welcome_back".tr(),
                                    style: TextStyle(
                                      fontSize: SizeConfig.fontSize(28),
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "sign_in_continue".tr(),
                                  style: TextStyle(
                                      fontSize: SizeConfig.fontSize(14),
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 25),

                                // Form + Listener
                                BlocListener<SignInCubit, SignInState>(
                                  listener: (context, state) {
                                    String? route;
                                    if (state is SignInSuccess) {
                                      route = state.route;
                                    }
                                    if (route != null) {
                                      context.pushAndRemoveUntilScreen(route);
                                      CustomProfessionalDialog.showSuccess(
                                        context,
                                        title: EasyLocalization.of(context)?.currentLocale?.languageCode == 'ar' ? 'مرحباً!' : 'Welcome!',
                                        message: EasyLocalization.of(context)?.currentLocale?.languageCode == 'ar' ? 'تم تسجيل الدخول بنجاح' : 'Signed in successfully',
                                      );
                                      return;
                                    }
                                    if (state is SignInFailure) {
                                      CustomProfessionalDialog.showError(
                                        context,
                                        title: EasyLocalization.of(context)?.currentLocale?.languageCode == 'ar' ? 'خطأ' : 'Error',
                                        message: state.message,
                                      );
                                    }
                                  },
                                  child: const SignInForm(),
                                ),

                                const FaceIdAndForgotPassword(),
                                SizedBox(height: SizeConfig.h(3.5)),

                                // Login Button
                                BlocBuilder<SignInCubit, SignInState>(
                                  buildWhen: (p, c) =>
                                      c is SignInLoading || p is SignInLoading,
                                  builder: (context, state) {
                                    return state is SignInLoading
                                        ? const CustomCircularProgresIndecator()
                                        : Container(
                                            width: double.infinity,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(28),
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF1E8449), Color(0xFF2E9B58)],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF1E8449).withValues(alpha: 0.35),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: () => context.read<SignInCubit>().signIn(),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(28),
                                                ),
                                              ),
                                              child: Text(
                                                "sign_in".tr(),
                                                style: TextStyle(
                                                  fontSize: SizeConfig.fontSize(16),
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          );
                                  },
                                ),

                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Overlapping Logo on the top border
                      Positioned(
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.kSecondaryColor, AppColors.kPrimaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.kPrimaryColor.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.asset(
                                AppImages.logoWithoutBackgroundImage,
                                width: SizeConfig.w(22),
                                height: SizeConfig.w(22),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  // Bottom Actions (Website & Location)
                  Row(
                    children: [
                      Expanded(
                        child: _buildBottomAction(
                          icon: Icons.location_on_outlined,
                          title: EasyLocalization.of(context)?.currentLocale?.languageCode == 'ar'
                              ? "الموقع"
                              : "Location",
                          isDark: isDark,
                          onTap: _launchMaps,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildBottomAction(
                          icon: Icons.public,
                          title: EasyLocalization.of(context)?.currentLocale?.languageCode == 'ar'
                              ? "الموقع الإلكتروني"
                              : "Website",
                          isDark: isDark,
                          onTap: _launchWebsite,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
