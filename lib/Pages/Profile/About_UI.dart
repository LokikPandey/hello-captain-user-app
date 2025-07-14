import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';

import '../../Essentials/Label.dart';
import '../../Repository/app_repo.dart';
import '../../Resources/commons.dart';

class About_UI extends ConsumerWidget {
  const About_UI({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyData = ref.watch(privacyFuture);

    return KScaffold(
      appBar: KAppBar(context, title: "About Us"),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: privacyData.when(
            data: (data) => Html(
              data: data["data"][0]["app_aboutus"],
            ),
            error: (error, stackTrace) => Label("$error").regular,
            loading: () => Center(
              child: kSmallLoading,
            ),
          ),
        ),
      ),
    );
  }
}
