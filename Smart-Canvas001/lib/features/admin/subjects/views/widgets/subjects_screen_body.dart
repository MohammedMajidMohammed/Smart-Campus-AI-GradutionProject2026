import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/admin/subjects/views/widgets/doctor_subjects_header.dart';
import 'package:smart_canvas/features/admin/subjects/views/widgets/doctor_subjects_list_view.dart';

class SubjectsScreenBody extends StatelessWidget {
  const SubjectsScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DoctorSubjectsHeader(),
        SizedBox(height: SizeConfig.height * 0.03),
        const DoctorSubjectsListView(),
      ],
    );
  }
}

