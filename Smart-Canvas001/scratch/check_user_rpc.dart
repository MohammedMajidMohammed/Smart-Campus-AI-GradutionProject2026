import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://yfdsfwqkrqgynfnkfkzg.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZHNmd3FrcnFneW5mbmtma3pnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTExMzgsImV4cCI6MjA4MTE2NzEzOH0.tP6Cc5MAbDkq18-cyvSj1IIxiKL8cTq6ltbqVcwpNtc',
  );

  try {
    print('Checking users directly in DB...');
    final List<dynamic> users = await supabase.from('users').select('id, full_name, college_id, role_id, roles(name)');
    for (var u in users) {
      print('User: name=${u['full_name']}, id=${u['id']}, college_id=${u['college_id']}, role=${u['roles']?['name']}');
      
      print('Calling get_user_with_role for ${u['full_name']} (${u['id']})...');
      final res = await supabase.rpc('get_user_with_role', params: {'p_user_id': u['id']});
      print('Result: $res');
    }
  } catch (e) {
    print('Error: $e');
  }
}
