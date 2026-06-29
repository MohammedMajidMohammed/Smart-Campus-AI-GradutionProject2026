import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/error/supabase_exceptions.dart';
import 'package:smart_canvas/core/network/supabase/auth/handel_auth_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> signUpWithPassword(
    {required String email, required String password}) async {
  try {
    await getIt<SupabaseClient>().auth.signUp(email: email, password: password);
  } on AuthException catch (e) {
    throw SupabaseExceptions(errorMessage: handleAuthError(e));
  } catch (e) {
    throw SupabaseExceptions(errorMessage: e.toString());
  }
}
