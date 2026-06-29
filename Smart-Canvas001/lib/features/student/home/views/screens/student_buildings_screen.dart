import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/administrator/buildings/view_models/cubit/buildings_cubit.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/buildings_screen_body.dart';
import 'package:easy_localization/easy_localization.dart';

class StudentBuildingsScreen extends StatelessWidget {
  const StudentBuildingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BuildingsCubit(),
      child: BuildingsScreenBody(title: "building_locations".tr(), canEdit: false),
    );
  }
}
