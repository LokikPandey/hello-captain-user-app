import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Helper/api_config.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';

final bankListFuture = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  ref.keepAlive();
  try {
    final res = await WalletRepo.fetchBankList();

    return (res['data'] as List).map((e) => e as Map<String, dynamic>).toList();
  } catch (e) {
    log("$e");
    rethrow;
  }
});

final walletFuture = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  try {
    final user = ref.read(userProvider);
    if (user == null) throw "User not logged in!";
    final res = await WalletRepo.fetchWallet(user.id);

    return res;
  } catch (e) {
    rethrow;
  }
});

final promoFuture = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  try {
    final res = await WalletRepo.fetchPromoList();
    return res;
  } catch (e) {
    rethrow;
  }
});

class WalletRepo {
  static Future<Map<String, dynamic>> withdraw(
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await apiCallBack(path: "/withdraw", body: body);
      if (res["code"] != "200") throw res["message"];
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchWallet(String userId) async {
    try {
      final res = await apiCallBack(path: "/wallet", body: {"id": userId});

      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchPromoList() async {
    try {
      final res = await apiCallBack(path: "/listkodepromo", method: 'POST');

      if (res["code"] != "200") throw res["message"];
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map> fetchBankList() async {
    try {
      final res = await apiCallBack(path: "/list_bank", method: "POST");
      if (res['data'] == null) throw "Something Went Wrong!";
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map> generatePidx(int amount, String userId) async {
    try {
      final res = await apiCallBack(
        path: "/createkhaltiorder",
        body: {"amount": amount, "id": userId},
      );
      if (res['code'] != 200) throw "Something Went Wrong!";
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map> verifyPayment(String pidx) async {
    try {
      final res = await apiCallBack(path: "/topupkhalti", body: {"pidx": pidx});
      // log("$res");
      if (res['code'] != 200) throw res['message'];
      return res;
    } catch (e) {
      rethrow;
    }
  }
}
