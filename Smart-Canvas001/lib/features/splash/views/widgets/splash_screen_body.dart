import 'package:smart_canvas/core/utilies/assets/images/app_images.dart';
import 'package:smart_canvas/features/splash/views/widgets/gradient_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreenBody extends StatelessWidget {
  const SplashScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GradientBody(
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Centered Main Content
            Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Premium Glassmorphic Badge for Logo
                      Container(
                        padding: EdgeInsets.all(width * 0.05),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF1E8449).withValues(alpha: 0.4), // Golden border
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E8449).withValues(alpha: 0.25),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          AppImages.logoWithoutBackgroundImage,
                          width: width * 0.45,
                          height: width * 0.45,
                          fit: BoxFit.contain,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                      .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          duration: 800.ms,
                          curve: Curves.easeOutBack),

                      SizedBox(height: height * 0.04),

                      // University Name Arabic
                      Text(
                        "جامعة المنوفية الأهلية",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: width * 0.065,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF2E240C),
                          letterSpacing: 0,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),

                      SizedBox(height: height * 0.012),

                      // University Name English
                      Text(
                        "MENOUFIA NATIONAL UNIVERSITY",
                        style: TextStyle(
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E8449), // Brand Gold
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Loading/Progress Indicator & Footer
            Positioned(
              bottom: height * 0.08,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Elegant thin progress indicator
                  SizedBox(
                    width: width * 0.4,
                    height: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E8449)),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 400.ms),

                  SizedBox(height: height * 0.02),

                  // Subtitle
                  Text(
                    "Smart Campus",
                    style: TextStyle(
                      fontSize: width * 0.035,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white30 : Colors.grey.shade400,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 500.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

