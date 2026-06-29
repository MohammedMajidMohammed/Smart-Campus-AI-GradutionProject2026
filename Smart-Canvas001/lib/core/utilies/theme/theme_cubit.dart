import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const String _themeKey = 'theme_mode';

  void _loadTheme() {
    final cache = getIt<CacheHelper>();
    final savedTheme = cache.getData(key: _themeKey);
    
    if (savedTheme != null) {
      switch (savedTheme) {
        case 'light':
          emit(ThemeMode.light);
          break;
        case 'dark':
          emit(ThemeMode.dark);
          break;
        default:
          emit(ThemeMode.system);
      }
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    final cache = getIt<CacheHelper>();
    
    String themeValue;
    switch (mode) {
      case ThemeMode.light:
        themeValue = 'light';
        break;
      case ThemeMode.dark:
        themeValue = 'dark';
        break;
      default:
        themeValue = 'system';
    }
    
    await cache.saveData(key: _themeKey, value: themeValue);
    emit(mode);
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setTheme(ThemeMode.light);
    } else {
      setTheme(ThemeMode.dark);
    }
  }

  bool get isDarkMode => state == ThemeMode.dark;
}
