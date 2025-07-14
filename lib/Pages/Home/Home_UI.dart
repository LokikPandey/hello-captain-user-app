// ignore_for_file: unused_result

import 'dart:convert';
import 'package:flutter/material.dart';
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
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Repository/home_repo.dart';
import 'package:hello_captain_user/Repository/news_repo.dart';
import 'package:hello_captain_user/Resources/app_config.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:skeletonizer/skeletonizer.dart';

class Home_UI extends ConsumerStatefulWidget {
  const Home_UI({super.key});

  @override
  ConsumerState<Home_UI> createState() => _Home_UIState();
}

class _Home_UIState extends ConsumerState<Home_UI> {
  Future<void> _refresh() async {
    final homeApiData = jsonEncode({
      "id": ref.read(userProvider)!.id,
      "latitude": 0,
      "longitude": 0,
      "phone_number": ref.read(userProvider)!.phone_number,
    });
    ref.refresh(allNewsFuture.future);
    await ref.refresh(homeFuture(homeApiData).future);
    await ref.refresh(serviceDataFuture.future);
  }

  @override
  Widget build(BuildContext context) {
    final homeApiData = jsonEncode({
      "id": ref.read(userProvider)!.id,
      "latitude": 0,
      "longitude": 0,
      "phone_number": ref.read(userProvider)!.phone_number,
    });
    final homeData = ref.watch(homeFuture(homeApiData));

    final user = ref.watch(userProvider);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: KScaffold(
        appBar: AppBar(
          surfaceTintColor: const Color.fromARGB(255, 255, 242, 220),
          automaticallyImplyLeading: false,
          // title: CircleAvatar(
          //   backgroundImage: AssetImage("$kImagePath/logo.png"),
          //   backgroundColor: Kolor.scaffold,
          // ),
          title: Image.asset(
            "$kImagePath/h_c_logoo.png",
            height: 200, // adjust as needed
            fit: BoxFit.contain,
          ),
          backgroundColor: Color(0xFFFFF5E5),
          actions: [
            Icon(Icons.account_balance_wallet_outlined),
            width5,
            Label(
              homeData.when(
                data: (data) => kCurrencyFormat(user?.balance ?? 0),
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
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... existing code before homeData.when
                homeData.when(
                  data:
                      (data) => Container(
                        // Outer Container to hold the background
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFFFAF0), // Light pastel background
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
                            // Removed the inner Container and its decoration
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
                                                            dynamic
                                                          >,
                                                      "serviceName": service,
                                                      "serviceImage":
                                                          serviceImageBaseUrl +
                                                          icon,
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
                          child: KCard(
                            height: 200,
                            width: double.infinity,
                            radius: 0,
                          ),
                        ),
                      ),
                  skipLoadingOnRefresh: false,
                ),
                kHeight(0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: kPadding,
                    //   ).copyWith(bottom: 10),
                    //   child: Label("Our Services", fontSize: 16).regular,
                    // ),
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
                                                              dynamic
                                                            >,
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
                                              offset: Offset(
                                                0,
                                                -20,
                                              ), // Move up by 10 pixels
                                              child: SizedBox(
                                                width: 100,
                                                height: 100,
                                                child: _more(
                                                  context,
                                                ), // ← ADD MORE BUTTON HERE
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 0,
                                    bottom: 40,
                                    child: IgnorePointer(
                                      child: Container(
                                        width: 30,
                                        alignment: Alignment.center,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Color.fromARGB(
                                              213,
                                              255,
                                              140,
                                              0,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 16,
                                            color: Colors.white,
                                            weight: 900,
                                          ),
                                        ),
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

                                padding: EdgeInsets.symmetric(horizontal: 10),
                                physics: NeverScrollableScrollPhysics(),
                                children: List.generate(
                                  6,
                                  (index) => KCard(
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
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      loading:
                          () => GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            physics: NeverScrollableScrollPhysics(),
                            children: List.generate(
                              6,
                              (index) => Skeletonizer(
                                child: Skeleton.leaf(
                                  enabled: true,
                                  child: KCard(
                                    margin: EdgeInsets.all(10),
                                    height: 120,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      skipLoadingOnRefresh: false,
                    ),
                  ],
                ),

                height20,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Label("Famous Locations in Nepal", fontSize: 16).regular,
                      TextButton(
                        onPressed: () => context.push("/all-news"),
                        child: Label("View All").regular,
                      ),
                    ],
                  ),
                ),
                height10,
                newsSection(),

                kHeight(100),
              ],
            ),
          ),
        ),
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
      margin: EdgeInsets.all(10),
      height: 100,
      width: 100,
      radius: 50, // Half of height/width → circle
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Kolor.scaffold,
            child: Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          ),
          // SizedBox(height: 2),
          // Label("More", fontSize: 11).regular,
        ],
      ),
    );
  }

  Widget catgeoryModal() {
    return Consumer(
      builder: (context, ref, _) {
        final homeData = ref.watch(
          homeFuture(
            jsonEncode({
              "id": ref.read(userProvider)!.id,
              "latitude": 0,
              "longitude": 0,
              "phone_number": ref.read(userProvider)!.phone_number,
            }),
          ),
        );
        return SingleChildScrollView(
          child: Container(
            // padding: EdgeInsets.all(kPadding),
            decoration: BoxDecoration(
              color: Kolor.scaffold,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(kPadding),
                    child: Label("Our Services").title,
                  ),
                  MasonryGridView(
                    gridDelegate:
                        SliverSimpleGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 0,
                    padding: EdgeInsets.symmetric(horizontal: 10),
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
                        error: (error, stackTrace) => [SizedBox()],
                        loading:
                            () => List.generate(
                              6,
                              (index) => KCard(
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
        return newsData.when(
          data:
              (data) => SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: kPadding),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 15,
                  children:
                      (data['data'] as List)
                          .map(
                            (e) => NewsCard(
                              data: e,
                              isSaved: (savedNewsData.value ?? []).any(
                                (element) => element["news_id"] == e["news_id"],
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
                padding: EdgeInsets.symmetric(horizontal: kPadding),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 15,
                  children:
                      [1, 2]
                          .map(
                            (e) => Skeletonizer(
                              child: Skeleton.leaf(
                                child: KCard(height: 150, width: 200),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
        );
      },
    );
  }
}
