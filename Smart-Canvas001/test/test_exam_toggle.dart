import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';

void main() {
  test('test exam toggle', () async {
    final supabase = SupabaseClient(
      AppConstants.supabaseUrl,
      AppConstants.supabaseAnonKey,
    );
    
    try {
      print('Fetching exams...');
      final exams = await supabase.from('exams').select('*');
      print('Exams found: ${exams.length}');
      for (var exam in exams) {
        print('Exam: ID=${exam['id']}, Title=${exam['title']}, IsActive=${exam['is_active']}, OpenAt=${exam['open_at']}, CloseAt=${exam['close_at']}');
        
        final testId = exam['id'].toString();
        final currentActive = exam['is_active'] == true;
        print('Attempting to update is_active to ${!currentActive} for exam $testId...');
        
        try {
          final res = await supabase.from('exams').update({'is_active': !currentActive}).eq('id', testId).select('*');
          print('Update response: $res');
        } catch (updateError) {
          print('Update error for exam $testId: $updateError');
        }
      }
    } catch (e) {
      print('Fetch error: $e');
    }
  });
}
