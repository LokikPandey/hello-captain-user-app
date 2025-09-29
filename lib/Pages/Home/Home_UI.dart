// lib/UI/Home_UI.dart

// ignore_for_file: unused_result, non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Components/Category_Tile.dart';
import 'package:hello_captain_user/Components/News_Card.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Essentials/kCarousel.dart';
import 'package:hello_captain_user/Helper/Location_Helper.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Repository/home_repo.dart';
import 'package:hello_captain_user/Repository/news_repo.dart';
import 'package:hello_captain_user/Resources/app_config.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:geolocator/geolocator.dart' as geo; // Added this import
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; // Added this import
// ignore_for_file: unused_result

// import 'dart:async';
// import 'dart:developer';
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:go_router/go_router.dart';
// import 'package:hello_captain_user/Essentials/KScaffold.dart';
// import 'package:hello_captain_user/Essentials/Label.dart';
// import 'package:hello_captain_user/Essentials/kButton.dart';
// import 'package:hello_captain_user/Essentials/kCard.dart';
// import 'package:hello_captain_user/Essentials/kField.dart';
// import 'package:hello_captain_user/Helper/Location_Helper.dart';
// import 'package:hello_captain_user/Models/driver_model.dart';
// import 'package:hello_captain_user/Repository/auth_repo.dart';
// import 'package:hello_captain_user/Repository/home_repo.dart';
import 'package:hello_captain_user/Repository/mapBox_repo.dart';
// import 'package:hello_captain_user/Repository/notification_repo.dart';
// import 'package:hello_captain_user/Repository/purchasing_repo.dart';
// import 'package:hello_captain_user/Repository/ride_repo.dart';
// import 'package:hello_captain_user/Repository/subscription_repo.dart';
// import 'package:hello_captain_user/Resources/colors.dart';
// import 'package:hello_captain_user/Resources/commons.dart';
// import 'package:hello_captain_user/Resources/constants.dart';
// import 'package:location/location.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart' as geo;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:simple_shadow/simple_shadow.dart';
// import 'package:skeletonizer/skeletonizer.dart';


final topRidersProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = Dio();
  try {
    const url = 'https://app.hellocaptain.in/api/driver/top_ranked_riders';
    final response = await dio.get(url);
    if (response.statusCode == 200 && response.data['code'] == '200') {
      return response.data['data']['top_drivers'] as List<dynamic>;
    } else {
      throw Exception('API returned an error: ${response.data['message']}');
    }
  } catch (e) {
    log('Failed to fetch top riders: $e');
    throw Exception('Could not connect to the server to get top riders.');
  }
});

class Home_UI extends ConsumerStatefulWidget {
  const Home_UI({super.key});

  @override
  ConsumerState<Home_UI> createState() => _Home_UIState();
}

class _Home_UIState extends ConsumerState<Home_UI> {
  Map<String, dynamic>? pickupAddressData;
  Map<String, dynamic>? dropAddressData;
  bool isFetchingLocation = false;

  Future<void> _refresh() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    final homeApiData = jsonEncode({
      "id": user.id,
      "latitude": 0,
      "longitude": 0,
      "phone_number": user.phone_number,
    });
    ref.refresh(allNewsFuture.future);
    ref.refresh(topRidersProvider.future);
    await ref.refresh(homeFuture(homeApiData).future);
    await ref.refresh(serviceDataFuture.future);
  }

  Future<void> _searchDropLocation() async {
    setState(() {
      isFetchingLocation = true;
    });

    try {
      final myPos = await LocationService.getCurrentLocation();
      if (myPos == null) {
        throw "Could not fetch your current location. Please ensure location services are enabled.";
      }

      // **MODIFIED:** Perform reverse geocoding to get the actual address
      final addressData = await MapboxRepo.getAddressFromCoordinates(
        Position(myPos.longitude, myPos.latitude),
      );

      if (addressData != null) {
        pickupAddressData = {
          "address": addressData['address'], // Use the real address
          "lat": myPos.latitude,
          "lng": myPos.longitude,
        };
      } else {
        // Fallback if reverse geocoding fails
        pickupAddressData = {
          "address": "${myPos.latitude.toStringAsFixed(6)}, ${myPos.longitude.toStringAsFixed(6)}",
          "lat": myPos.latitude,
          "lng": myPos.longitude,
        };
      }

      final res = await context.push("/search-place") as Map<String, dynamic>?;

      if (res != null) {
        setState(() {
          dropAddressData = res;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          isFetchingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return KScaffold(body: Center(child: CircularProgressIndicator()));
    }

    final homeApiData = jsonEncode({
      "id": user.id,
      "latitude": 0,
      "longitude": 0,
      "phone_number": user.phone_number,
    });
    final homeData = ref.watch(homeFuture(homeApiData));

    return RefreshIndicator(
      onRefresh: _refresh,
      child: KScaffold(
        appBar: AppBar(
          surfaceTintColor: const Color.fromARGB(255, 255, 242, 220),
          automaticallyImplyLeading: false,
          title: Image.asset(
            "$kImagePath/h_c_logoo.png",
            height: 200,
            fit: BoxFit.contain,
          ),
          backgroundColor: const Color(0xFFFFF5E5),
          actions: [
            const Icon(Icons.account_balance_wallet_outlined),
            width5,
            Label(
              homeData.when(
                data: (data) => kCurrencyFormat(user.balance),
                error: (error, stackTrace) => "-",
                loading: () => "...",
              ),
              weight: 800,
            ).regular,
            width20,
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchSection(),
                homeData.when(
                  data:
                      (data) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFFFAF0),
                              Color.fromARGB(255, 255, 242, 220),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(16),
                            ),
                            child: SizedBox(
                              height: 200,
                              child: KCarousel(
                                isLooped: true,
                                showIndicator: false,
                                children:
                                    (data["slider"] as List)
                                        .map(
                                          (e) => GestureDetector(
                                            onTap: () async {
                                              try {
                                                final promotionType =
                                                    e['promotion_type']
                                                        ?.toString();
                                                final hardcodedUrl =
                                                    'http://dynamic-link-two.vercel.app';

                                                if (promotionType ==
                                                    'service') {
                                                  final title =
                                                      e['title']?.toString() ??
                                                      '';
                                                  final service =
                                                      e['service']
                                                          ?.toString() ??
                                                      '';
                                                  final icon =
                                                      e['icon']?.toString() ??
                                                      '';

                                                  String path = "";
                                                  switch (title) {
                                                    case "Passenger Transportation":
                                                      path =
                                                          "/passenger-transportation";
                                                      break;
                                                    case "Rental":
                                                      path = "/rental";
                                                      break;
                                                    case "Shipment":
                                                      path = "/shipment";
                                                      break;
                                                    case "Purchasing Service":
                                                      path =
                                                          "/purchasing-service";
                                                      break;
                                                    default:
                                                      log(
                                                        "Unknown service title: $title",
                                                      );
                                                      return;
                                                  }

                                                  context.push(
                                                    path,
                                                    extra: {
                                                      ...e
                                                          as Map<
                                                              String,
                                                              dynamic>,
                                                      "serviceName": service,
                                                      "serviceImage":
                                                          "$serviceImageBaseUrl/$icon",
                                                    },
                                                  );
                                                } else {
                                                  final uri = Uri.parse(
                                                    hardcodedUrl,
                                                  );
                                                  if (await canLaunchUrl(uri)) {
                                                    await launchUrl(
                                                      uri,
                                                      mode:
                                                          LaunchMode
                                                              .externalApplication,
                                                    );
                                                  } else {
                                                    log(
                                                      "Could not launch $hardcodedUrl",
                                                    );
                                                  }
                                                }
                                              } catch (err, stack) {
                                                log(
                                                  "Error in onTap: $err\n$stack",
                                                );
                                              }
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                    "$promoImageBaseUrl/${e["photo"]}",
                                                  ),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                  error:
                      (error, stackTrace) => SizedBox(
                        child: KCard(
                          height: 200,
                          width: double.infinity,
                          radius: 0,
                          child: Center(
                            child: Icon(
                              Icons.photo,
                              color: Kolor.hint,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                  loading:
                      () => Skeletonizer(
                        child: Skeleton.leaf(
                          child: const KCard(
                            height: 200,
                            width: double.infinity,
                            radius: 0,
                          ),
                        ),
                      ),
                  skipLoadingOnRefresh: false,
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFFAF0), Color(0xFFFFF2DC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Image.asset(
                      'assets/images/6.png',
                      width: double.infinity,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    homeData.when(
                      data:
                          (data) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFFAF0), Color(0xFFFFF2DC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: SizedBox(
                              height: 170,
                              child: Stack(
                                children: [
                                  Center(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          ...List.generate(
                                            (data["service"] as List)
                                                .take(5)
                                                .length,
                                            (index) {
                                              final category =
                                                  (data["service"]
                                                          as List)[index];
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 5,
                                                ),
                                                child: SizedBox(
                                                  width: 125,
                                                  height: 150,
                                                  child: CategoryTile(
                                                    index: index,
                                                    data:
                                                        category
                                                            as Map<
                                                                String,
                                                                dynamic>,
                                                    type: category["title"],
                                                    id: "${category["id"]}",
                                                    label: category["service"],
                                                    image:
                                                        "$serviceImageBaseUrl/${category["icon"]}",
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 5,
                                            ),
                                            child: Transform.translate(
                                              offset: const Offset(0, -20),
                                              child: SizedBox(
                                                width: 100,
                                                height: 100,
                                                child: _more(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      error:
                          (error, stackTrace) => Stack(
                            alignment: Alignment.center,
                            children: [
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                physics: const NeverScrollableScrollPhysics(),
                                children: List.generate(
                                  6,
                                  (index) => const KCard(
                                    margin: EdgeInsets.all(10),
                                    height: 120,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                              SimpleShadow(
                                sigma: 30,
                                opacity: .3,
                                child: Column(
                                  children: [
                                    Label("Oops!", weight: 900).regular,
                                    Label("$error").regular,
                                    height10,
                                    KButton(
                                      onPressed: () async {
                                        await _refresh();
                                      },
                                      label: "Retry",
                                      radius: 5,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      loading:
                          () => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFFAF0), Color(0xFFFFF2DC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              physics: const NeverScrollableScrollPhysics(),
                              children: List.generate(
                                3,
                                (index) => Skeletonizer(
                                  child: Skeleton.leaf(
                                    enabled: true,
                                    child: const KCard(
                                      margin: EdgeInsets.all(10),
                                      height: 60,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      skipLoadingOnRefresh: false,
                    ),
                    _buildTopRidersSection(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFFAF0), Color(0xFFFFF2DC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kPadding,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Label(
                                  "Famous Locations in Nepal",
                                  fontSize: 16,
                                  color: const Color.fromARGB(255, 231, 140, 3),
                                  weight: 900,
                                ).regular,
                                TextButton(
                                  onPressed: () => context.push("/all-news"),
                                  child:
                                      Label(
                                        "View All",
                                        color: Color.fromARGB(255, 121, 74, 2),
                                      ).regular,
                                ),
                              ],
                            ),
                          ),
                        ),
                        newsSection(),
                        Container(
                          height: 50,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFFAF0), Color(0xFFFFF2DC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFFAF0), Color(0xFFFFF2DC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(kPadding),
      child: Row(
        children: [
          Expanded(child: _locationInputWidget()),
          width10,
          SizedBox(
            height: 55,
            width: 55,
            child: ElevatedButton(
              onPressed:
                  isFetchingLocation || dropAddressData == null
                      ? null
                      : () {
                          context.push(
                            "/passenger-transportation-2",
                            extra: {
                              "initialPickup": pickupAddressData,
                              "initialDrop": dropAddressData,
                            },
                          );
                        },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 112, 35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: EdgeInsets.zero,
              ),
              child:
                  isFetchingLocation
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 112, 112, 112),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRidersSection() {
    return Consumer(
      builder: (context, ref, child) {
        final topRidersData = ref.watch(topRidersProvider);
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFAF0), Color(0xFFFFF2DC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(kPadding, 10, kPadding, 10),
                child:
                    Label(
                      "Top Ranked Riders",
                      fontSize: 16,
                      color: const Color.fromARGB(255, 231, 140, 3),
                      weight: 900,
                    ).regular,
              ),
              topRidersData.when(
                data: (riders) {
                  if (riders.isEmpty) {
                    return const SizedBox(
                      height: 60,
                      child: Center(child: Text("No top riders found.")),
                    );
                  }
                  return _TopRidersCarousel(riders: riders);
                },
                error:
                    (error, stackTrace) => SizedBox(
                      height: 60,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kPadding,
                        ),
                        child: KCard(
                          child: Center(
                            child: Text(
                              "Could not load top riders.",
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ),
                      ),
                    ),
                loading:
                    () => SizedBox(
                      height: 60,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kPadding,
                        ),
                        child: Skeletonizer(
                          child: Skeleton.leaf(
                            child: KCard(width: double.infinity),
                          ),
                        ),
                      ),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _locationInputWidget() {
    return KCard(
      onTap: _searchDropLocation,
      borderWidth: 1,
      height: 55,
      color: Kolor.scaffold,
      child: Row(
        spacing: 15,
        children: [
          const Icon(
            Icons.search,
            size: 27,
            color: Color.fromARGB(255, 255, 89, 0),
          ),
          Expanded(
            child:
                (dropAddressData == null)
                    ? Label("Where to?", fontSize: 15).title
                    : Text(
                        dropAddressData!["address"],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
          ),
        ],
      ),
    );
  }

  KCard _more(BuildContext context) {
    return KCard(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => catgeoryModal(),
        );
      },
      margin: const EdgeInsets.all(10),
      height: 100,
      width: 100,
      radius: 50,
      color: Colors.white,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Kolor.scaffold,
            child: Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          ),
        ],
      ),
    );
  }

  Widget catgeoryModal() {
    return Consumer(
      builder: (context, ref, _) {
        final user = ref.watch(userProvider);
        if (user == null) return const Center(child: Text("Please log in."));

        final homeData = ref.watch(
          homeFuture(
            jsonEncode({
              "id": user.id,
              "latitude": 0,
              "longitude": 0,
              "phone_number": user.phone_number,
            }),
          ),
        );
        return SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Kolor.scaffold,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(kPadding),
                    child: Label("Our Services").title,
                  ),
                  MasonryGridView(
                    gridDelegate:
                        const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      ...homeData.when(
                        data: (data) {
                          return List.generate(
                            (data["allfitur"] as List).length,
                            (index) {
                              final category = data["allfitur"][index];
                              return CategoryTile(
                                index: index,
                                data: category as Map<String, dynamic>,
                                id: "${category["id"]}",
                                label: category["service"],
                                image:
                                    "$serviceImageBaseUrl/${category["icon"]}",
                                type: category["title"],
                              );
                            },
                          );
                        },
                        error: (error, stackTrace) => [const SizedBox()],
                        loading:
                            () => List.generate(
                              6,
                              (index) => const KCard(
                                margin: EdgeInsets.all(10),
                                height: 120,
                                width: double.infinity,
                              ),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget newsSection() {
    return Consumer(
      builder: (context, ref, child) {
        final savedNewsData = ref.watch(savedNewsFuture);
        final newsData = ref.watch(allNewsFuture);
        ref.watch(serviceDataFuture);

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFAF0), Color(0xFFFFF2DC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: newsData.when(
            data:
                (data) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        (data['data'] as List)
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width / 2 -
                                      15,
                                  child: NewsCard(
                                    data: e,
                                    isSaved: (savedNewsData.value ?? []).any(
                                      (element) =>
                                          element["news_id"] == e["news_id"],
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
            error:
                (error, stackTrace) =>
                    Center(child: kNoData(subtitle: "Unable To Fetch News!")),
            loading:
                () => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        [1, 2]
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Skeletonizer(
                                  child: Skeleton.leaf(
                                    child: KCard(
                                      height: 150,
                                      width:
                                          MediaQuery.of(context).size.width /
                                              2 -
                                              24,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
          ),
        );
      },
    );
  }
}

class _TopRidersCarousel extends StatefulWidget {
  final List<dynamic> riders;
  const _TopRidersCarousel({required this.riders});

  @override
  State<_TopRidersCarousel> createState() => __TopRidersCarouselState();
}

class __TopRidersCarouselState extends State<_TopRidersCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.riders.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
        if (_currentPage < widget.riders.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeIn,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> rankColors = [
      const Color(0xFFFFF3B5), // Gold
      const Color(0xFFF1F1F1), // Silver
      const Color(0xFFFCE1C5), // Bronze
      const Color(0xFFE9F8F1), // Green
      const Color(0xFFEAF6FE), // Blue
    ];

    return SizedBox(
      height: 60,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.riders.length,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          final rider = widget.riders[index];
          final cardColor = rankColors[index % rankColors.length];
          final ratingValue =
              double.tryParse(rider['rating'].toString()) ?? 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: kPadding),
            child: KCard(
              color: cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withOpacity(0.7),
                    child: const Icon(
                      Icons.person_outline,
                      color: Kolor.primary,
                      size: 24,
                    ),
                  ),
                  width10,
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rider['driver_name'] ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        RatingBarIndicator(
                          rating: ratingValue,
                          itemBuilder:
                              (context, index) =>
                                  const Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 14.0,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "#${index + 1}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Kolor.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}