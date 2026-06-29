import 'package:flutter/material.dart';
import 'package:smart_canvas/features/admin/schedule/views/widgets/schedules_screen_body.dart';

class DoctorSchedulesScreen extends StatelessWidget {
  const DoctorSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DoctorSchedulesScreenBody(),
    );
  }
}
