import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/admin/material/view_models/cubit/materials_cubit.dart';
import 'package:smart_canvas/features/admin/material/views/widgets/doctor_material_header.dart';
import 'package:smart_canvas/features/admin/material/views/widgets/professor_subjects_list_view.dart';

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MaterialsCubit()..getProfessorSubjects(),
      child: BlocListener<MaterialsCubit, MaterialsState>(
        listener: (context, state) {
          if (state is GetMaterialsFailure) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Error"),
                content: Text(state.message),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
                ],
              ),
            );
          } else if (state is AddSubjectSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Subject Added Successfully!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: const Scaffold(
          body: Column(
            children: [
              DoctorMaterialsHeader(), // Reuse the premium header
              ProfessorSubjectsListView(), // New view to show subjects from schedule
            ],
          ),
        ),
      ),
    );
  }
}
