import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> signInWithFacebook() async {
  final supabase = Supabase.instance.client;

  try {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: "com.example.detect_ovarian_cancer://login-callback/", // لازم تزبطها تحت
    );
  } catch (e) {
    print("❌ Facebook login error: $e");
  }
}
