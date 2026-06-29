import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:smart_canvas/features/administrator/home/views/widgets/custom_bottom_nav_bar.dart';
import 'package:smart_canvas/features/admin/home/view_models/cubit/doctor_bottom_nav_bar_cubit.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoctorBottomNavBarCubit, int>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(child: AppConstants.doctorScreens[state]),
          bottomNavigationBar: CustomBottomNavBar(
            selectedIndex: state,
            taps: AppConstants.doctorTabs
                .map<GButton>(
                  (e) => GButton(
                    icon: e.icon,
                    text: e.title.tr(),
                    onPressed: () {
                      context.read<DoctorBottomNavBarCubit>().changeIndex(
                            e.index,
                          );
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
