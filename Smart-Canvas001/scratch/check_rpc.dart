import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://yfdsfwqkrqgynfnkfkzg.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZHNmd3FrcnFneW5mbmtma3pnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTExMzgsImV4cCI6MjA4MTE2NzEzOH0.tP6Cc5MAbDkq18-cyvSj1IIxiKL8cTq6ltbqVcwpNtc',
  );

  try {
    print('Calling get_subjects_with_college_and_year RPC...');
    final response = await supabase.rpc('get_subjects_with_college_and_year');
    if (response is List && response.isNotEmpty) {
      print('First subject returned from RPC keys: ${response.first.keys}');
      print('First subject content: ${response.first}');
    } else {
      print('Empty response or not a list: $response');
    }

    print('\nCalling get_materials_with_subject_and_user RPC...');
    final responseMaterials = await supabase.rpc('get_materials_with_subject_and_user');
    if (responseMaterials is List && responseMaterials.isNotEmpty) {
      print('First material returned from RPC keys: ${responseMaterials.first.keys}');
      print('First material content: ${responseMaterials.first}');
    } else {
      print('Empty response or not a list: $responseMaterials');
    }
  } catch (e) {
    print('Error: $e');
  }
}
