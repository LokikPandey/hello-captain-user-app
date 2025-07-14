import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Helper/api_config.dart';
import 'package:hello_captain_user/Models/merchant_model.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Repository/ride_repo.dart';

final currentMerchantProvider = StateProvider<MerchantModel?>((ref) => null);

final listMerchantRidersFuture = FutureProvider.autoDispose.family<Map, String>(
  (ref, params) async {
    try {
      final data = jsonDecode(params);
      final res = await RideRepo.listRide({
        "latitude": data["latitude"],
        "longitude": data["longitude"],
        "service": data["serviceId"],
      });

      return res;
    } catch (e) {
      rethrow;
    }
  },
);

final categoryFuture = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, params) async {
      try {
        ref.keepAlive();
        final body = jsonDecode(params);

        final phone = ref.read(userProvider)?.phone_number;

        if (phone == null) throw "User not logged in!";

        final res = await PurchasingRepo.fetchAllCategories(
          body["serviceId"],
          body["lat"],
          body["lng"],
          phone,
        );

        return res;
      } catch (e) {
        rethrow;
      }
    });

final merchantFuture = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, params) async {
      try {
        final body = jsonDecode(params);

        final phone = ref.read(userProvider)?.phone_number;

        if (phone == null) throw "User not logged in!";

        final res = await PurchasingRepo.allMerchantByCategory(
          body["serviceId"],
          body["categoryId"],
          body["lat"],
          body["lng"],
          phone,
        );

        return res;
      } catch (e) {
        rethrow;
      }
    });

final merchantDetailFuture = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, params) async {
      try {
        final body = jsonDecode(params);

        final phone = ref.read(userProvider)?.phone_number;

        if (phone == null) throw "User not logged in!";

        final res = await PurchasingRepo.merchantById(
          body["merchantId"],
          body["lat"],
          body["lng"],
          phone,
        );

        return res;
      } catch (e) {
        rethrow;
      }
    });

final itemsFuture = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, params) async {
      try {
        final body = jsonDecode(params);

        final phone = ref.read(userProvider)?.phone_number;

        if (phone == null) throw "User not logged in!";

        final res = await PurchasingRepo.itemsByCategory(
          body["merchantId"],
          body["categoryId"],
          phone,
        );

        return res;
      } catch (e) {
        rethrow;
      }
    });

class PurchasingRepo {
  static Future<Map<String, dynamic>> fetchAllCategories(
    String serviceId,
    double lat,
    double lng,
    String phone,
  ) async {
    try {
      final res = await apiCallBack(
        path: "/allmerchant",
        body: {
          "service": serviceId,
          "latitude": lat,
          "longitude": lng,
          "phone_number": phone,
        },
      );
      if (res["code"] != "200") throw res["message"];
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> allMerchantByCategory(
    String serviceId,
    String categoryId,
    double lat,
    double lng,
    String phone,
  ) async {
    try {
      final res = await apiCallBack(
        path: "/allmerchantbykategori",
        body: {
          "service": serviceId,
          "category": categoryId,
          "latitude": lat,
          "longitude": lng,
          "phone_number": phone,
        },
      );
      if (res["code"] != "200") throw res["message"];
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> merchantById(
    String merchantId,
    double lat,
    double lng,
    String phone,
  ) async {
    try {
      final res = await apiCallBack(
        path: "/merchantbyid",
        body: {
          "idmerchant": merchantId,
          "latitude": lat,
          "longitude": lng,
          "phone_number": phone,
        },
      );

      if (res["code"] != "200") throw res["message"];
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> itemsByCategory(
    String merchantId,
    String categoryId,
    String phone,
  ) async {
    try {
      final res = await apiCallBack(
        path: "/itembykategori",
        body: {"id": merchantId, "category": categoryId, "phone_number": phone},
      );
      if (res["code"] != "200") throw res["message"];
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> buyCartItems(
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await apiCallBack(
        path: "/inserttransaksimerchant",
        body: body,
      );

      return res;
    } catch (e) {
      throw "Api error - $e";
    }
  }

  static Future<Map<String, dynamic>> acceptBid({
    required String transactionId,
    required String driverId,
    required int amount,
  }) async {
    try {
      // log(
      //   "${{"transaction_id": transactionId, "driver_id": driverId, "amount": amount}}",
      // );
      final res = await apiCallBack(
        path: "/accept",
        body: {
          "transaction_id": transactionId,
          "id": driverId,
          "amount": "$amount",
        },
      );

      return res;
    } catch (e) {
      throw "Api error - $e";
    }
  }
}
