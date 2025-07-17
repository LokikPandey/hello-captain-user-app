// ignore_for_file: unused_result

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Helper/hive_config.dart';
import 'package:hello_captain_user/Repository/news_repo.dart';
import 'package:hello_captain_user/Resources/app_config.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../Essentials/Label.dart';
import '../Resources/colors.dart';
import '../Resources/commons.dart';

class NewsCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  final bool isSaved;
  const NewsCard({super.key, required this.data, required this.isSaved});

  Future<void> saveNews(
    BuildContext context,
    WidgetRef ref, {
    required Map newsData,
  }) async {
    try {
      final hiveBox = await Hive.openBox("hiveBox");

      List savedNews = hiveBox.get("savedNews") ?? [];

      savedNews.removeWhere(
        (element) => element['news_id'] == newsData['news_id'],
      );
      savedNews.add(newsData);
      await HiveConfig.setData("savedNews", savedNews);
      ref.refresh(allNewsFuture.future);
      KSnackbar(context, message: "News Saved");
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push("/news-detail/${data['news_id']}"),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Kolor.border),
              borderRadius: kRadius(10),
            ),
            clipBehavior: Clip.hardEdge,
            constraints: const BoxConstraints(maxWidth: 250),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        "$newsImageBaseUrl/${data['news_images']}",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFFFEFB), // Very light top
                        Color.fromARGB(255, 246, 239, 227), // Slightly deeper bottom
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Label(
                        "${data['title']}".replaceAll(RegExp(r'<[^>]*>'), ''),
                        fontSize: 17,
                        maxLines: 1,
                      ).title,
                      Label(
                        "${data['content']}\n".replaceAll(
                          RegExp(r'<[^>]*>'),
                          '',
                        ),
                        fontSize: 12,
                        maxLines: 2,
                      ).subtitle,
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => saveNews(context, ref, newsData: data),
            icon: Icon(
              Icons.favorite,
              color: isSaved ? Kolor.tertiary : Kolor.fadeText,
            ),
          ),
        ],
      ),
    );
  }
}
