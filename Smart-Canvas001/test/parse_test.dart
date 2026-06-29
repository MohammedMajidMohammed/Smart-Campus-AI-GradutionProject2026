import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canvas/features/auth/sign_in/models/user_model.dart';
import 'package:smart_canvas/features/auth/sign_in/models/role_model.dart';

void main() {
  test('Test parsing UserModel from get_user_with_role RPC and users table select', () {
    // 1. Format returned by get_user_with_role RPC
    final Map<String, dynamic> rpcJson = {
      'id': '71feea60-141a-4632-aba7-268e378c89de',
      'full_name': 'Mohammed',
      'role_id': 'dd4575e5-7cfb-4e89-9407-1ea5d3211516',
      'college_id': null,
      'academic_year_id': null,
      'created_at': '2026-06-08T11:43:08.52093+00:00',
      'image': null,
      'phone_number': null,
      'email': 'moh@gmail.com',
      'university_id': null,
      'current_year': null,
      'year_level': 1,
      'device_id': null,
      'role_name': 'Administrator'
    };

    // 2. Format returned by select('*, role:roles(*)')
    final Map<String, dynamic> selectJson = {
      'id': '71feea60-141a-4632-aba7-268e378c89de',
      'full_name': 'Mohammed',
      'role_id': 'dd4575e5-7cfb-4e89-9407-1ea5d3211516',
      'college_id': null,
      'academic_year_id': null,
      'created_at': '2026-06-08T11:43:08.52093+00:00',
      'image': null,
      'phone_number': null,
      'email': 'moh@gmail.com',
      'university_id': null,
      'current_year': null,
      'year_level': 1,
      'device_id': null,
      'role': {
        'id': 'dd4575e5-7cfb-4e89-9407-1ea5d3211516',
        'name': 'Administrator',
        'created_at': '2026-05-13T22:38:28.188448+00:00'
      }
    };

    try {
      final model1 = UserModel.fromJson(rpcJson);
      print('Parsed RPC user: name=${model1.fullName}, role=${model1.roleName}');
      expect(model1.roleName, 'Administrator');

      final model2 = UserModel.fromJson(selectJson);
      print('Parsed Select user: name=${model2.fullName}, role=${model2.roleName}');
      expect(model2.roleName, 'Administrator');
    } catch (e, stackTrace) {
      print('Parsing failed: $e');
      print(stackTrace);
      fail('UserModel parsing failed');
    }
  });
}
