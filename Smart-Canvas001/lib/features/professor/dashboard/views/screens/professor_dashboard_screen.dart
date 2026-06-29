import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/professor/dashboard/views/widgets/professor_dashboard_screen_body.dart';
import 'package:smart_canvas/features/professor/schedule/view_models/cubit/professor_schedule_cubit.dart';

class ProfessorDashboardScreen extends StatelessWidget {
  const ProfessorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: BlocProvider(
          create: (context) => ProfessorScheduleCubit(), // Reuse Schedule Cubit for "Today's Schedule" data
          child: const ProfessorDashboardScreenBody(),
        ),
      ),
    );
  }
}
