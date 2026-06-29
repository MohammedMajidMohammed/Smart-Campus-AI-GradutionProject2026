import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:smart_canvas/features/administrator/home/view_models/cubit/administrator_bottom_nav_bar_cubit.dart';
import 'package:smart_canvas/features/administrator/home/views/widgets/custom_bottom_nav_bar.dart';

class AdministratorHomeScreen extends StatelessWidget {
  const AdministratorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdministratorBottomNavBarCubit, int>(
      builder: (context, state) {
        return Scaffold(
          body: AppConstants.administratorScreens[state],
          bottomNavigationBar: CustomBottomNavBar(
            selectedIndex: state,
            taps: AppConstants.administratorTabs
                .map<GButton>(
                  (e) => GButton(
                    icon: e.icon,
                    text: e.title.tr(),
                    onPressed: () {
                      context.read<AdministratorBottomNavBarCubit>().changeIndex(
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
