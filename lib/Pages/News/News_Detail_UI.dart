import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: newsDetail.when(
        data:
            (data) => Column(
              children: [
                // Image header
                Stack(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.35,
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
                    Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),

                // Content section
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -30), // overlapping effect
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(kPadding),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                data['title'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Label(data['category']).subtitle,
                                ),
                                Label(
                                  kDateFormat(data['news_created']),
                                ).subtitle,
                              ],
                            ),
                            const Divider(height: 30),
                            Html(
                              data: data['content'],
                              style: {
                                "html": Style(
                                  fontSize: FontSize.medium,
                                  padding: HtmlPaddings.all(0),
                                ),
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        error: (e, _) => kNoData(subtitle: "$e Unable to load news."),
        loading: () => kSmallLoading,
      ),
    );
  }
}
