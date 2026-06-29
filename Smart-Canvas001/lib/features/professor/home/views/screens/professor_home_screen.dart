import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:smart_canvas/features/administrator/home/views/widgets/custom_bottom_nav_bar.dart';
import 'package:smart_canvas/features/professor/home/view_models/cubit/professor_bottom_nav_bar_cubit.dart';

class ProfessorHomeScreen extends StatelessWidget {
  const ProfessorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfessorBottomNavBarCubit, int>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(child: AppConstants.professorScreens[state]),
          bottomNavigationBar: CustomBottomNavBar(
            selectedIndex: state,
            taps: AppConstants.professorTabs
                .map<GButton>(
                  (e) => GButton(
                    icon: e.icon,
                    text: e.title.tr(),
                    onPressed: () {
                      context.read<ProfessorBottomNavBarCubit>().changeIndex(e.index);
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
