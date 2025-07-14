import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Helper/api_config.dart';
import '../Helper/Location_Helper.dart';

final listRideFuture = FutureProvider.autoDispose.family<Map, String>((
  ref,
  serviceId,
) async {
  try {
    final myPos = await LocationService.getCurrentLocation();
    if (myPos == null) throw "Location unresolved";

    final res = await RideRepo.listRide({
      "latitude": myPos.latitude,
      "longitude": myPos.longitude,
      "service": serviceId,
    });

    return res;
  } catch (e) {
    rethrow;
  }
});

final locateDriverFuture = FutureProvider.autoDispose.family<Map, String>((
  ref,
  driverId,
) async {
  try {
    final res = await RideRepo.locateDriver(driverId: driverId);

    return res;
  } catch (e) {
    rethrow;
  }
});

class RideRepo {
  static Future<Map<String, dynamic>> listRide(
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await apiCallBack(path: "/list_ride", body: body);

      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> sendOrderRequest(
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await apiCallBack(path: "/request_transaksi", body: body);
      if (res['data'].isNotEmpty) return res;

      throw "Unable to place order!";
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> checkOrderRequest(
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await apiCallBack(
        path: "/check_status_transaksi",
        body: body,
      );

      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> validatePromocode(
    String serviceId,
    String promocode,
  ) async {
    try {
      final res = await apiCallBack(
        path: "/kodepromo",
        body: {"code": promocode, "service": serviceId},
      );

      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> locateDriver({
    required String driverId,
  }) async {
    try {
      final res = await apiCallBack(
        path: "/liat_lokasi_driver",
        body: {"id": driverId},
      );
      if (res['status'] != true) throw "Something Went Wrong!";
      return res;
    } catch (e) {
      throw "Api error - $e";
    }
  }
}
