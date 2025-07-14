import 'dart:convert';
import 'package:hello_captain_user/Helper/api_config.dart';

class NotificationRepo {
  static Future<Map<String, dynamic>> sendNotification(
    String to,
    String title,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await apiCallBack(
        path: "/send_fcm",
        body: {
          'fcm_json': jsonEncode({
            "to": to,
            "data": {
              'title': title,
              'body': {"type": '1', ...body},
            },
          }),
        },
      );

      return res;
    } catch (e) {
      rethrow;
    }
  }
}
