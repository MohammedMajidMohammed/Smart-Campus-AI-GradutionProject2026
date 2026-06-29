import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://yfdsfwqkrqgynfnkfkzg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZHNmd3FrcnFneW5mbmtma3zgIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTExMzgsImV4cCI6MjA4MTE2NzEzOH0.tP6Cc5MAbDkq18-cyvSj1IIxiKL8cTq6ltbqVcwpNtc',
  );

  final client1 = Supabase.instance.client;
  
  print('Client 1: Connecting to channel...');
  final channel = client1.channel('online_presence');
  
  channel.onPresenceSync((payload) {
    final state = channel.presenceState();
    print('Presence State updated: $state');
  });

  channel.subscribe((status, error) {
    print('Subscription status: $status, error: $error');
    if (status == RealtimeSubscribeStatus.subscribed) {
      print('Tracking presence for user1...');
      channel.track({
        'user_id': 'user-1-id',
        'online_at': DateTime.now().toIso8601String(),
      }).then((res) {
        print('Track result: success');
      }).catchError((err) {
        print('Track error: $err');
      });
    }
  });

  // Keep alive for 10 seconds to receive sync
  await Future.delayed(const Duration(seconds: 10));
}
