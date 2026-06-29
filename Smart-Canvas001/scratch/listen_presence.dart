import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://yfdsfwqkrqgynfnkfkzg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZHNmd3FrcnFneW5mbmtma3zgIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTExMzgsImV4cCI6MjA4MTE2NzEzOH0.tP6Cc5MAbDkq18-cyvSj1IIxiKL8cTq6ltbqVcwpNtc',
  );

  final client = Supabase.instance.client;
  print('Listening to presence channel online_presence for 60 seconds...');
  
  final channel = client.channel('online_presence');
  
  channel.onPresenceSync((payload) {
    final state = channel.presenceState();
    print('\n--- Presence Sync Event ---');
    for (final entry in state) {
      print('Key: ${entry.key}');
      for (var p in entry.presences) {
        print('  Presence Ref: ${p.presenceRef}');
        print('  Payload: ${p.payload}');
      }
    }
  });

  channel.subscribe((status, error) {
    print('Listener subscription status: $status, error: $error');
  });

  await Future.delayed(const Duration(seconds: 60));
  print('Done listening.');
}
