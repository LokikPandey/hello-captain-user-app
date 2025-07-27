import 'dart:async';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hello_captain_user/Repository/mapBox_repo.dart';
import 'package:hello_captain_user/Components/KSearchbar.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Models/user_model.dart';
// import 'package:hello_captain_user/Providers/user_provider.dart';

class Search_Place_UI extends ConsumerStatefulWidget {
  const Search_Place_UI({super.key});

  @override
  ConsumerState<Search_Place_UI> createState() => _Search_Place_UIState();
}

class _Search_Place_UIState extends ConsumerState<Search_Place_UI> {
  final searchKey = TextEditingController();
  final isLoading = ValueNotifier(false);
  Timer? _debounce;
  bool isFetching = false;
  List<Map<String, dynamic>> addressList = [];

  @override
  void initState() {
    super.initState();
    searchPlace(); // Load recent searches initially
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        searchPlace();
      } else {
        mapboxSearch();
      }
    });
  }

  Future<void> mapboxSearch() async {
    setState(() => isFetching = true);
    final res = await MapboxRepo().searchPlace(searchKey.text);
    setState(() {
      addressList = res.map((e) => Map<String, dynamic>.from(e)).toList();
      isFetching = false;
    });
  }

  Future<void> searchPlace() async {
    try {
      setState(() => isFetching = true);

      final user = ref.read(userProvider);
      if (user == null) throw "User not found";

      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      final jar = PersistCookieJar(
        ignoreExpires: true,
        storage: FileStorage("${dir.path}/.cookies/"),
      );
      dio.interceptors.add(CookieManager(jar));

      final response = await dio.post(
        "https://app.hellocaptain.in/api/customerapi/get_recent_searches",
        data: {"user_id": user.id},
        options: Options(headers: {"Authorization": 'Basic YWJjZDo='}),
      );

      if (response.statusCode == 200 &&
          response.data['recent_searches'] is List) {
        final searches = response.data['recent_searches'] as List;
        setState(() {
          addressList =
              searches.map((e) {
                return {'description': e, 'place_id': e, 'isRecent': true};
              }).toList();
          isFetching = false;
        });
      } else {
        throw "Invalid response";
      }
    } catch (e) {
      print("Error fetching recent: $e");
      setState(() => isFetching = false);
    }
  }

  Future<void> addRecentSearch(String userId, String location) async {
    try {
      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      final jar = PersistCookieJar(
        ignoreExpires: true,
        storage: FileStorage("${dir.path}/.cookies/"),
      );
      dio.interceptors.add(CookieManager(jar));

      final response = await dio.post(
        "https://app.hellocaptain.in/api/customerapi/add_recent_search",
        data: {"user_id": userId, "location": location},
        options: Options(headers: {"Authorization": 'Basic YWJjZDo='}),
      );

      if (response.statusCode != 200) {
        throw "Failed to add recent search";
      }
    } catch (e) {
      print("Error adding recent search: $e");
    }
  }

  Future<void> getPlaceDetails(
    String placeId,
    String address, {
    bool isRecent = false,
  }) async {
    try {
      isLoading.value = true;

      final user = ref.read(userProvider);
      dynamic res;

      if (isRecent) {
        final searchResults = await MapboxRepo().searchPlace(address);
        if (searchResults.isEmpty) throw "No results found for $address";
        final firstResult = searchResults.first;
        final newPlaceId = firstResult['place_id'] ?? address;
        res = await MapboxRepo().placeDetails(newPlaceId, address);
      } else {
        res = await MapboxRepo().placeDetails(placeId, address);
      }

      if (user != null) {
        await addRecentSearch(user.id, address);
      }

      context.pop(res);
    } catch (e) {
      KSnackbar(context, message: "API Error: $e", error: true);
    } finally {
      isLoading.value = false;
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
                children: [
                  KSearchbar(
                    controller: searchKey,
                    hintText: "Where are you going?",
                    onClear: () {
                      searchKey.clear();
                      searchPlace();
                    },
                    onFieldSubmitted: (_) => mapboxSearch(),
                    onChanged: onSearchChanged,
                    isFetching: isFetching,
                  ),
                  const SizedBox(height: 8),
                  if (searchKey.text.isEmpty && addressList.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "Recent Searches",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) => div,
                itemCount: addressList.length,
                padding: const EdgeInsets.symmetric(
                  vertical: kPadding,
                ).copyWith(top: 0),
                itemBuilder: (context, index) {
                  final address = addressList[index];
                  final desc = address['description'] ?? 'Unknown';
                  final placeId =
                      address['place_id'] ?? desc.hashCode.toString();

                  return KCard(
                    onTap:
                        () => getPlaceDetails(
                          placeId,
                          desc,
                          isRecent: address['isRecent'] == true,
                        ),
                    color: Colors.white,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.history, color: Colors.white),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [Label(desc, fontSize: 16).title],
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
