import 'dart:convert';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Helper/api_config.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../Helper/Location_Helper.dart';

final homeFuture = FutureProvider.autoDispose.family<Map, String>((
  ref,
  params,
) async {
  try {
    final data = jsonDecode(params);
    final myPos = await LocationService.getCurrentLocation();
    if (myPos == null) throw "Location not enabled!";

    data["latitude"] = myPos.latitude;
    data["longitude"] = myPos.longitude;
    final res = await HomeRepo.homeData(data);
    ref.keepAlive();
    if (res["code"] != "200") throw res["message"];
    ref
        .read(userProvider.notifier)
        .update(
          (state) => state?.copyWith(
            balance: parseToDouble(res["data"][0]["balance"]),
          ),
        );
    return res;
  } catch (e) {
    log("$e");
    throw "Server Busy! $e";
  }
});

final serviceDetailsProvider = StateProvider((ref) => []);

final serviceDataFuture = FutureProvider.autoDispose((ref) async {
  try {
    log("Srevice data fetching called responsible for driver icons");
    final res = await HomeRepo.serviceDetails();
    ref.read(serviceDetailsProvider.notifier).state = res;
    return res;
  } catch (e) {
    throw "Server Busy!";
  }
});

class HomeRepo {
  static Future<Map> homeData(Map<String, dynamic> body) async {
    try {
      final res = await apiCallBack(path: "/home", body: body);

      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<List> serviceDetails() async {
    try {
      // Open the Hive box
      final hiveBox = await Hive.openBox('hiveBox');
      final now = DateTime.now();

      // Check if key exists and if date is within current month
      if (hiveBox.containsKey('serviceDetails')) {
        final cached = hiveBox.get('serviceDetails');
        if (cached is Map &&
            cached.containsKey('data') &&
            cached.containsKey('date')) {
          final cachedDate = DateTime.tryParse(cached['date'] ?? '');
          if (cachedDate != null &&
              cachedDate.year == now.year &&
              cachedDate.month == now.month &&
              cachedDate.day == now.day) {
            // Return cached data
            // log("Returning cached service details");
            // log("${cached['data']}");

            return cached['data'];
          }
        }
      }

      // If not cached or cache is outdated, call API
      final res = await apiCallBack(path: "/detail_fitur", method: "GET");
      // log("Returning api service details");
      // log("${res['data']}");

      // Save to Hive with current date
      await hiveBox.put('serviceDetails', {
        'data': res["data"],
        'date': now.toIso8601String(),
      });

      return res['data'];
    } catch (e) {
      rethrow;
    }
  }
}
