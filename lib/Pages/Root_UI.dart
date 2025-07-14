import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Essentials/KNavigationBar.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Pages/Chat/Chat_UI.dart';
import 'package:hello_captain_user/Pages/News/Saved_News_UI.dart';
import 'package:hello_captain_user/Pages/Orders/Orders_UI.dart';
import 'package:hello_captain_user/Pages/Profile/Profile_UI.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../Resources/colors.dart';
import '../Resources/commons.dart';
import 'Home/Home_UI.dart';

class Root_UI extends ConsumerStatefulWidget {
  const Root_UI({super.key});

  @override
  ConsumerState<Root_UI> createState() => _Root_UIState();
}

class _Root_UIState extends ConsumerState<Root_UI> {
  final List<Widget> _screens = [
    const Home_UI(),
    const Orders_UI(),
    const Saved_UI(),
    const Chat_UI(),
    const Profile_UI(),
  ];

  final List _navs = [
    {"label": "Home", "iconPath": "home", "index": 0},

    {"label": "Rides", "iconPath": "orders", "index": 1},

    {"label": "Saved", "iconPath": "heart", "index": 2},

    {"label": "Chat", "iconPath": "chat", "index": 3},

    {"label": "Profile", "iconPath": "profile", "index": 4},
  ];

  bool canPop = false;

  Future<void> onWillPop(bool didPop, result) async {
    setState(() {
      canPop = true;
    });
    KSnackbar(context, message: "Press back again to exit");

    await Future.delayed(Duration(seconds: 3), () {
      setState(() {
        canPop = false;
      });
    });
  }

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    systemColors();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: onWillPop,
      child: KScaffold(
        body: ValueListenableBuilder(
          valueListenable: activePageNotifier,
          builder: (context, activePage, _) {
            return PageTransitionSwitcher(
              transitionBuilder: (child, animation, secondaryAnimation) {
                return FadeThroughTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  fillColor: Kolor.scaffold,
                  child: child,
                );
              },
              child: _screens[activePage],
            );
          },
        ),
        bottomNavigationBar: KNavigationBar(navList: _navs),
      ),
    );
  }
}
