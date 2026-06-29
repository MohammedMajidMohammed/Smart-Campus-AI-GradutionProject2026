import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/administrator/buildings/view_models/cubit/buildings_cubit.dart';
import 'package:smart_canvas/features/administrator/buildings/view_models/cubit/add_building_cubit.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/add_floating_action_button.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/add_building_modal_bottom_sheet_body.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/buildings_screen_body.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';

class BuildingsScreen extends StatelessWidget {
  const BuildingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = getIt<CacheHelper>().getUserModel();
    final String roleName = (user?.roleName ?? '').toLowerCase();
    // Simplify: Allow editing by default on management screens unless explicitly restricted
    final bool isAdmin = roleName != 'student' && roleName != 'professor';

    return Scaffold(
      body: BuildingsScreenBody(canEdit: isAdmin),
      floatingActionButton: isAdmin ? AddFloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (context) => BlocProvider(
                    create: (context) => AddBuildingCubit(),
                    child: const AddBuildingModalBottomSheetBody(),
                  ),
                ).then((value) {
                  if (context.mounted) {
                    context.read<BuildingsCubit>().getBuildings();
                  }
                });
              },
      ) : null,
    );
  }
}
