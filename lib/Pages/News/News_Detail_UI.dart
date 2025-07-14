import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Repository/news_repo.dart';
import 'package:hello_captain_user/Resources/app_config.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

class News_Detail_UI extends ConsumerWidget {
  final String newsId;
  const News_Detail_UI({super.key, required this.newsId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsDetail = ref.watch(newsDetailFuture(newsId));
    return KScaffold(
      appBar: KAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(kPadding),
          child: newsDetail.when(
            data:
                (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            "$newsImageBaseUrl/${data['news_images']}",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    height20,
                    Label(data['title']).title,
                    Row(
                      children: [
                        Expanded(child: Label((data['category'])).subtitle),
                        Label(kDateFormat(data['news_created'])).subtitle,
                      ],
                    ),
                    div,
                    Html(
                      data: data['content'],
                      style: {"html": Style(padding: HtmlPaddings.all(0))},
                    ),
                  ],
                ),
            error:
                (error, stackTrace) =>
                    kNoData(subtitle: "$error Unable To Load News."),
            loading: () => kSmallLoading,
          ),
        ),
      ),
    );
  }
}
