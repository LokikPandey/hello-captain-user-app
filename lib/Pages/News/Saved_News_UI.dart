// ignore_for_file: unused_result

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Helper/hive_config.dart';
import 'package:hello_captain_user/Repository/news_repo.dart';
import 'package:hello_captain_user/Resources/app_config.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class Saved_UI extends ConsumerStatefulWidget {
  const Saved_UI({super.key});

  @override
  ConsumerState<Saved_UI> createState() => _Saved_UIState();
}

class _Saved_UIState extends ConsumerState<Saved_UI> {
  Future<void> removeSaved(String newsId) async {
    try {
      final hiveBox = await Hive.openBox("hiveBox");
      List savedNews = hiveBox.get("savedNews") ?? [];

      savedNews.removeWhere((element) => element['news_id'] == newsId);
      await HiveConfig.setData("savedNews", savedNews);
      await ref.refresh(savedNewsFuture.future);
      KSnackbar(context, message: "News removed!");
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedNewsData = ref.watch(savedNewsFuture);
    return KScaffold(
      appBar: KAppBar(context, title: "Saved", showBack: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(kPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              savedNewsData.when(
                data:
                    (data) =>
                        data.isNotEmpty
                            ? ListView.separated(
                              separatorBuilder: (context, index) => height15,
                              shrinkWrap: true,
                              itemCount: data.length,
                              itemBuilder:
                                  (context, index) => KCard(
                                    onTap:
                                        () => context.push(
                                          "/news-detail/${data[index]['news_id']}",
                                        ),
                                    child: Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              height: 170,
                                              decoration: BoxDecoration(
                                                borderRadius: kRadius(10),
                                                image: DecorationImage(
                                                  fit: BoxFit.cover,
                                                  image: NetworkImage(
                                                    "$newsImageBaseUrl/${data[index]['news_images']}",
                                                  ),
                                                ),
                                              ),
                                            ),
                                            height10,
                                            Label(
                                              "${data[index]['title']}"
                                                  .replaceAll(
                                                    RegExp(r'<[^>]*>'),
                                                    '',
                                                  ),
                                              fontSize: 17,
                                              maxLines: 1,
                                            ).title,
                                            Label(
                                              "${data[index]['content']}"
                                                  .replaceAll(
                                                    RegExp(r'<[^>]*>'),
                                                    '',
                                                  ),
                                              fontSize: 12,
                                              maxLines: 2,
                                            ).subtitle,
                                          ],
                                        ),
                                        IconButton(
                                          onPressed:
                                              () => removeSaved(
                                                data[index]["news_id"],
                                              ),
                                          icon: Icon(
                                            Icons.favorite,
                                            color: Kolor.tertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            )
                            : kNoData(
                              title: "No Saved News!",
                              subtitle: "All saved news will appear here.",
                            ),
                error: (error, stackTrace) => kNoData(subtitle: "$error"),
                loading: () => dummy(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Skeletonizer dummy() {
    return Skeletonizer(
      child: Column(
        children: List.generate(
          5,
          (index) =>
              Skeleton.leaf(child: KCard(width: double.infinity, height: 100)),
        ),
      ),
    );
  }
}
