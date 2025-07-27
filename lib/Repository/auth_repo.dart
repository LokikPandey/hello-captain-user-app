import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Helper/api_config.dart';
import 'package:hello_captain_user/Models/app_settings_model.dart';
import 'package:hello_captain_user/Models/user_model.dart';
import 'package:hive/hive.dart';
import '../Essentials/KNavigationBar.dart';
import '../Helper/hive_config.dart';

final userProvider = StateProvider<UserModel?>((ref) => null);

final appSettingsProvider = StateProvider<AppSettingsModel?>((ref) => null);

final authFuture = FutureProvider((ref) async {
  try {
    final hiveBox = await Hive.openBox('hiveBox');
    final userData = hiveBox.get('userData');
    final phone = userData?["phone"];
    final password = userData?["password"];
    if (phone == null || password == null) {
      throw "User not logged in!";
    }

    final res = await AuthRepo.login(phone, password);
    if (res["code"] != "200") {
      throw res["message"];
    }
    ref.read(userProvider.notifier).state = UserModel.fromMap(res["data"][0]);
    ref.read(appSettingsProvider.notifier).state = AppSettingsModel.fromMap(
      res as Map<String, dynamic>,
    );
  } catch (e) {
    log("$e");
    rethrow;
  }
});

class AuthRepo {
  static Future<Map> login(String phone, String password) async {
    try {
      String? fcm = "";
      try {
        fcm = await FirebaseMessaging.instance.getToken();
      } catch (err) {
        fcm = "";
      }
      final res = await apiCallBack(
        path: "/login",
        body: {
          "phone_number": phone,
          "password": password,
          "token": "$fcm",
          "checked": "false",
        },
      );

      return res;
    } catch (e) {
      log("FCM: $e");
      rethrow;
    }
  }

  static Future<Map> register(Map<String, dynamic> body) async {
    try {
      final res = await apiCallBack(path: "/register_user", body: body);
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map> forgotPassword(String email) async {
    try {
      final res = await apiCallBack(path: "/forgot", body: {"email": email});
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map> sendOtp(String phone) async {
    try {
      final res = await apiCallBack(
        path: "/send_otp",
        body: {"phone_number": phone},
      );
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map> verifyOtp({
    required String phone,
    required String otp,
    required String token,
  }) async {
    try {
      final res = await apiCallBack(
        path: "/verify_otp",
        body: {
          "phone_number": phone,
          "otp_code": otp,
          "token": token,
          "checked": "false",
        },
      );
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map> changePassword(
    String oldPassword,
    String newPassword,
    String phone,
  ) async {
    try {
      final res = await apiCallBack(
        path: "/changepass",
        body: {
          "password": oldPassword,
          "new_password": newPassword,
          "phone_number": phone,
        },
      );
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map> editProfile(Map<String, dynamic> body) async {
    try {
      final res = await apiCallBack(path: "/edit_profile", body: body);
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> logout(BuildContext context, WidgetRef ref) async {
    try {
      await HiveConfig.clearBox();
      activePageNotifier.value = 0;
      ref.read(userProvider.notifier).state = null;
      context.go("/login");
    } catch (e) {
      rethrow;
    }
  }
}
