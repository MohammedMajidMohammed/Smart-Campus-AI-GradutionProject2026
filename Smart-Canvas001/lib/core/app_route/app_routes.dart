import 'package:smart_canvas/features/administrator/buildings/view_models/cubit/buildings_cubit.dart';
import 'package:smart_canvas/features/profile/view_models/profile_cubit.dart';
import 'package:smart_canvas/features/student/dashboard/view_models/college_data_cubit.dart';
import 'package:smart_canvas/features/administrator/buildings/views/screens/buildings_screen.dart';
import 'package:smart_canvas/features/administrator/collages/view_models/cubit/colleges_cubit.dart';
import 'package:smart_canvas/features/administrator/collages/views/screens/collages_screen.dart';
import 'package:smart_canvas/features/administrator/home/view_models/cubit/administrator_bottom_nav_bar_cubit.dart';
import 'package:smart_canvas/features/administrator/home/views/screens/administrator_home_screen.dart';
import 'package:smart_canvas/features/administrator/rooms/view_models/cubit/rooms_cubit.dart';
import 'package:smart_canvas/features/administrator/rooms/views/screens/rooms_screen.dart';
import 'package:smart_canvas/features/administrator/schedule/views/screens/schedules_screen.dart';
import 'package:smart_canvas/features/auth/select_role/views/screens/select_role_screen.dart';
import 'package:smart_canvas/features/auth/sign_in/view_models/cubit/sign_in_cubit.dart';
import 'package:smart_canvas/features/auth/sign_in/views/screens/sign_in_screen.dart';
import 'package:smart_canvas/features/auth/sign_up/view_models/cubit/sign_up_cubit.dart';
import 'package:smart_canvas/features/auth/sign_up/views/screens/sign_up_screen.dart';
import 'package:smart_canvas/features/admin/home/view_models/cubit/doctor_bottom_nav_bar_cubit.dart';
import 'package:smart_canvas/features/admin/home/views/screens/doctor_home_screen.dart';
import 'package:smart_canvas/features/admin/material/view_models/cubit/materials_cubit.dart';
import 'package:smart_canvas/features/admin/material/views/screens/materials_screen.dart';
import 'package:smart_canvas/features/admin/schedule/view_models/cubit/schedules_cubit.dart';
import 'package:smart_canvas/features/admin/schedule/views/screens/doctor_schedules_screen.dart';
import 'package:smart_canvas/features/admin/subjects/view_models/cubit/subjects_cubit.dart';
import 'package:smart_canvas/features/admin/subjects/views/screens/subjects_screen.dart';
import 'package:smart_canvas/features/on_boarding/view_models/cubit/on_boarding_cubit.dart';
import 'package:smart_canvas/features/on_boarding/views/screens/on_boarding_screen.dart';
import 'package:smart_canvas/features/professor/schedule/views/screens/professor_schedule_screen.dart';
import 'package:smart_canvas/features/splash/views/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/features/student/chatbots/views/screens/chatbots_screen.dart';
import 'package:smart_canvas/features/student/schedule/view_models/cubit/student_schedule_cubit.dart';
import 'package:smart_canvas/features/student/schedule/views/screens/student_schedule_screen.dart';
import 'package:smart_canvas/features/student/study_chatbot/view_models/cubit/study_chatbot_cubit.dart';
import 'package:smart_canvas/features/student/study_chatbot/views/screens/study_chatbot_screen.dart';
import 'package:smart_canvas/features/student/home/view_models/cubit/student_bottom_nav_bar_cubit.dart';
import 'package:smart_canvas/features/student/home/views/screens/student_home_screen.dart';
import 'package:smart_canvas/features/student/subject_details/views/screens/subject_details_screen.dart';
import 'package:smart_canvas/features/administrator/user_management/view_models/cubit/users_cubit.dart';
import 'package:smart_canvas/features/administrator/user_management/views/screens/users_screen.dart';
import 'package:smart_canvas/features/professor/attendance/views/screens/qr_attendance_screen.dart';
import 'package:smart_canvas/features/admin/classroom/views/screens/digital_classroom_screen.dart';
import 'package:smart_canvas/features/student/attendance/views/screens/qr_scanner_screen.dart';
import 'package:smart_canvas/features/professor/home/view_models/cubit/professor_bottom_nav_bar_cubit.dart';
import 'package:smart_canvas/features/professor/home/views/screens/professor_home_screen.dart';
import 'package:smart_canvas/core/components/settings/enhanced_notifications_screen.dart';
import 'package:smart_canvas/features/student/attendance/views/screens/student_attendance_history_screen.dart';
import 'package:smart_canvas/features/student/regulations_chatbot/view_models/cubit/regulations_chatbot_cubit.dart';
import 'package:smart_canvas/features/student/regulations_chatbot/views/screens/regulations_chatbot_screen.dart';
import 'package:smart_canvas/features/professor/exams/views/screens/exams_screen.dart';
import 'package:smart_canvas/features/student/exams/views/screens/student_exams_screen.dart';
import 'package:smart_canvas/features/professor/online_sessions/views/screens/professor_online_sessions_screen.dart';
import 'package:smart_canvas/features/student/online_sessions/views/screens/student_online_sessions_screen.dart';
import 'package:smart_canvas/features/online_sessions/view_models/cubit/online_sessions_cubit.dart';
import 'package:smart_canvas/features/online_sessions/services/online_sessions_service.dart';
import 'package:smart_canvas/features/online_sessions/services/subject_chat_service.dart';
import 'package:smart_canvas/features/online_sessions/view_models/cubit/subject_chat_cubit.dart';
import 'package:smart_canvas/features/online_sessions/views/screens/subject_chat_screen.dart';
import 'package:smart_canvas/features/online_sessions/views/screens/professor_subject_chat_list_screen.dart';
import 'package:smart_canvas/features/online_sessions/views/screens/student_subject_chat_list_screen.dart';
import 'package:smart_canvas/features/professor/assignments/views/screens/doctor_assignments_screen.dart';
import 'package:smart_canvas/features/student/assignments/views/screens/student_assignments_screen.dart';
import 'package:smart_canvas/features/student/home/views/screens/student_subjects_screen.dart';


class AppRoutes {
  static Map<String, Widget Function(BuildContext)> routes =
      <String, WidgetBuilder>{
        RouteNames.splashScreen: (context) => const SplashScreen(),
        RouteNames.onBoardingScreen: (context) => BlocProvider(
          create: (context) => OnBoardingCubit(),
          child: const OnBoardingScreen(),
        ),
        RouteNames.signInScreen: (context) => BlocProvider(
          create: (context) => SignInCubit(),
          child: const SignInScreen(),
        ),
        RouteNames.selectRoleScreen: (context) => const SelectRoleScreen(),
        RouteNames.signUpScreen: (context) => BlocProvider(
          create: (context) => SignUpCubit(),
          child: const SignUpScreen(),
        ),

        // Administrator Routes
        RouteNames.administratorHomeScreen: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => AdministratorBottomNavBarCubit()),
            BlocProvider(create: (context) => ProfileCubit()..loadUserProfile()),
          ],
          child: const AdministratorHomeScreen(),
        ),
        RouteNames.collegesScreen: (context) => BlocProvider(
          create: (context) => CollegesCubit(),
          child: const CollagesScreen(),
        ),
        RouteNames.buildingsScreen: (context) => BlocProvider(
          create: (context) => BuildingsCubit(),
          child: const BuildingsScreen(),
        ),
        RouteNames.roomsScreen: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final String? buildingId = args?.toString();
          return BlocProvider(
            create: (context) => RoomsCubit(initialBuildingId: buildingId),
            child: const RoomsScreen(),
          );
        },
        RouteNames.subjectsScreen: (context) => BlocProvider(
          create: (context) => SubjectsCubit(),
          child: const SubjectsScreen(),
        ),
        RouteNames.tablesScreen:(context)=> const TablesScreen(),
        RouteNames.materialsScreen: (context) => BlocProvider(
          create: (context) => MaterialsCubit(),
          child: const MaterialsScreen(),
        ),
        RouteNames.doctorHomeScreen: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => DoctorBottomNavBarCubit()),
            BlocProvider(create: (context) => ProfileCubit()..loadUserProfile()),
          ],
          child: const DoctorHomeScreen(),
        ),
        RouteNames.studentHomeScreen: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => StudentBottomNavBarCubit()),
            BlocProvider(create: (context) => ProfileCubit()..loadUserProfile()),
            BlocProvider(create: (context) => CollegeDataCubit()..getStudentSubjects()),
          ],
          child: const StudentHomeScreen(),
        ),
        RouteNames.doctorSchedulesScreen: (context) => BlocProvider(
          create: (context) => DoctorSchedulesCubit(),
          child: const DoctorSchedulesScreen(),
        ),
        RouteNames.subjectDetailsScreen: (context) =>
            const SubjectDetailsScreen(),
        RouteNames.studentSubjectsScreen: (context) =>
            const StudentSubjectsScreen(),
        RouteNames.studentMaterialsScreen: (context) =>
            const StudentSubjectsScreen(isMaterialsView: true),
        RouteNames.chatbotsScreen: (context) => const ChatbotsScreen(),
        RouteNames.studyChatbotScreen: (context) => BlocProvider(
          create: (context) => StudyChatbotCubit(),
          child: const StudyChatbotScreen(),
        ),
        RouteNames.regulationsChatbotScreen: (context) => BlocProvider(
          create: (context) => RegulationsChatbotCubit(),
          child: const RegulationsChatbotScreen(),
        ),
        RouteNames.studySchedulesScreen: (context) => BlocProvider(
          create: (context) => StudentScheduleCubit(),
          child: const StudentScheduleScreen(),
        ),
        RouteNames.professorSchedulesScreen: (context) => const ProfessorSchedulesScreen(),
        RouteNames.professorHomeScreen: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => ProfessorBottomNavBarCubit()),
            BlocProvider(create: (context) => ProfileCubit()..loadUserProfile()),
          ],
          child: const ProfessorHomeScreen(),
        ),
        // Administrator User Management
        RouteNames.usersScreen: (context) => BlocProvider(
          create: (context) => UsersCubit(),
          child: const UsersScreen(),
        ),
        RouteNames.qrAttendanceScreen: (context) => const QrAttendanceScreen(),
        RouteNames.qrScannerScreen: (context) => const QrScannerScreen(),
        RouteNames.digitalClassroomScreen: (context) => const DigitalClassroomScreen(),
        RouteNames.enhancedNotificationsScreen: (context) => const EnhancedNotificationsScreen(),
        RouteNames.studentAttendanceHistoryScreen: (context) => const StudentAttendanceHistoryScreen(),
        // Exam System
        RouteNames.examsScreen: (context) => const ExamsScreen(),
        RouteNames.studentExamsScreen: (context) => const StudentExamsScreen(),
        
        // Online Sessions
        RouteNames.professorOnlineSessionsScreen: (context) => BlocProvider(
          create: (context) => OnlineSessionsCubit(getIt<OnlineSessionsService>())..subscribeToSessions(isProfessor: true),
          child: const ProfessorOnlineSessionsScreen(),
        ),
        RouteNames.studentOnlineSessionsScreen: (context) => BlocProvider(
          create: (context) => OnlineSessionsCubit(getIt<OnlineSessionsService>())..subscribeToSessions(isProfessor: false),
          child: const StudentOnlineSessionsScreen(),
        ),
        RouteNames.subjectChatScreen: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return BlocProvider(
            create: (context) => SubjectChatCubit(getIt<SubjectChatService>()),
            child: SubjectChatScreen(
              subjectId: args['subjectId'],
              subjectName: args['subjectName'],
            ),
          );
        },
        RouteNames.professorSubjectChatListScreen: (context) => const ProfessorSubjectChatListScreen(),
        RouteNames.studentSubjectChatListScreen: (context) => BlocProvider(
          create: (context) => CollegeDataCubit()..getStudentSubjects(),
          child: const StudentSubjectChatListScreen(),
        ),
        RouteNames.doctorAssignmentsScreen: (context) => const DoctorAssignmentsScreen(),
        RouteNames.studentAssignmentsScreen: (context) => const StudentAssignmentsScreen(),
      };
}
