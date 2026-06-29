import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:device_preview/device_preview.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_canvas/app/my_app.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:smart_canvas/core/services/enhanced_notification_service.dart';

import 'package:smart_canvas/core/services/presence_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase asynchronously to prevent startup blocking
  Firebase.initializeApp().then((_) {
    FirebaseMessaging.onBackgroundMessage(EnhancedNotificationService.firebaseMessagingBackgroundHandler);
  }).catchError((e) {
    debugPrint('Firebase initialization failed: $e');
  });
  
  await EasyLocalization.ensureInitialized();
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10,
    ),
  );
  await setupDI();
  await dotenv.load();
  PresenceService.instance.init();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      saveLocale: true,
      child: DevicePreview(enabled: false, builder: (context) => const MyApp()),
    ),
  );
}
