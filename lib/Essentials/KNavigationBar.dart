import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../Resources/colors.dart';
import '../Resources/constants.dart';
import 'Label.dart';
import 'kCard.dart';

ValueNotifier activePageNotifier = ValueNotifier(0);

class KNavigationBar extends StatelessWidget {
  final List navList;
  String get navIconPath => "$kIconPath/navigation";
  const KNavigationBar({super.key, required this.navList});

  @override
  Widget build(BuildContext context) {
    return KCard(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 5,
      ).copyWith(bottom: 10),
      color: const Color.fromARGB(
        255,
        255,
        230,
        203,
      ), // Light pastel orange background
      radius: 0,
      child: SafeArea(
        child: Row(
          spacing: 5,
          children:
              navList
                  .map(
                    (e) => btn(
                      iconPath: e['iconPath'],
                      index: e['index'],
                      label: e['label'],
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget btn({
    required String iconPath,
    required int index,
    required String label,
  }) {
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: activePageNotifier,
        builder: (context, activePage, _) {
          final selected = activePage == index;

          final Color activeColor = Colors.white;
          final Color inactiveColor = const Color.fromARGB(
            255,
            237,
            123,
            8,
          ); // Dark orange

          return InkWell(
            onTap: () {
              activePageNotifier.value = index;
            },
            child: Column(
              spacing: 7,
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  selected
                      ? "$navIconPath/$iconPath-filled.svg"
                      : "$navIconPath/$iconPath.svg",
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    selected ? activeColor : inactiveColor,
                    BlendMode.srcIn,
                  ),
                ),
                Label(
                  label,
                  weight: selected ? 700 : 600,
                  color: selected ? activeColor : inactiveColor,
                  fontSize: 13,
                ).regular,
              ],
            ),
          );
        },
      ),
    );
  }
}
