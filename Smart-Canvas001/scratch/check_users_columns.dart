import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://yfdsfwqkrqgynfnkfkzg.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZHNmd3FrcnFneW5mbmtma3zgIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTExMzgsImV4cCI6MjA4MTE2NzEzOH0.tP6Cc5MAbDkq18-cyvSj1IIxiKL8cTq6ltbqVcwpNtc',
  );

  try {
    print('Fetching all users...');
    final response = await supabase
        .from('users')
        .select('*');
    
    print('Total users fetched: ${response.length}');
    for (var u in response) {
      print('User ID: ${u['id']}, Name: ${u['full_name']}, Email: ${u['email']}, Keys: ${u.keys.join(', ')}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
