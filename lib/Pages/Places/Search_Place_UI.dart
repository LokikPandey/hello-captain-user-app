import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Components/KSearchbar.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Repository/mapBox_repo.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

class Search_Place_UI extends StatefulWidget {
  const Search_Place_UI({super.key});

  @override
  State<Search_Place_UI> createState() => _Search_Place_UIState();
}

class _Search_Place_UIState extends State<Search_Place_UI> {
  final searchKey = TextEditingController();
  final isLoading = ValueNotifier(false);
  Timer? _debounce;
  bool isFetching = false;
  List addressList = [];

  void searchPlace() async {
    setState(() {
      isFetching = true;
    });

    final res = await MapboxRepo().searchPlace(searchKey.text);

    setState(() {
      addressList = res;
      isFetching = false;
    });
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        searchPlace();
      }
    });
  }

  Future<void> getPlaceDetails(String placeId, String address) async {
    try {
      isLoading.value = true;
      final res = await MapboxRepo().placeDetails(placeId, address);
      isLoading.value = false;
      context.pop(res);
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    } finally {
      if (mounted) isLoading.value = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KScaffold(
      isLoading: isLoading,
      appBar: KAppBar(context, title: "Search Place"),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(kPadding).copyWith(top: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  KSearchbar(
                    controller: searchKey,
                    hintText: "Search places, locality etc",
                    onClear: () {
                      searchKey.clear();
                      setState(() {
                        isFetching = false;
                      });
                    },
                    onFieldSubmitted: (val) {
                      searchPlace();
                    },
                    onChanged: onSearchChanged,
                    isFetching: isFetching,
                  ),
                  Label("Powered by MapBox").regular,
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) => div,
                itemCount: addressList.length,
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  vertical: kPadding,
                ).copyWith(top: 0),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final address = addressList[index];

                  return KCard(
                    onTap:
                        () => getPlaceDetails(
                          address['place_id'],
                          address['description'],
                        ),
                    color: Kolor.scaffold,
                    width: double.infinity,
                    child: Row(
                      spacing: 10,
                      children: [
                        // Icon(Icons.location_on),
                        CircleAvatar(child: Icon(Icons.location_on)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Label(
                                "${address["description"]}",
                                fontSize: 17,
                              ).title,
                              // if (address["properties"]["full_address"] != null)
                              //   Label(
                              //     "${address["properties"]["full_address"]}",
                              //   ).subtitle,
                              // Label(
                              //   "${address["properties"]["place_formatted"]}",
                              // ).subtitle,
                            ],
                          ),
                        ),
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
