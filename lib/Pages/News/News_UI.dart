import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Repository/news_repo.dart';
import 'package:hello_captain_user/Resources/app_config.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

class News_UI extends ConsumerWidget {
  const News_UI({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsData = ref.watch(allNewsFuture);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(allNewsFuture.future),
      child: KScaffold(
        appBar: KAppBar(context, title: "News"),
        body: SafeArea(
          child: newsData.when(
            data:
                (data) => ListView.separated(
                  physics: AlwaysScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => div,
                  itemCount: (data['data'] as List).length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final news = data['data'][index];
                    return InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(kPadding),
                        child: Row(
                          spacing: 20,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: kRadius(10),
                                color: Kolor.card,
                                image: DecorationImage(
                                  image: NetworkImage(
                                    "$newsImageBaseUrl/${news['news_images']}",
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Label(
                                    "${news['title']}".replaceAll(
                                      RegExp(r'<[^>]*>'),
                                      '',
                                    ),
                                    fontSize: 17,
                                  ).title,
                                  Label(
                                    "${news['content']}".replaceAll(
                                      RegExp(r'<[^>]*>'),
                                      '',
                                    ),
                                  ).subtitle,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            error:
                (error, stackTrace) =>
                    Center(child: kNoData(subtitle: "Unable To Fetch News!")),
            loading: () => kSmallLoading,
          ),
        ),
      ),
    );
  }
}
