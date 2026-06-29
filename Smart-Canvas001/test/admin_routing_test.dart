import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canvas/features/auth/sign_in/models/user_model.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';

void main() {
  test('Test UserModel role parsing and routing resolution', () {
    // 1. Test Administrator format
    final Map<String, dynamic> adminJson1 = {
      'id': '71feea60-141a-4632-aba7-268e378c89de',
      'full_name': 'Mohammed',
      'role_name': 'Administrator'
    };

    // 2. Test Admin format
    final Map<String, dynamic> adminJson2 = {
      'id': '71feea60-141a-4632-aba7-268e378c89de',
      'full_name': 'Mohammed',
      'role_name': 'Admin'
    };

    // 3. Test lowercase admin format
    final Map<String, dynamic> adminJson3 = {
      'id': '71feea60-141a-4632-aba7-268e378c89de',
      'full_name': 'Mohammed',
      'role_name': 'admin '
    };

    final model1 = UserModel.fromJson(adminJson1);
    final model2 = UserModel.fromJson(adminJson2);
    final model3 = UserModel.fromJson(adminJson3);

    expect(model1.roleName, 'Administrator');
    expect(model2.roleName, 'Admin');
    expect(model3.roleName.trim(), 'admin');

    // Simulate getScreenRoute logic
    String getScreenRouteMock(String rawRole) {
      final roleName = rawRole.trim().toLowerCase();
      if (roleName == "student") {
        return RouteNames.studentHomeScreen;
      } else if (roleName == "administrator") {
        return RouteNames.administratorHomeScreen;
      } else if (roleName == "professor") {
        return RouteNames.professorHomeScreen;
      } else if (roleName == "admin") {
        return RouteNames.doctorHomeScreen;
      } else {
        return RouteNames.doctorHomeScreen;
      }
    }

    expect(getScreenRouteMock(model1.roleName), RouteNames.administratorHomeScreen);
    expect(getScreenRouteMock(model2.roleName), RouteNames.doctorHomeScreen);
    expect(getScreenRouteMock(model3.roleName), RouteNames.doctorHomeScreen);
  });
}
