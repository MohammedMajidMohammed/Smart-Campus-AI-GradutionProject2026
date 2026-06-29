import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/add_floating_action_button.dart';
import 'package:smart_canvas/features/admin/subjects/view_models/cubit/add_subject_cubit.dart';
import 'package:smart_canvas/features/admin/subjects/views/widgets/add_subject_modal_bottom_sheet_body.dart';
import 'package:smart_canvas/features/admin/subjects/views/widgets/subjects_screen_body.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SubjectsScreenBody(),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            context: context,
            builder: (context) => BlocProvider(
              create: (context) => AddSubjectCubit(),
              child: const AddSubjectModalBottomSheetBody(),
            ),
          );
        },
      ),
    );
  }
}
