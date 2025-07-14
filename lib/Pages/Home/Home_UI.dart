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
          surfaceTintColor: Kolor.scaffold,
          automaticallyImplyLeading: false,
          // title: CircleAvatar(
          //   backgroundImage: AssetImage("$kImagePath/logo.png"),
          //   backgroundColor: Kolor.scaffold,
          // ),
          title: Image.asset(
            "$kImagePath/syslogo.png",
            height: 30, // adjust as needed
            fit: BoxFit.contain,
          ),
          backgroundColor: Kolor.scaffold,
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
                homeData.when(
                  data:
                      (data) => KCarousel(
                        isLooped: true,
                        children:
                            (data["slider"] as List)
                                .map(
                                  (e) => GestureDetector(
                                    onTap: () {
                                      String path = "";
                                      switch (e['title']) {
                                        case "Passenger Transportation":
                                          path = "/passenger-transportation";
                                          break;

                                        case "Rental":
                                          path = "/rental";
                                          break;

                                        case "Shipment":
                                          path = "/shipment";
                                          break;

                                        case "Purchasing Service":
                                          path = "/purchasing-service";
                                          break;
                                        default:
                                      }
                                      context.push(
                                        path,
                                        extra: {
                                          ...e as Map<String, dynamic>,
                                          "serviceName": e['service'],
                                          "serviceImage":
                                              serviceImageBaseUrl + e['icon'],
                                        },
                                      );
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
                kHeight(30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kPadding,
                      ).copyWith(bottom: 10),
                      child: Label("Our Services", fontSize: 16).regular,
                    ),

                    homeData.when(
                      data:
                          (data) => Stack(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...List.generate(5, (index) {
                                      final category =
                                          (data["service"] as List)[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 5,
                                        ),
                                        child: SizedBox(
                                          width: 125,
                                          height: 125,
                                          child: CategoryTile(
                                            index: index,
                                            data:
                                                category
                                                    as Map<String, dynamic>,
                                            type: category["title"],
                                            id: "${category["id"]}",
                                            label: category["service"],
                                            image:
                                                "$serviceImageBaseUrl/${category["icon"]}",
                                          ),
                                        ),
                                      );
                                    }),
                                    // Keep this part commented for future use
                                    Padding(
                                      padding: const EdgeInsets.only(right: 0),
                                      child: SizedBox(
                                        // width: 10,
                                        // height: 10,
                                        // child: _more(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Scroll indicator overlay (right edge gradient + arrow)
                              Positioned(
                                right: 8,
                                top: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 30,
                                    alignment: Alignment.center,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(
                                          0xFFFF8C00,
                                        ), // Pirate Orange or adjust to match theme
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color:
                                            Colors
                                                .white, // Use Colors.black if you prefer dark arrow
                                        weight: 900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
      margin: EdgeInsets.all(8),
      height: 120,
      child: Column(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Kolor.scaffold,
            child: Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ),
          Label("More").regular,
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
