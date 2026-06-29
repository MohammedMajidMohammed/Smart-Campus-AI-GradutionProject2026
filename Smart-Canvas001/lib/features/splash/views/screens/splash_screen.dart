import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/utilies/extensions/app_extensions.dart';
import 'package:smart_canvas/features/splash/views/widgets/splash_screen_body.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/features/auth/sign_in/models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    _navigateToNextScreen();
    super.initState();
  }

  Future<void> _navigateToNextScreen() async {
    final startTime = DateTime.now();
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Try fetching the latest user details from network first to handle role/college updates immediately
      try {
        if (session.isExpired) {
          debugPrint('SplashScreen: Session is expired, refreshing...');
          await Supabase.instance.client.auth.refreshSession();
        }
        
        final freshSession = Supabase.instance.client.auth.currentSession;
        final userId = freshSession?.user.id ?? session.user.id;
        
        final res = await Supabase.instance.client.rpc(
          'get_user_with_role',
          params: {'p_user_id': userId},
        );
        final list = res as List;
        if (list.isEmpty) throw Exception("User not found");
        final data = list.first;

        final userModel = UserModel.fromJson(data);
        await getIt<CacheHelper>().saveUserModel(userModel);

        if (!mounted) return;
        final roleName = userModel.roleName;
        await _waitForMinDelay(startTime);
        _navigateToRole(roleName);
      } catch (e) {
        // Fallback to local cache if network is offline or request fails
        final cachedUser = getIt<CacheHelper>().getUserModel();
        if (cachedUser != null && cachedUser.roleName.isNotEmpty) {
          if (!mounted) return;
          final roleName = cachedUser.roleName;
          await _waitForMinDelay(startTime);
          _navigateToRole(roleName);
        } else {
          // If both fail, navigate to auth
          if (!mounted) return;
          await _waitForMinDelay(startTime);
          _navigateToAuth();
        }
      }
    } else {
      await _waitForMinDelay(startTime);
      if (!mounted) return;
      _navigateToAuth();
    }
  }

  void _navigateToRole(String roleName) {
    if (!mounted) return;
    final normalizedRole = roleName.trim().toLowerCase();
    if (normalizedRole == 'administrator') {
      context.pushReplacementScreen(RouteNames.administratorHomeScreen);
    } else if (normalizedRole == 'admin' || normalizedRole == 'doctor') {
      context.pushReplacementScreen(RouteNames.doctorHomeScreen);
    } else if (normalizedRole == 'professor') {
      context.pushReplacementScreen(RouteNames.professorHomeScreen);
    } else if (normalizedRole == 'student') {
      context.pushReplacementScreen(RouteNames.studentHomeScreen);
    } else {
      context.pushReplacementScreen(RouteNames.studentHomeScreen);
    }
  }

  Future<void> _waitForMinDelay(DateTime startTime) async {
    final elapsed = DateTime.now().difference(startTime);
    final remainingDelay = const Duration(milliseconds: 2500) - elapsed;
    if (remainingDelay > Duration.zero) {
      await Future.delayed(remainingDelay);
    }
  }

  void _navigateToAuth() {
    final onBoardingVisited = getIt<CacheHelper>().getData(key: 'onBoarding');
    if (onBoardingVisited == true) {
      context.pushReplacementScreen(RouteNames.signInScreen);
    } else {
      context.pushReplacementScreen(RouteNames.onBoardingScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SplashScreenBody(),
    );
  }
}

