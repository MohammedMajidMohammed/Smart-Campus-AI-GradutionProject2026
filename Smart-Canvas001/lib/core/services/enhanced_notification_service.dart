import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:smart_canvas/app/my_app.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

/// Enhanced Notification Service with persistence and management
class EnhancedNotificationService {
  static final EnhancedNotificationService _instance =
      EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Box<String>? _notificationsBox;

  // Reactive Notification List
  final ValueNotifier<List<NotificationItem>> notificationsNotifier =
      ValueNotifier<List<NotificationItem>>([]);

  // Reactive Unread Counter
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  // Notification channels
  static const String scheduleChannelId = 'schedule_channel';
  static const String materialChannelId = 'material_channel';
  static const String announcementChannelId = 'announcement_channel';
  static const String reminderChannelId = 'reminder_channel';

  Future<void> init() async {
    tz_data.initializeTimeZones();

    // Initialize Hive box for notifications
    try {
      _notificationsBox = await Hive.openBox<String>('notifications');
    } catch (e) {
      debugPrint('Hive box already open or error: $e');
      _notificationsBox = Hive.box<String>('notifications');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions on Android 13+
    await _requestPermissions();

    // Setup FCM
    await _setupFCM();

    // Setup Supabase Realtime Notification Listener
    _setupSupabaseRealtimeListener();

    // Check and trigger welcome notification
    final hasShownWelcome =
        getIt<CacheHelper>().getData(key: 'hasShownWelcome') as bool? ?? false;
    if (!hasShownWelcome) {
      // Small delay to ensure the app UI is loaded before firing
      Future.delayed(const Duration(seconds: 3), () async {
        await showNotification(
          id: 1, // Fixed ID for welcome
          title: "Welcome to Smart Campus 🎉",
          body:
              "Start exploring your academic journey with our powerful features. We're happy to see you!",
          type: NotificationType.general,
        );
        getIt<CacheHelper>().saveData(key: 'hasShownWelcome', value: true);
      });
    }
  }

  /// Top-level background message handler
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();
    debugPrint("Handling a background message: ${message.messageId}");

    // We can show a local notification here if needed
    // But FCM usually shows its own notification if 'notification' payload exists
  }

  Future<void> _setupFCM() async {
    // Check if Firebase is initialized before using it
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase not initialized, skipping FCM setup');
        return;
      }

      final messaging = FirebaseMessaging.instance;

      // Request permissions (especially for iOS)
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Get the token
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        // Save token to cache
        getIt<CacheHelper>().saveData(key: 'fcmToken', value: token);

        // Ideally, we should upload this token to Supabase users table here
        _uploadTokenToSupabase(token);
      }

      // Listen to messages while app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        if (message.notification != null) {
          showNotification(
            id: message.hashCode,
            title: message.notification!.title ?? 'New Message',
            body: message.notification!.body ?? '',
            type: NotificationType.general,
          );
        }
      });
    } catch (e) {
      debugPrint('Error setting up FCM: $e');
    }
  }

  Future<void> _uploadTokenToSupabase(String token) async {
    try {
      final user = getIt<CacheHelper>().getUserModel();
      if (user != null) {
        final supabase = Supabase.instance.client;
        await supabase
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Error uploading FCM token to Supabase: $e');
    }
  }

  void _setupSupabaseRealtimeListener() {
    final user = getIt<CacheHelper>().getUserModel();
    if (user == null) return;

    final supabase = Supabase.instance.client;

    // Listen to ALL new chat messages
    supabase
        .channel('global_chat_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final senderId = payload.newRecord['sender_id'];
            // Don't show notification for our own messages
            if (senderId != user.id) {
              final senderName =
                  payload.newRecord['sender_name'] ?? 'New Message';
              final content =
                  payload.newRecord['content'] ?? 'Sent an attachment';

              showNotification(
                id: payload.newRecord['id'].hashCode,
                title: senderName,
                body: content,
                type: NotificationType.general,
              );
            }
          },
        )
        .subscribe();

    // Listen to ALL new subject messages
    supabase
        .channel('global_subject_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'subject_messages',
          callback: (payload) {
            final senderId = payload.newRecord['sender_id'];
            if (senderId != user.id) {
              final senderName =
                  payload.newRecord['sender_name'] ?? 'New Message';
              final content =
                  payload.newRecord['content'] ?? 'Sent an attachment';

              showNotification(
                id: payload.newRecord['id'].hashCode,
                title: senderName,
                body: content,
                type: NotificationType.general,
              );
            }
          },
        )
        .subscribe();

    // Listen to NEW polls
    supabase
        .channel('global_polls_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'polls',
          callback: (payload) {
            final question =
                payload.newRecord['question'] ?? 'New Poll available';
            showNotification(
              id: payload.newRecord['id'].hashCode,
              title: "New Poll 📊",
              body: question,
              type: NotificationType.announcement,
            );
          },
        )
        .subscribe();

    // Listen to NEW assignments
    supabase
        .channel('global_assignments_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'broadcast_assignments',
          callback: (payload) {
            final title = payload.newRecord['title'] ?? 'New Assignment';
            showNotification(
              id: payload.newRecord['id'].hashCode,
              title: "New Assignment 📚",
              body: "A new assignment has been posted: $title",
              type: NotificationType.material,
            );
          },
        )
        .subscribe();

    // Listen to NEW and UPDATED exams
    supabase
        .channel('global_exams_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'exams',
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.insert) {
              final title = payload.newRecord['title'] ?? 'New Exam';
              showNotification(
                id: payload.newRecord['id'].hashCode,
                title: "New Exam Scheduled 📝",
                body: "A new exam has been scheduled: $title",
                type: NotificationType.announcement,
              );
            } else if (payload.eventType == PostgresChangeEvent.update) {
              final newRecord = payload.newRecord;
              final isActive = newRecord['is_active'] == true;
              if (isActive) {
                final title = newRecord['title'] ?? 'Exam';
                showNotification(
                  id: newRecord['id'].hashCode,
                  title: "Exam Active 🚀",
                  body: "The exam '$title' is now active and ready.",
                  type: NotificationType.announcement,
                );
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.requestNotificationsPermission();
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    if (response.actionId == 'navigation_action') {
      final location = response.payload ?? 'Unknown Location';
      _showLocationDialog(location);
    } else {
      debugPrint('Notification tapped: ${response.payload}');
    }
  }

  void _showLocationDialog(String location) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Lecture Location 📍"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                "Go to: $location",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Got it"),
            ),
          ],
        ),
      );
    }
  }

  /// Get stored notifications
  List<NotificationItem> getStoredNotifications() {
    if (_notificationsBox == null) return [];

    List<NotificationItem> notifications = [];
    for (var key in _notificationsBox!.keys) {
      try {
        final json = _notificationsBox!.get(key);
        if (json != null) {
          notifications.add(NotificationItem.fromJson(jsonDecode(json)));
        }
      } catch (e) {
        debugPrint('Error parsing notification: $e');
      }
    }

    // Sort by time (newest first)
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Update notifiers
    notificationsNotifier.value = notifications;
    _updateUnreadNotifier(notifications);
    return notifications;
  }

  void _updateUnreadNotifier(List<NotificationItem> items) {
    unreadCountNotifier.value = items.where((n) => !n.isRead).length;
  }

  /// Store notification
  Future<void> _storeNotification(NotificationItem notification) async {
    if (_notificationsBox == null) return;
    await _notificationsBox!.put(
      notification.id.toString(),
      jsonEncode(notification.toJson()),
    );
  }

  /// Mark notification as read
  Future<void> markAsRead(int id) async {
    if (_notificationsBox == null) return;
    final json = _notificationsBox!.get(id.toString());
    if (json != null) {
      final notification = NotificationItem.fromJson(jsonDecode(json));
      if (!notification.isRead) {
        notification.isRead = true;
        await _notificationsBox!.put(
          id.toString(),
          jsonEncode(notification.toJson()),
        );

        // Update reactive counter
        if (unreadCountNotifier.value > 0) {
          unreadCountNotifier.value--;
        }
      }
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    await _notificationsBox?.clear();
    await _notificationsPlugin.cancelAll();
    unreadCountNotifier.value = 0;
  }

  /// Delete specific notification
  Future<void> deleteNotification(int id) async {
    final json = _notificationsBox!.get(id.toString());
    if (json != null) {
      final notification = NotificationItem.fromJson(jsonDecode(json));
      if (!notification.isRead && unreadCountNotifier.value > 0) {
        unreadCountNotifier.value--;
      }
    }

    await _notificationsBox?.delete(id.toString());
    await _notificationsPlugin.cancel(id);
  }

  /// Get unread count
  int getUnreadCount() {
    return getStoredNotifications().where((n) => !n.isRead).length;
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.general,
  }) async {
    final channelId = _getChannelId(type);
    final channelName = _getChannelName(type);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Smart Campus $channelName',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2ECC71),
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );

    // Store notification
    await _storeNotification(
      NotificationItem(
        id: id,
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
        isRead: false,
      ),
    );

    // Refresh list to trigger UI updates
    getStoredNotifications();
  }

  /// Schedule notification for specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    NotificationType type = NotificationType.schedule,
  }) async {
    final channelId = _getChannelId(type);
    final channelName = _getChannelName(type);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Smart Campus $channelName',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF2ECC71),
        actions: [
          const AndroidNotificationAction(
            'navigation_action',
            'View Location 📍',
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final canExact = await _canScheduleExact();

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling notification (exact: $canExact): $e');
      if (canExact) {
        try {
          await _notificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(scheduledTime, tz.local),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload,
          );
        } catch (fallbackError) {
          debugPrint('Fallback notification failed: $fallbackError');
        }
      }
    }

    // Store scheduled notification
    await _storeNotification(
      NotificationItem(
        id: id,
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
        scheduledFor: scheduledTime,
        isRead: false,
      ),
    );
  }

  /// Schedule daily reminder
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        reminderChannelId,
        'Daily Reminders',
        channelDescription: 'Daily study reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    final canExact = await _canScheduleExact();

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
    } catch (e) {
      debugPrint('Error scheduling daily reminder (exact: $canExact): $e');
      if (canExact) {
        try {
          await _notificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(scheduledDate, tz.local),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
          );
        } catch (fallbackError) {
          debugPrint('Fallback daily reminder failed: $fallbackError');
        }
      }
    }
  }

  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.schedule:
        return scheduleChannelId;
      case NotificationType.material:
        return materialChannelId;
      case NotificationType.announcement:
        return announcementChannelId;
      case NotificationType.reminder:
        return reminderChannelId;
      default:
        return 'general_channel';
    }
  }

  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.schedule:
        return 'Schedule Notifications';
      case NotificationType.material:
        return 'Material Updates';
      case NotificationType.announcement:
        return 'Announcements';
      case NotificationType.reminder:
        return 'Reminders';
      default:
        return 'General';
    }
  }

  Future<bool> _canScheduleExact() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;
    try {
      return await androidPlugin.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// Notification types
enum NotificationType { general, schedule, material, announcement, reminder }

/// Notification item model
class NotificationItem {
  final int id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.scheduledFor,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values[json['type'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'] as String)
          : null,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.index,
      'createdAt': createdAt.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'isRead': isRead,
    };
  }

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.schedule:
        return Icons.schedule;
      case NotificationType.material:
        return Icons.book;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.reminder:
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.schedule:
        return const Color(0xFF2ECC71);
      case NotificationType.material:
        return const Color(0xFF10B981);
      case NotificationType.announcement:
        return const Color(0xFFF59E0B);
      case NotificationType.reminder:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
