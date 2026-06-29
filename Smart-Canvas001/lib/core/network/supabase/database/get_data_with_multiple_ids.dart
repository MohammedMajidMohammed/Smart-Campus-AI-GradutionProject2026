import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/error/supabase_exceptions.dart';

Future<List<Map<String, dynamic>>> getDataWithMultipleIds({
  required String tableName,
  required List<String> ids,
  String? primaryKey,
}) async {
  final supabase = getIt<SupabaseClient>();
  try {
    final response = await supabase
        .from(tableName)
        .select('*')
        .inFilter(primaryKey ?? 'id', ids);

    return response;
  } catch (e) {
    log(e.toString());
    throw SupabaseExceptions(errorMessage: '❌ Error while fetching data: $e');
  }
}
