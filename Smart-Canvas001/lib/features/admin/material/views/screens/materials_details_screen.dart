import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/admin/material/view_models/cubit/materials_cubit.dart';
import 'package:smart_canvas/features/admin/material/view_models/cubit/add_material_cubit.dart';
import 'package:smart_canvas/features/admin/material/views/widgets/subject_details_header.dart';
import 'package:smart_canvas/features/admin/material/views/widgets/doctor_material_list_view.dart';
import 'package:smart_canvas/features/admin/material/views/widgets/add_material_modal_bottom_sheet_body.dart';
import 'package:smart_canvas/features/admin/subjects/models/subject_model.dart';

class MaterialsDetailsScreen extends StatelessWidget {
  final SubjectModel subject;
  const MaterialsDetailsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => MaterialsCubit()..getMaterialsForSubject(subject.id),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0E0A) : const Color(0xFFFAF9F5),
        body: Column(
          children: [
            SubjectDetailsHeader(subject: subject), 
            const DoctorMaterialsListView(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (_) => BlocProvider(
                    create: (context) => AddMaterialCubit()..subjectId = subject.id,
                    child: const AddMaterialModalBottomSheetBody(),
                  ),
                ).then((_) {
                  context.read<MaterialsCubit>().refresh();
                });
              },
              backgroundColor: const Color(0xFF1E8449),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
            );
          },
        ),
      ),
    );
  }
}
