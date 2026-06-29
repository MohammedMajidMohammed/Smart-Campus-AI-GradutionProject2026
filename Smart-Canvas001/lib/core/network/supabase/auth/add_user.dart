import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<Map<String, dynamic>> createUser(String email, String password) async {
  final response = await http.post(
    Uri.parse(
        "https://cxvorxzdirqhrmualltt.supabase.co/functions/v1/hyper-function"),
    headers: {
      "Content-Type": "application/json",
      "Authorization":
          "Bearer ${getIt<SupabaseClient>().auth.currentSession?.accessToken}", // 👈
    },
    body: jsonEncode({
      "email": email,
      "password": password,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return data['user'];
    } else {
      throw Exception(data['error']);
    }
  } else {
    throw Exception(response.body);
  }
}
