// ignore_for_file: deprecated_member_use
import 'package:smart_canvas/core/app_route/app_routes.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/theme/app_theme.dart';
import 'package:smart_canvas/core/utilies/theme/theme_cubit.dart';
import 'package:device_preview/device_preview.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return LayoutBuilder(
            builder: (context, constraints) {
              SizeConfig.init(context);
              return MaterialApp(
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                builder: DevicePreview.appBuilder,
                useInheritedMediaQuery: true,
                // Localization
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                // Theme Configuration
                theme: AppTheme.getTheme(context, isDark: false),
                darkTheme: AppTheme.getTheme(context, isDark: true),
                themeMode: themeMode,
                // Routes
                routes: AppRoutes.routes,
                initialRoute: RouteNames.splashScreen,
                // Page Transitions
                onGenerateRoute: (settings) {
                  // Custom page transition for smooth navigation
                  final routes = AppRoutes.routes;
                  if (routes.containsKey(settings.name)) {
                    return PageRouteBuilder(
                      settings: settings,
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return routes[settings.name]!(context);
                      },
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const curve = Curves.easeInOutCubic;
                        var fadeAnimation = Tween<double>(
                          begin: 0.0,
                          end: 1.0,
                        ).animate(
                          CurvedAnimation(parent: animation, curve: curve),
                        );
                        var slideAnimation = Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(parent: animation, curve: curve),
                        );
                        return FadeTransition(
                          opacity: fadeAnimation,
                          child: SlideTransition(
                            position: slideAnimation,
                            child: child,
                          ),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    );
                  }
                  return null;
                },
              );
            },
          );
        },
      ),
    );
  }
}
