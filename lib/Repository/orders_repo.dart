import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Helper/api_config.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';

final ordersHistoryFuture = FutureProvider.autoDispose((ref) async {
  try {
    final userId = ref.read(userProvider)?.id;
    if (userId == null) throw "User not logged in!";
    final res = await OrdersRepo.orderHistory(userId);
    return res;
  } catch (e) {
    rethrow;
  }
});

final orderDetailFuture = FutureProvider.autoDispose.family<Map, String>((
  ref,
  params,
) async {
  try {
    final body = jsonDecode(params);
    final res = await OrdersRepo.fetchOrderDetail(
      driverId: body['driverId'],
      transactionId: body['transactionId'],
    );
    return res;
  } catch (e) {
    rethrow;
  }
});

class OrdersRepo {
  static Future<Map> orderHistory(String userId) async {
    try {
      final res = await apiCallBack(
        path: "/history_progress",
        body: {"id": userId},
      );

      if (res["status"] != true) throw "Something Went Wrong!";
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map> fetchOrderDetail({
    required String transactionId,
    required String driverId,
  }) async {
    try {
      final res = await apiCallBack(
        path: "/detail_transaksi",
        body: {"id": transactionId, "driver_id": driverId},
      );
      if (res["status"] != true) throw "Something Went Wrong!";
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map> shareRatings({required Map<String, dynamic> body}) async {
    try {
      final res = await apiCallBack(path: "/rate_driver", body: body);

      return res;
    } catch (e) {
      rethrow;
    }
  }

    static Future<Map> cancelOrder({required Map<String, dynamic> body}) async {
    try {
      final res = await apiCallBack(
        path: "/cancel_order",
        body: body,
      );

      return res;
    } catch (e) {
      rethrow;
    }
  }
}
