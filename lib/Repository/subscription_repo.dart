import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Helper/api_config.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';

final subscriptionListFuture = FutureProvider.autoDispose((ref) async {
  try {
    final res = await SubscriptionRepo.fetchSubscriptionList();
    return res;
  } catch (e) {
    rethrow;
  }
});

final activeSubscriptionFuture = FutureProvider.autoDispose((ref) async {
  try {
    final uid = ref.read(userProvider)?.id;
    if (uid == null) throw "User not logged in!";
    final res = await SubscriptionRepo.fetchActiveSubscription(uid);
    return res;
  } catch (e) {
    rethrow;
  }
});

class SubscriptionRepo {
  static Future<Map<String, dynamic>> fetchSubscriptionList() async {
    try {
      final res = await apiCallBack(path: "/getsubscriptionlist");

      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> purchase(
    String uid,
    String subscriptionId,
  ) async {
    try {
      final res = await apiCallBack(
        path: "/buySubscription",
        body: {"user_id": uid, "subscriptionId": subscriptionId},
      );

      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map> fetchActiveSubscription(String uid) async {
    try {
      final res = await apiCallBack(
        path: "/getPurchasedSubscriptions",
        body: {"user_id": uid},
      );
      // log("$res");
      if (res['data'] == null || res['data'].isEmpty) return {};
      return res['data'][0];
    } catch (e) {
      rethrow;
    }
  }
}
