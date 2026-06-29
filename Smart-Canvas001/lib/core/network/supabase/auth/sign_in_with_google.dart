import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '830674988394-94e5e5ajtm92dn5nv8dng9ucp3lnnk3i.apps.googleusercontent.com',
  );

  GoogleSignInAccount? _googleUser;

  Future<AuthResponse> signWithGoogle() async {
    try {
      _googleUser = await _googleSignIn.signIn();
      if (_googleUser == null) {
        throw Exception('Sign in aborted by user');
      }

      final googleAuth = await _googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Missing Google Auth Token(s)');
      }

      // 2️⃣ تسجيل الدخول في Supabase باستخدام Google
      final supabase = getIt<SupabaseClient>();
      final result = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // final userId = result.user?.id;
      // if (userId == null) {
      //   throw Exception('Failed to retrieve user ID from Supabase');
      // }

      // // 3️⃣ التحقق هل المستخدم مسجّل مسبقًا في جدول users
      // final response =
      //     await supabase.from('users').select().eq('id', userId).maybeSingle();

      // // 4️⃣ إضافة المستخدم لو مش موجود
      // if (response == null) {
      //   await addData(
      //     tableName: "users",
      //     data: {
      //       "id": userId, // مهم عشان يبقى الرابط مع Supabase Auth
      //       "full_name": _googleUser!.displayName ?? '',
      //       "username":
      //           _googleUser!.displayName?.replaceAll(' ', '_').toLowerCase() ??
      //               '',
      //       "email": result.user!.email,
      //       "image": _googleUser!.photoUrl,
      //     },
      //   );
      // }

      return result;
    } catch (e) {
      rethrow; // يسيب اللي بيستدعي هو اللي يتعامل مع الـ error
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await getIt<SupabaseClient>().auth.signOut();
    _googleUser = null;
  }
}
