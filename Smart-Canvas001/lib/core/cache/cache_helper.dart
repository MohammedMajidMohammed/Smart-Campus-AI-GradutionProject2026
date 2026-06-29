import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_canvas/features/auth/sign_in/models/user_model.dart';

class CacheHelper {
  static late SharedPreferences sharedPreferences;

  //! Initialize the cache
  Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  //! Save basic types
  Future<bool> saveData({required String key, required dynamic value}) async {
    if (value is bool) {
      return await sharedPreferences.setBool(key, value);
    } else if (value is String) {
      return await sharedPreferences.setString(key, value);
    } else if (value is int) {
      return await sharedPreferences.setInt(key, value);
    } else if (value is double) {
      return await sharedPreferences.setDouble(key, value);
    } else {
      throw Exception('Unsupported type');
    }
  }

  dynamic getData({required String key}) {
    return sharedPreferences.get(key);
  }

  String? getDataString({required String key}) {
    return sharedPreferences.getString(key);
  }

  Future<bool> removeData({required String key}) async {
    return await sharedPreferences.remove(key);
  }

  Future<bool> clearData() async {
    final Set<String> keysToPreserve = {
      'saved_username',
      'saved_password',
      'remember_me',
    };

    final keys = sharedPreferences.getKeys();
    bool allSuccess = true;
    for (String key in keys) {
      if (keysToPreserve.contains(key) ||
          key.startsWith('easy_localization') ||
          key.contains('theme') ||
          key.contains('locale')) {
        continue;
      }
      final success = await sharedPreferences.remove(key);
      if (!success) {
        allSuccess = false;
      }
    }
    return allSuccess;
  }

  Future<bool> containsKey({required String key}) async {
    return sharedPreferences.containsKey(key);
  }
  Future<bool> saveUserModel(UserModel customer) async {
    // نحول CustomerModel إلى json
    final customerJson = jsonEncode(customer.toJson());

    // نخزنها في SharedPreferences
    return await sharedPreferences.setString('user', customerJson);
  }

  UserModel? getUserModel() {
    final customerJson = sharedPreferences.getString('user');

    if (customerJson == null) return null; // لو مفيش داتا

    final Map<String, dynamic> decodedJson = jsonDecode(customerJson);

    return UserModel.fromJson(decodedJson);
  }
}
