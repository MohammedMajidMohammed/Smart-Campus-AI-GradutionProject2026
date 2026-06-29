import 'package:flutter/material.dart';
import 'package:smart_canvas/features/admin/dashboard/views/widgets/doctor_dashboard_screen_body.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(child: DoctorDashboardScreenBody()),
    );
  }
}

