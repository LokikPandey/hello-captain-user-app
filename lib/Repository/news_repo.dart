import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Helper/api_config.dart';
import 'package:hive_flutter/hive_flutter.dart';

final savedNewsFuture = FutureProvider.autoDispose((ref) async {
  try {
    final res = await NewsRepo.fetchSavedNews();

    return res;
  } catch (e) {
    rethrow;
  }
});

final allNewsFuture = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  try {
    ref.keepAlive();
    final res = await NewsRepo.fetchAllNews();
    return res;
  } catch (e) {
    rethrow;
  }
});

final newsDetailFuture = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
      try {
        final res = await NewsRepo.fetchNewsDetail(id);
        return res['data'][0];
      } catch (e) {
        rethrow;
      }
    });

class NewsRepo {
  static Future<Map<String, dynamic>> fetchAllNews() async {
    try {
      final res = await apiCallBack(path: '/all_berita', method: "POST");

      if (res['status'] != true) throw "Unable To Fetch News!";
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchNewsDetail(String id) async {
    try {
      final res = await apiCallBack(
        path: '/detail_berita',
        method: "POST",
        body: {"id": id},
      );

      if (res['status'] != true) throw "Unable To Fetch News!";
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<List> fetchSavedNews() async {
    try {
      final hiveBox = await Hive.openBox("hiveBox");
      final savedNews = await hiveBox.get("savedNews") as List?;

      return savedNews ?? [];
    } catch (e) {
      rethrow;
    }
  }
}
