// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Resources/colors.dart';
import '../Resources/commons.dart';
import '../Resources/constants.dart';
import 'Label.dart';
import 'kCard.dart';

// ignore: must_be_immutable
class KScaffold extends StatelessWidget {
  PreferredSizeWidget? appBar;
  final Widget body;
  FloatingActionButtonLocation? floatingActionButtonLocation;
  FloatingActionButtonAnimator? floatingActionButtonAnimator;
  Widget? floatingActionButton;
  Widget? bottomNavigationBar;
  ValueListenable<dynamic>? isLoading;
  List<Widget>? persistentFooterButtons;
  KScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.isLoading,
    this.floatingActionButtonAnimator,
    this.floatingActionButtonLocation,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.persistentFooterButtons,
  });

  @override
  Widget build(BuildContext context) {
    systemColors();
    return Scaffold(
      backgroundColor: Kolor.scaffold,
      body: ValueListenableBuilder(
        valueListenable: isLoading ?? ValueNotifier(false),
        builder: (context, loading, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // MAIN LAYOUT
              Scaffold(
                backgroundColor: Kolor.scaffold,
                persistentFooterButtons: persistentFooterButtons,
                appBar: appBar,
                body: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFFF8F2),
                        Color(0xFFFFF2DC),
                      ], // subtle pastel gradient
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(child: body),
                ),
                floatingActionButtonAnimator: floatingActionButtonAnimator,
                floatingActionButtonLocation: floatingActionButtonLocation,
                floatingActionButton: floatingActionButton,
                bottomNavigationBar: bottomNavigationBar,
              ),

              // LOADING OVERLAY
              _fullLoading(isLoading: loading),
            ],
          );
        },
      ),
    );
  }

  AnimatedSwitcher _fullLoading({required bool isLoading}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 200),
      child:
          isLoading
              ? Container(
                height: double.maxFinite,
                width: double.maxFinite,
                color: kOpacity(Kolor.scaffold, .8),
                child: Center(
                  child: KCard(
                    width: 300,
                    color: Colors.transparent,
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      spacing: 30,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            backgroundColor: kOpacity(Kolor.scaffold, .1),
                            color: Colors.black,
                          ),
                        ),
                        Label(
                          "Please Wait",
                          fontSize: 17,
                          weight: 550,
                          color: Colors.black,
                        ).title,
                      ],
                    ),
                  ),
                ),
              )
              : const SizedBox(),
    );
  }
}

AppBar KAppBar(
  BuildContext context, {
  IconData? icon,
  String title = "",
  Widget? child,
  bool showBack = true,
  List<Widget>? actions,
}) {
  final currentPath = GoRouterState.of(context).uri.toString();

  final bool isOrderDetailPage = currentPath.startsWith("/order-detail/");

  return AppBar(
    backgroundColor: const Color(0xFFFFF2DC),
    automaticallyImplyLeading: false,
    titleSpacing: showBack ? 0 : kPadding,
    leadingWidth: 50,
    surfaceTintColor: Colors.transparent,
    leading:
        showBack
            ? Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.deepOrange,
                ),
              ),
            )
            : null,
    title:
        child ??
        Label(title, fontSize: 20, weight: 800, color: Colors.deepOrange).title,
    actions: [
      ...(actions ?? []),
      if (isOrderDetailPage)
        IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home, color: Colors.deepOrange),
        ),
    ],
  );
}
