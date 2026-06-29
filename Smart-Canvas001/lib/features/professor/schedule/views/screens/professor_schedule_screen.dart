import 'package:flutter/material.dart';
import 'package:smart_canvas/features/professor/schedule/views/widgets/professor_schedule_screen_body.dart';


class ProfessorSchedulesScreen extends StatelessWidget {
  const ProfessorSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ProfessorSchedulesScreenBody(),
    );
  }
}
