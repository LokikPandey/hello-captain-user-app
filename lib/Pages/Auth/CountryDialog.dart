import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Components/KSearchbar.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Resources/app-data.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

class CountryDialog extends StatefulWidget {
  const CountryDialog({super.key});

  @override
  State<CountryDialog> createState() => _CountryDialogState();
}

class _CountryDialogState extends State<CountryDialog> {
  final searchKey = TextEditingController();
  List<Map<String, dynamic>> filterList = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    countries.sort(
      (a, b) =>
          "${a["name"]}".toLowerCase().compareTo("${b["name"]}".toLowerCase()),
    );
    searchKey.addListener(whenSearching);
  }

  void whenSearching() {
    if (searchKey.text.isNotEmpty) {
      isSearching = true;
      var temp = List<Map<String, dynamic>>.from(countries);
      temp.retainWhere((element) {
        return element["name"]!.toLowerCase().contains(
          searchKey.text.toLowerCase(),
        );
      });

      temp.sort(
        (a, b) => "${a["name"]}".toLowerCase().compareTo(
          "${b["name"]}".toLowerCase(),
        ),
      );
      filterList = temp;
    } else {
      isSearching = false;
      filterList = countries;
    }
    setState(() {});
  }

  @override
  void dispose() {
    searchKey.removeListener(whenSearching);
    searchKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(kPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KSearchbar(controller: searchKey, hintText: "Search country"),
            height20,
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) => div,
                itemCount: isSearching ? filterList.length : countries.length,
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final country =
                      isSearching ? filterList[index] : countries[index];
                  return KCard(
                    onTap: () {
                      context.pop({"code": country["code"]});
                    },
                    color: Kolor.scaffold,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                    child: Row(
                      spacing: 12,
                      children: [
                        Label(country["emoji"]).regular,
                        Expanded(child: Label(country["name"] ?? "").regular),
                        Label(country["code"]).regular,
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
