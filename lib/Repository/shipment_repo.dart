import 'package:hello_captain_user/Helper/api_config.dart';

class ShipmentRepo {
  static Future<Map<String, dynamic>> orderShipment(
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await apiCallBack(
        path: "/request_transaksi_send",
        body: body,
      );
      return res;
    } catch (e) {
      rethrow;
    }
  }
}
