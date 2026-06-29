import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/error/supabase_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<List<Map<String, dynamic>>> getData(
    {required String tableName, String? orderBy}) async {
  final supabase = getIt<SupabaseClient>();

  try {
    final response =
        await supabase.from(tableName).select().order(orderBy ?? 'created_at');
    if (response.isNotEmpty) {
      return response;
    } else {
      return [];
    }
  } catch (e) {
    throw SupabaseExceptions(errorMessage: '❌ Error while get data : $e');
  }
}
