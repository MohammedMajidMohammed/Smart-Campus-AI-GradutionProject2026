import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key, required this.taps});
  final List<GButton> taps ;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: SizeConfig.width * 0.01,
        vertical: SizeConfig.height * 0.005,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.width * 0.03,
        vertical: SizeConfig.height * 0.015,
      ),
      decoration: BoxDecoration(
        color: AppColors.kPrimaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: GNav(
        haptic: true,
        gap: SizeConfig.width * 0.02,
        iconSize: SizeConfig.width * 0.06,
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.width * 0.05,
          vertical: SizeConfig.height * 0.01,
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        color: Colors.white70,
        activeColor: AppColors.kPrimaryColor,
        tabBackgroundColor: Colors.white,
        tabBorderRadius: SizeConfig.width * 0.04,
        tabs: taps,
      ),
    );
  }
}
