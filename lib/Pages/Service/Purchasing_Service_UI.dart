// ignore_for_file: unused_result

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Helper/Location_Helper.dart';
import 'package:hello_captain_user/Models/merchant_model.dart';
import 'package:hello_captain_user/Pages/Service/Merchant/Cart_Wrapper.dart';
import 'package:hello_captain_user/Repository/purchasing_repo.dart';
import 'package:hello_captain_user/Resources/app_config.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:skeletonizer/skeletonizer.dart';

class Purchasing_Service_UI extends ConsumerStatefulWidget {
  final Map<String, dynamic> serviceData;
  const Purchasing_Service_UI({super.key, required this.serviceData});

  @override
  ConsumerState<Purchasing_Service_UI> createState() =>
      _Purchasing_Service_UIState();
}

class _Purchasing_Service_UIState extends ConsumerState<Purchasing_Service_UI> {
  Position? myPos;
  final filterId = ValueNotifier("1");

  final position = StateProvider<Position?>((ref) => null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      getLocation();
    });
  }

  Future<void> getLocation() async {
    myPos = await LocationService.getCurrentLocation();
    setState(() {});
  }

  Future<void> _refresh() async {
    if (myPos != null) {
      ref.refresh(categoryFuture(widget.serviceData["service_id"]).future);
      await ref.refresh(
        merchantFuture(
          jsonEncode({
            "serviceId": widget.serviceData["service_id"],
            "categoryId": filterId.value,
            "lat": myPos?.latitude ?? 0,
            "lng": myPos?.longitude ?? 0,
          }),
        ).future,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryData = ref.watch(
      categoryFuture(
        jsonEncode({
          "serviceId": widget.serviceData["service_id"],
          "categoryId": filterId.value,
          "lat": myPos?.latitude ?? 0,
          "lng": myPos?.longitude ?? 0,
        }),
      ),
    );

    final merchantData = ref.watch(
      merchantFuture(
        jsonEncode({
          "serviceId": widget.serviceData["service_id"],
          "categoryId": filterId.value,
          "lat": myPos?.latitude ?? 0,
          "lng": myPos?.longitude ?? 0,
        }),
      ),
    );

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CartWrapper(
        serviceId: widget.serviceData['service_id'] ?? widget.serviceData['id'],
        child: KScaffold(
          appBar: KAppBar(context, title: "${widget.serviceData['service']}"),
          body: SafeArea(
            child: Visibility(
              visible: myPos != null,
              replacement: Padding(
                padding: const EdgeInsets.all(kPadding),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        "$kImagePath/searching-location.svg",
                        height: 200,
                      ),
                      Label(
                        "Searching Merchants ...",
                        weight: 900,
                        fontSize: 16,
                      ).title,
                    ],
                  ),
                ),
              ),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: ValueListenableBuilder(
                  valueListenable: filterId,
                  builder: (context, selectedFilter, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: kPadding),
                          scrollDirection: Axis.horizontal,
                          child: categoryData.when(
                            data:
                                (data) => Row(
                                  spacing: 10,
                                  children:
                                      (data["kategorymerchant"] as List)
                                          .map(
                                            (e) => ChoiceChip(
                                              selected:
                                                  e["category_merchant_id"] ==
                                                  selectedFilter,
                                              onSelected: (value) async {
                                                filterId.value =
                                                    e["category_merchant_id"];
                                                await _refresh();
                                              },
                                              backgroundColor: Kolor.scaffold,
                                              selectedColor: Kolor.primary,
                                              label:
                                                  Label(
                                                    "${e["category_name"]}",
                                                    color:
                                                        e["category_merchant_id"] ==
                                                                selectedFilter
                                                            ? Kolor.scaffold
                                                            : Colors.black,
                                                  ).regular,
                                              checkmarkColor: Kolor.scaffold,
                                            ),
                                          )
                                          .toList(),
                                ),
                            error: (error, stackTrace) => const SizedBox(),
                            loading:
                                () => Row(
                                  spacing: 10,
                                  children: List.generate(
                                    7,
                                    (index) => Skeletonizer(
                                      child: Skeleton.leaf(
                                        child: Chip(label: Text("text")),
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.all(kPadding),
                          child:
                              selectedFilter == "1"
                                  ? categoryData.when(
                                    data:
                                        (data) => merchantListData(
                                          data["allmerchantnearby"] as List,
                                        ),

                                    error: (error, stackTrace) => kNoData(),
                                    loading: () => dummyData(),
                                    skipLoadingOnRefresh: false,
                                  )
                                  : merchantData.when(
                                    data:
                                        (data) => merchantListData(
                                          data["allmerchantnearby"] as List,
                                        ),
                                    error: (error, stackTrace) => kNoData(),
                                    loading: () => dummyData(),
                                    skipLoadingOnRefresh: false,
                                  ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget dummyData() => ListView.separated(
    separatorBuilder: (context, index) => height15,
    itemCount: 5,
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    itemBuilder:
        (context, index) => Skeletonizer(
          child: Skeleton.leaf(
            child: KCard(width: double.infinity, height: 200),
          ),
        ),
  );

  Widget merchantListData(List merchantList) {
    if (merchantList.isNotEmpty) {
      return ListView.separated(
        physics: NeverScrollableScrollPhysics(),
        separatorBuilder: (context, index) => height15,
        itemCount: merchantList.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final merchant = merchantList[index];
          // Add ext_id in merchant model
          merchant["ext_id"] = widget.serviceData["ext_id"];
          return KCard(
            onTap: () {
              ref
                  .read(currentMerchantProvider.notifier)
                  .state = MerchantModel.fromMap(merchant);
              context.push(
                "/merchant/detail",
                extra: {
                  ...widget.serviceData,
                  "merchant_id": merchant['merchant_id'],
                },
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Kolor.scaffold,
                    borderRadius: kRadius(15),
                    image: DecorationImage(
                      image: NetworkImage(
                        "$merchantImageBaseUrl/${merchant["merchant_image"]}",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                height15,
                Row(
                  children: [
                    Expanded(
                      child:
                          Label(
                            merchant["category_name"],
                            fontSize: 12,
                          ).regular,
                    ),
                    Row(
                      spacing: 5,
                      children: [
                        Icon(Icons.location_on, size: 15),
                        Label(
                          "${parseToDouble(merchant["distance"]).toStringAsFixed(2)} Kms",
                          fontSize: 12,
                        ).regular,
                      ],
                    ),
                  ],
                ),
                Label(merchant["merchant_name"]).title,
                Label(merchant["merchant_address"]).subtitle,
                height5,
                Label(
                  "Timing: ${merchant["open_hour"]} - ${merchant["close_hour"]}",
                  fontSize: 12,
                  weight: 700,
                ).regular,
              ],
            ),
          );
        },
      );
    }

    return kNoData(subtitle: "No Merchants Nearby.");
  }
}
