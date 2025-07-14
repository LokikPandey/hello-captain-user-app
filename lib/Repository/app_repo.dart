import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Helper/api_config.dart';

final privacyFuture = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    try {
      final res = await AppRepo.fetchPrivacy();
      if (res["code"] != "200") throw res["message"];
      ref.keepAlive();
      return res;
    } catch (e) {
      rethrow;
    }
  },
);

class AppRepo {
  static Future<Map<String, dynamic>> fetchLanguages() async {
    try {
      final res = await apiCallBack(path: "/user_language", method: "POST");

      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchPrivacy() async {
    try {
      final res = await apiCallBack(path: "/privacy", method: "POST");

      return res;
    } catch (e) {
      rethrow;
    }
  }
}
