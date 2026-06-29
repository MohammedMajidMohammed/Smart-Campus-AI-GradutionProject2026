import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/core/services/hive_service.dart';
import 'package:smart_canvas/core/services/notification_service.dart';
import 'package:smart_canvas/core/services/enhanced_notification_service.dart';
import 'package:smart_canvas/core/services/navigation_service.dart';
import 'package:smart_canvas/core/services/text_to_speech_service.dart';
import 'package:smart_canvas/features/online_sessions/services/online_sessions_service.dart';
import 'package:smart_canvas/features/online_sessions/services/subject_chat_service.dart';
import 'package:smart_canvas/features/professor/assignments/services/assignments_service.dart';
import 'package:smart_canvas/features/professor/assignments/view_models/doctor_assignment_cubit.dart';
import 'package:smart_canvas/features/student/assignments/view_models/student_assignment_cubit.dart';
import 'package:smart_canvas/features/chat/services/chat_service.dart';

import 'package:smart_canvas/features/chat/view_models/cubit/generic_chat_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  final cacheHelper = CacheHelper();
  await cacheHelper.init();
  getIt.registerSingleton<CacheHelper>(cacheHelper);
  getIt.registerLazySingleton(() => Supabase.instance.client);
  
  final hiveService = HiveService();
  await hiveService.init();
  getIt.registerSingleton<HiveService>(hiveService);

  // Legacy notification service (keep for backward compatibility)
  final notificationService = NotificationService();
  await notificationService.init();
  getIt.registerSingleton<NotificationService>(notificationService);

  // Enhanced notification service with more features
  final enhancedNotificationService = EnhancedNotificationService();
  await enhancedNotificationService.init();
  getIt.registerSingleton<EnhancedNotificationService>(enhancedNotificationService);

  // Navigation Services
  getIt.registerLazySingleton<NavigationService>(() => NavigationService());
  getIt.registerLazySingleton<TextToSpeechService>(() => TextToSpeechService());
  getIt.registerLazySingleton<OnlineSessionsService>(() => OnlineSessionsService());
  getIt.registerLazySingleton<SubjectChatService>(() => SubjectChatService());
  getIt.registerLazySingleton<AssignmentsService>(() => AssignmentsService());
  getIt.registerLazySingleton<ChatService>(() => ChatService());
  
  // Cubits
  getIt.registerFactory(() => DoctorAssignmentCubit(getIt<AssignmentsService>()));
  getIt.registerFactory(() => StudentAssignmentCubit());
  getIt.registerFactory(() => GenericChatCubit(getIt<ChatService>()));
}

