import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:line_icons/line_icons.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/components/custom_elevated_button.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/utilies/assets/images/app_images.dart';
import 'package:smart_canvas/core/utilies/assets/lotties/app_lotties.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/features/administrator/dashboard/models/administrator_action_model.dart';
import 'package:smart_canvas/features/administrator/dashboard/views/screens/administrator_dashboard_screen.dart';
import 'package:smart_canvas/features/administrator/home/models/g_button_model.dart';
import 'package:smart_canvas/features/admin/dashboard/models/doctor_action_model.dart';
import 'package:smart_canvas/features/admin/dashboard/views/screens/doctor_dashboard_screen.dart';
import 'package:smart_canvas/features/on_boarding/models/on_boarding_model.dart';
import 'package:smart_canvas/features/student/dashboard/views/screens/student_dashboard_screen.dart';
import 'package:smart_canvas/features/student/home/views/screens/student_buildings_screen.dart';
import 'package:smart_canvas/core/components/settings/settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/features/professor/dashboard/views/screens/professor_dashboard_screen.dart';
import 'package:smart_canvas/features/online_sessions/views/screens/student_subject_chat_list_screen.dart';
import 'package:smart_canvas/features/online_sessions/views/screens/professor_subject_chat_list_screen.dart';

import 'package:smart_canvas/core/components/settings/enhanced_notifications_screen.dart';
import 'package:smart_canvas/features/administrator/chat/views/screens/admin_chat_selection_screen.dart';

class AppConstants {
  // on boarding list
  // on boarding list
  static List<OnBoardingStepModel> get onBoardingList => <OnBoardingStepModel>[
    OnBoardingStepModel(
      image: AppLotties.courseMaterialsLottie, // course materials lottie
      title: "onboarding_title_1".tr(),
      subTitle: "onboarding_subtitle_1".tr(),
    ),
    OnBoardingStepModel(
      image: AppLotties.librarySearchLottie, // digital library lottie
      title: "onboarding_title_2".tr(),
      subTitle: "onboarding_subtitle_2".tr(),
    ),
    OnBoardingStepModel(
      image: AppLotties.notificationLottie, // notifications lottie
      title: "onboarding_title_3".tr(),
      subTitle: "onboarding_subtitle_3".tr(),
    ),
    OnBoardingStepModel(
      image: AppLotties.aiAssistantLottie, // AI chatbot lottie
      title: "onboarding_title_4".tr(),
      subTitle: "onboarding_subtitle_4".tr(),
    ),
    OnBoardingStepModel(
      image: AppLotties.loginLottie, // login/dashboard lottie
      title: "onboarding_title_5".tr(),
      subTitle: "onboarding_subtitle_5".tr(),
    ),
  ];
  //
  static List<String> get days => [
    "saturday".tr(),
    "sunday".tr(), 
    "monday".tr(),
    "tuesday".tr(),
    "wednesday".tr(),
    "thursday".tr(),
    "friday".tr(),
  ];
  static List<String> timeSlots = [
    "08:00 AM - 10:00 AM",
    "10:00 AM - 12:00 PM",
    "12:00 PM - 02:00 PM",
    "02:00 PM - 04:00 PM",
    "04:00 PM - 06:00 PM",
  ];
  // admministrator tabs
  static List<GButtonModel> get administratorTabs => <GButtonModel>[
    GButtonModel(
      index: 0,
      title: "home_tab",
      icon: LineIcons.home,
      onPressed: () {},
    ),
    GButtonModel(
      index: 1,
      title: "chat_tab",
      icon: LineIcons.facebookMessenger,
      onPressed: () {},
    ),
    GButtonModel(
      index: 2,
      title: "notifications_tab",
      icon: LineIcons.bell,
      onPressed: () {},
    ),
    GButtonModel(
      index: 3,
      title: "settings_tab",
      icon: LineIcons.cog,
      onPressed: () {},
    ),
  ];
  // administrator screens
  static List<Widget> get administratorScreens => [
    const AdministratorDashboardScreen(),
    const AdminChatManagementScreen(),
    const EnhancedNotificationsScreen(),
    const ProfessionalSettingsScreen(),
  ];
  // administrator actions
  static List<AdministratorActionModel> get administratorActions =>
      <AdministratorActionModel>[
        AdministratorActionModel(
          title: "buildings_action".tr(),
          image: AppImages.buildingsImage,
          route: RouteNames.buildingsScreen,
          icon: LineIcons.building,
        ),
        AdministratorActionModel(
          title: "rooms_action".tr(),
          image: AppImages.roomsImage,
          route: RouteNames.roomsScreen,
          icon: LineIcons.doorOpen,
        ),
        AdministratorActionModel(
          title: "collages_action".tr(),
          image: AppImages.collagesImage,
          route: RouteNames.collegesScreen,
          icon: LineIcons.university,
        ),
        AdministratorActionModel(
          title: "tables_action".tr(),
          image: AppImages.tablesImage,
          route: RouteNames.tablesScreen,
          icon: LineIcons.calendar,
        ),
        AdministratorActionModel(
          title: "users_action".tr(),
          image: AppImages.usersImage,
          route: RouteNames.usersScreen,
          icon: LineIcons.users,
        ),
      ];
  // admministrator tabs
  static List<GButtonModel> get doctorTabs => <GButtonModel>[
    GButtonModel(
      index: 0,
      title: "home_tab",
      icon: LineIcons.home,
      onPressed: () {},
    ),
    GButtonModel(
      index: 1,
      title: "chat_tab",
      icon: LineIcons.facebookMessenger,
      onPressed: () {},
    ),
    GButtonModel(
      index: 2,
      title: "notifications_tab",
      icon: LineIcons.bell,
      onPressed: () {},
    ),
    GButtonModel(
      index: 3,
      title: "settings_tab",
      icon: LineIcons.cog,
      onPressed: () {},
    ),
  ];

  // doctor screens
  static List<Widget> get doctorScreens => [
    const DoctorDashboardScreen(),
    const ProfessorSubjectChatListScreen(),
    const EnhancedNotificationsScreen(),
    const ProfessionalSettingsScreen(),
  ];
  // administrator actions
  static List<DoctorActionModel> get doctorActions => <DoctorActionModel>[
    DoctorActionModel(
      title: "subjects_action".tr(),
      image: AppImages.subjectsImage,
      route: RouteNames.subjectsScreen,
    ),
    DoctorActionModel(
      title: "materials_action".tr(),
      image: AppImages.materialsImage,
      route: RouteNames.materialsScreen,
    ),
    DoctorActionModel(
      title: "classroom_action".tr(),
      image: AppImages.tablesImage, 
      route: RouteNames.digitalClassroomScreen,
    ),
  ];
  // student tabs
  static List<GButtonModel> get studentTabs => <GButtonModel>[
    GButtonModel(index: 0, title: "home_tab", icon: LineIcons.home),
    GButtonModel(index: 1, title: "buildings_action", icon: Icons.apartment),
    GButtonModel(index: 2, title: "chat_tab", icon: LineIcons.facebookMessenger),
    GButtonModel(index: 3, title: "settings_tab", icon: LineIcons.cog),
  ];

  // student screens
  static List<Widget> get studentScreens => [
    const StudentDashboardScreen(),
    const StudentBuildingsScreen(),
    const StudentSubjectChatListScreen(),
    const ProfessionalSettingsScreen(),
  ];
  // professor tabs
  static List<GButtonModel> get professorTabs => <GButtonModel>[
    GButtonModel(index: 0, title: "home_tab", icon: LineIcons.home),
    GButtonModel(index: 1, title: "buildings_action", icon: Icons.apartment),
    GButtonModel(index: 2, title: "chat_tab", icon: LineIcons.facebookMessenger),
    GButtonModel(index: 3, title: "settings_tab", icon: LineIcons.cog),
  ];

  // professor screens
  static List<Widget> get professorScreens => [
    const ProfessorDashboardScreen(),
    const StudentBuildingsScreen(),
    const ProfessorSubjectChatListScreen(),
    const ProfessionalSettingsScreen(),
  ];
  // Chatbot helper messages
  static List<String> get chatbotHelperMessage => <String>[
    "chatbot_help_1".tr(),
    "chatbot_help_2".tr(),
    "chatbot_help_3".tr(),
    "chatbot_help_4".tr(),
    "chatbot_help_5".tr(),
  ];
  
  static List<String> get regulationsChatbotHelperMessage => <String>[
    "reg_chatbot_help_1".tr(),
    "reg_chatbot_help_2".tr(),
    "reg_chatbot_help_3".tr(),
    "reg_chatbot_help_4".tr(),
    "reg_chatbot_help_5".tr(),
  ];

  static const String regulationsChatbotApiUrl = 'http://172.20.10.2:8000/api/chat/';

  static const String supabaseUrl = "https://yfdsfwqkrqgynfnkfkzg.supabase.co";
  static const String supabaseAnonKey = 
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZHNmd3FrcnFneW5mbmtma3pnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTExMzgsImV4cCI6MjA4MTE2NzEzOH0.tP6Cc5MAbDkq18-cyvSj1IIxiKL8cTq6ltbqVcwpNtc";
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CustomElevatedButton(
          name: "sign_out".tr(),
          onPressed: () async {
            await getIt<SupabaseClient>().auth.signOut();
            await getIt<CacheHelper>().clearData();
            context.pushAndRemoveUntilScreen(RouteNames.signInScreen);
          },
        ),
      ),
    );
  }
}
