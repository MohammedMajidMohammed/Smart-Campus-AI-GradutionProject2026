import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/error/supabase_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Stream<List<Map<String, dynamic>>> streamDataWithSpecificId(
    {required String tableName,
    required String id,
    String? primaryKey}) async* {
  final supabase = getIt<SupabaseClient>();
  try {
    yield* supabase
        .from(tableName)
        .stream(primaryKey: ['id'])
        .eq(primaryKey ?? 'id', id)
        .handleError((error) {
          throw SupabaseExceptions(
              errorMessage: 'Error while streaming data: $error');
        })
        .map((data) {
          if (data.isEmpty) {
            return [];
          }
          return data;
        });
  } catch (e) {
    throw SupabaseExceptions(
        errorMessage: 'Exception caught in streamData: $e');
  }
}
