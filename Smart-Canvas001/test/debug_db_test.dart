import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/core/constants/app_constants.dart';

void main() {
  test('debug db', () async {
    final supabase = SupabaseClient(
      AppConstants.supabaseUrl,
      AppConstants.supabaseAnonKey,
    );
    
    try {
      final response = await supabase.from('roles').select('*');
      print('--- ROLES ---');
      for (var row in response) {
        print('Role: ID=${row['id']}, Name=${row['name']}');
      }
    } catch (e) {
      print('Roles error: $e');
    }
    
    try {
      final users = await supabase.from('users').select('*, roles(name)');
      print('--- USERS ---');
      for (var user in users) {
        print('User: ID=${user['id']}, Name=${user['full_name']}, RoleID=${user['role_id']}, RoleName=${user['roles']?['name']}');
      }
    } catch (e) {
      print('Users error: $e');
      
      // Try simple query if join fails
      try {
        final simpleUsers = await supabase.from('users').select('*');
        print('--- SIMPLE USERS ---');
        for (var user in simpleUsers) {
          print('User: ID=${user['id']}, Name=${user['full_name']}, RoleID=${user['role_id']}');
        }
      } catch (e2) {
        print('Simple users error: $e2');
      }
    }
  });
}
