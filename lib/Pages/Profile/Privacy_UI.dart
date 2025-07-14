import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Repository/app_repo.dart';
import 'package:hello_captain_user/Resources/commons.dart';

class Privacy_UI extends ConsumerWidget {
  const Privacy_UI({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyData = ref.watch(privacyFuture);

    return KScaffold(
      appBar: KAppBar(context, title: "Privacy Policy"),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: privacyData.when(
            data: (data) => Html(
              data: data["data"][0]["app_privacy_policy"],
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
