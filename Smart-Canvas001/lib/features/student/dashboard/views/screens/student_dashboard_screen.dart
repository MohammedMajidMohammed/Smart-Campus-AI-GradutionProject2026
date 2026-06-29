import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/student/dashboard/view_models/college_data_cubit.dart';
import 'package:smart_canvas/features/student/dashboard/views/widgets/student_dashboard_screen_body.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as Supabase_flutter;
import 'package:smart_canvas/features/student/dashboard/view_models/cubit/attendance_cubit/attendance_cubit.dart';
import 'package:smart_canvas/features/student/dashboard/repositories/attendance_repository.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => CollegeDataCubit()..getStudentSubjects(),
            ),
            BlocProvider(
              create: (context) => AttendanceCubit(
                AttendanceRepository(getIt<Supabase_flutter.SupabaseClient>()),
              ),
            ),
          ],
          child: const StudentDashboardScreenBody(),
        ),
      ),
    );
  }
}
