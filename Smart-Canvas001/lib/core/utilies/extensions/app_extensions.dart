import 'package:smart_canvas/app/my_app.dart';
import 'package:flutter/material.dart';

extension AppExtensions on BuildContext {
  //features/auth/cubit
  // CustomerSignUpCubit get CustomerSignUpCubit => read<CustomerSignUpCubit>();
  // SignInCubit get signInCubit => read<SignInCubit>();
  double get screenWidth => MediaQuery.of(navigatorKey.currentContext!).size.width;
  double get screenHeight => MediaQuery.of(navigatorKey.currentContext!).size.height;
  // ForgetPasswordCubit get forgetPasswordCubit => read<ForgetPasswordCubit>();

  // navigation
  void pushScreen(String routeName, {Object? arguments}) {
    Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }

  void pushReplacementScreen(String routeName,{Object? arguments}) {
    Navigator.of(this).pushReplacementNamed(routeName, arguments: arguments);
  }

  void pushAndRemoveUntilScreen(String routeName) {
    Navigator.of(this).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  void popScreen() {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    }
  }

  void popWithResult<T>(T result) {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop(result);
    }
  }

  bool canPopScreen() {
    return Navigator.of(this).canPop();
  }
}
