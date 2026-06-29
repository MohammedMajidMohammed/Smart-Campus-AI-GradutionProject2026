import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://yfdsfwqkrqgynfnkfkzg.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZHNmd3FrcnFneW5mbmtma3pnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTExMzgsImV4cCI6MjA4MTE2NzEzOH0.tP6Cc5MAbDkq18-cyvSj1IIxiKL8cTq6ltbqVcwpNtc',
  );

  try {
    print('Checking users table...');
    final response = await supabase
        .from('users')
        .select('*, roles(*)');
    
    print('Total users found: ${response.length}');
    for (var i = 0; i < response.length && i < 5; i++) {
      final row = response[i];
      print('User $i: ID=${row['id']}, Name=${row['full_name']}, Role=${row['roles']?['name'] ?? row['role_name'] ?? 'none'}, CollegeId=${row['college_id']}, AcademicYearId=${row['academic_year_id']}, YearLevel=${row['year_level']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
