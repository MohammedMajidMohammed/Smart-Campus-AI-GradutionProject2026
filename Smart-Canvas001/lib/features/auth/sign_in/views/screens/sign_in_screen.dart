import 'package:flutter/material.dart';
import 'package:smart_canvas/features/auth/sign_in/views/widgets/sign_in_screen_body.dart';
import 'package:smart_canvas/features/splash/views/widgets/gradient_body.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GradientBody(
      child: SignInScreenBody(),
    );
  }
}

