import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kCarousel.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/constants.dart';

import '../Essentials/Label.dart';

class Welcome_UI extends StatefulWidget {
  const Welcome_UI({super.key});

  @override
  State<Welcome_UI> createState() => _Welcome_UIState();
}

class _Welcome_UIState extends State<Welcome_UI> {
  @override
  Widget build(BuildContext context) {
    return KScaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(kPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Label(
                      "Welcome Back to",
                      fontSize: 17,
                      textAlign: TextAlign.center,
                    ).regular,
                    Label(
                      "Hello Captain",
                      weight: 700,
                      fontSize: 25,
                      textAlign: TextAlign.center,
                    ).title,
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      KCarousel(
                        height: MediaQuery.of(context).size.height * .5,
                        isLooped: true,
                        children: [1, 2, 3]
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: kPadding),
                                child: SvgPicture.asset(
                                  "$kImagePath/welcome/$e.svg",
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(kPadding),
                child: KButton(
                  onPressed: () => context.go("/login"),
                  label: "Continue",
                  backgroundColor: Kolor.primary,
                  style: KButtonStyle.expanded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
