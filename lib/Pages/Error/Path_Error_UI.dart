import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../Essentials/Label.dart';
import '../../Essentials/kButton.dart';
import '../../Resources/constants.dart';

class Path_Error_UI extends StatelessWidget {
  const Path_Error_UI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(kPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Label("Page Not Found!", fontSize: 30, weight: 700).title,
                Label(
                  "Sorry we cannot find the requested page!",
                  fontSize: 17,
                  weight: 500,
                  textAlign: TextAlign.center,
                ).subtitle,
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(kPadding),
          child: KButton(
            onPressed: () => context.go("/"),
            label: "Go Home",
          ),
        ),
      ),
    );
  }
}
