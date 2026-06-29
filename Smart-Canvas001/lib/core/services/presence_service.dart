import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceService {
  PresenceService._();
  static final instance = PresenceService._();

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _presenceChannel;

  final ValueNotifier<Set<String>> onlineUserIds = ValueNotifier<Set<String>>({});

  bool _initialized = false;

  void init() {
    if (_initialized) {
      debugPrint('PresenceService: Already initialized, skipping init()');
      return;
    }
    _initialized = true;
    debugPrint('PresenceService: init() called');
    
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;
      debugPrint('PresenceService: onAuthStateChange fired: $event, session exists: ${session != null}');
      
      if (session != null) {
        _startTracking(session.user.id);
      } else {
        _stopTracking();
      }
    });

    final initialSession = _supabase.auth.currentSession;
    debugPrint('PresenceService: initialSession check: ${initialSession != null}');
    if (initialSession != null) {
      _startTracking(initialSession.user.id);
    }
  }

  void _startTracking(String userId) {
    if (_presenceChannel != null) {
      debugPrint('PresenceService: Already tracking presence on channel');
      return;
    }

    debugPrint('PresenceService: _startTracking() for user: $userId');
    _presenceChannel = _supabase.channel('online_presence');
    
    _presenceChannel!.onPresenceSync((payload) {
      final state = _presenceChannel!.presenceState();
      final onlineIds = <String>{};
      
      for (final presenceState in state) {
        for (final presence in presenceState.presences) {
          final id = presence.payload['user_id'] as String?;
          if (id != null) {
            onlineIds.add(id);
          }
        }
      }
      
      debugPrint('PresenceService: Presence Sync event. Online users: $onlineIds');
      onlineUserIds.value = onlineIds;
    });

    _presenceChannel!.subscribe((status, error) {
      debugPrint('PresenceService: Subscription status: $status, error: $error');
      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint('PresenceService: Tracking user $userId on channel');
        _presenceChannel!.track({
          'user_id': userId,
          'online_at': DateTime.now().toIso8601String(),
        }).then((value) {
          debugPrint('PresenceService: Successfully tracked presence on server.');
        }).catchError((err) {
          debugPrint('PresenceService: Failed to track presence on server: $err');
        });
      }
    });
  }

  void _stopTracking() {
    debugPrint('PresenceService: _stopTracking() called');
    _presenceChannel?.unsubscribe();
    _presenceChannel = null;
    onlineUserIds.value = {};
  }
}
