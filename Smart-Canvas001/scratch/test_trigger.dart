import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://yfdsfwqkrqgynfnkfkzg.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZHNmd3FrcnFneW5mbmtma3pnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTExMzgsImV4cCI6MjA4MTE2NzEzOH0.tP6Cc5MAbDkq18-cyvSj1IIxiKL8cTq6ltbqVcwpNtc',
  );

  try {
    print('Fetching a college...');
    final colleges = await supabase.from('colleges').select('id, name');
    if (colleges.isEmpty) {
      print('No colleges found!');
      return;
    }
    final collegeId = colleges.first['id'];
    final collegeName = colleges.first['name'];
    print('Selected College: $collegeName (ID: $collegeId)');

    print('Attempting to update Administrator user with college_id...');
    final response = await supabase
        .from('users')
        .update({'college_id': collegeId})
        .eq('id', '4dbee268-5f9d-415d-97f8-b4ae9a5e8254')
        .select();

    print('Update successful! Response: $response');
  } catch (e) {
    print('Error: $e');
  }
}
