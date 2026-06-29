import 'dart:developer';

import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/error/supabase_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> removeData({required String tableName,required Map<String,dynamic> data}) async {
  final supabase = getIt<SupabaseClient>();

try {
    final response = await supabase
        .from(tableName)
        .delete().match({...data})
        .select();

    if (response.isNotEmpty) {
      log('✅ User removed successfully!');
    } else {
      throw SupabaseExceptions(errorMessage: '❌ Failed to add data');
    }
  } catch (e) {
    throw SupabaseExceptions(errorMessage:  '❌ Error while adding data : $e');
  }
}
