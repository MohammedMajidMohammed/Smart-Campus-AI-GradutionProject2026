import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/features/administrator/home/views/widgets/custom_bottom_nav_bar.dart';
import 'package:smart_canvas/features/student/home/view_models/cubit/student_bottom_nav_bar_cubit.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentBottomNavBarCubit, int>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(child: AppConstants.studentScreens[state]),
          bottomNavigationBar: CustomBottomNavBar(
            selectedIndex: state,
            taps: AppConstants.studentTabs
                .map<GButton>(
                  (e) => GButton(
                    icon: e.icon,
                    text: e.title.tr(),
                    onPressed: () {
                      context.read<StudentBottomNavBarCubit>().changeIndex(e.index);
                    },
                  ),
                )
                .toList(),
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E8449).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                context.pushScreen(RouteNames.chatbotsScreen);
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              highlightElevation: 0,
              shape: const CircleBorder(),
              child: const Icon(LineIcons.robot, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }
}
