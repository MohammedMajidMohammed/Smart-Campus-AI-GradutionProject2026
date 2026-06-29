import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/add_floating_action_button.dart';
import 'package:smart_canvas/features/administrator/schedule/view_models/cubit/add_subject_schedule_cubit.dart';
import 'package:smart_canvas/features/administrator/schedule/views/widgets/add_subject_schedule_bottom_sheet_body.dart';
import 'package:smart_canvas/features/administrator/schedule/view_models/cubit/schedules_cubit.dart';
import 'package:smart_canvas/features/administrator/schedule/views/widgets/schedules_screen_body.dart';

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SchedulesCubit(),
      child: Builder(builder: (context) {
        final cubit = context.read<SchedulesCubit>();
        return Scaffold(
          body: const SchedulesScreenBody(),
          floatingActionButton: AddFloatingActionButton(
            onPressed: () async {
              await showModalBottomSheet(
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                context: context,
                builder: (context) => BlocProvider(
                  create: (context) => AddSubjectScheduleCubit(),
                  child: const AddSubjectScheduleModalBottomSheetBody(),
                ),
              );
              // Auto Refresh after adding
              if (context.mounted) {
                cubit.getSchedules();
              }
            },
          ),
        );
      }),
    );
  }
}
