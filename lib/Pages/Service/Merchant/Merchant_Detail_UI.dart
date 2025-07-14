// ignore_for_file: unused_result

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Helper/Location_Helper.dart';
import 'package:hello_captain_user/Models/cart_item_model.dart';
import 'package:hello_captain_user/Pages/Service/Merchant/Cart_Wrapper.dart';
import 'package:hello_captain_user/Repository/cart_repo.dart';
import 'package:hello_captain_user/Repository/purchasing_repo.dart';
import 'package:hello_captain_user/Resources/app_config.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:skeletonizer/skeletonizer.dart';

class Merchant_Detail_UI extends ConsumerStatefulWidget {
  final String merchantId;
  final String serviceId;
  final String serviceName;
  const Merchant_Detail_UI({
    super.key,
    required this.merchantId,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  ConsumerState<Merchant_Detail_UI> createState() => _Merchant_Detail_UIState();
}

class _Merchant_Detail_UIState extends ConsumerState<Merchant_Detail_UI> {
  Position? myPos;
  final filterId = ValueNotifier("1");

  final position = StateProvider<Position?>((ref) => null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => getLocation());
  }

  Future<void> getLocation() async {
    myPos = await LocationService.getCurrentLocation();
    setState(() {});
  }

  Future<void> _refresh() async {
    if (myPos != null) {
      await ref.refresh(
        merchantDetailFuture(
          jsonEncode({
            "merchantId": widget.merchantId,
            "lat": myPos?.latitude ?? 0,
            "lng": myPos?.longitude ?? 0,
          }),
        ).future,
      );
      await ref.refresh(
        itemsFuture(
          jsonEncode({
            "merchantId": widget.merchantId,
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
    final merchantData = ref.watch(
      merchantDetailFuture(
        jsonEncode({
          "merchantId": widget.merchantId,
          "lat": myPos?.latitude ?? 0,
          "lng": myPos?.longitude ?? 0,
        }),
      ),
    );

    final itemsData = ref.watch(
      itemsFuture(
        jsonEncode({
          "merchantId": widget.merchantId,
          "categoryId": filterId.value,
          "lat": myPos?.latitude ?? 0,
          "lng": myPos?.longitude ?? 0,
        }),
      ),
    );
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CartWrapper(
        serviceName: widget.serviceName,
        serviceId: widget.serviceId,
        child: KScaffold(
          appBar: AppBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Builder(
                builder: (context) {
                  if (myPos != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        merchantData.when(
                          data:
                              (data) => Padding(
                                padding: EdgeInsets.all(kPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: kRadius(15),
                                        image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: NetworkImage(
                                            "$merchantImageBaseUrl/${data['fotomerchant']}",
                                          ),
                                        ),
                                      ),
                                    ),
                                    height10,
                                    Label(
                                      "${data['namamerchant']}",
                                      fontSize: 30,
                                      weight: 900,
                                    ).title,
                                    height5,
                                    Row(
                                      spacing: 10,
                                      children: [
                                        Expanded(
                                          child:
                                              Label(
                                                "${data['alamatmerchant']}",
                                              ).regular,
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            try {
                                              await openMap(
                                                data['latmerchant'],
                                                data['longmerchant'],
                                              );
                                            } catch (e) {
                                              KSnackbar(
                                                context,
                                                message: "Unable to open map!",
                                                error: true,
                                              );
                                            }
                                          },
                                          icon: Icon(
                                            Icons.directions,
                                            color: StatusText.neutral,
                                          ),
                                        ),
                                      ],
                                    ),
                                    height10,
                                    Row(
                                      spacing: 10,
                                      children: [
                                        Icon(Icons.schedule, size: 15),
                                        Label(
                                          "${data['bukamerchant']} - ${data['tutupmerchant']}",
                                        ).regular,
                                      ],
                                    ),
                                    height20,
                                    ValueListenableBuilder(
                                      valueListenable: filterId,
                                      builder: (context, selectedFilter, _) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                spacing: 10,
                                                children:
                                                    [
                                                      {
                                                        "category_item_id": "1",
                                                        "category_name_item":
                                                            "All",
                                                      },
                                                      ...(data["kategoriitem"]
                                                          as List),
                                                    ].map((e) {
                                                      return ChoiceChip(
                                                        selected:
                                                            e["category_item_id"] ==
                                                            selectedFilter,
                                                        backgroundColor:
                                                            Kolor.scaffold,
                                                        selectedColor:
                                                            Kolor.primary,
                                                        checkmarkColor:
                                                            Kolor.scaffold,
                                                        onSelected: (
                                                          value,
                                                        ) async {
                                                          filterId.value =
                                                              e["category_item_id"];

                                                          await _refresh();
                                                        },
                                                        label:
                                                            Label(
                                                              "${e["category_name_item"]}",
                                                              color:
                                                                  e["category_item_id"] ==
                                                                          selectedFilter
                                                                      ? Kolor
                                                                          .scaffold
                                                                      : Colors
                                                                          .black,
                                                            ).regular,
                                                      );
                                                    }).toList(),
                                              ),
                                            ),
                                            height20,
                                            selectedFilter == "1"
                                                ? merchantData.when(
                                                  data:
                                                      (data) => itemListData(
                                                        data["itembyid"]
                                                            as List,
                                                      ),

                                                  error:
                                                      (error, stackTrace) =>
                                                          kNoData(
                                                            subtitle: "$error",
                                                          ),
                                                  loading: () => dummyData(),
                                                )
                                                : itemsData.when(
                                                  data: (data) {
                                                    return itemListData(
                                                      data["itembyid"] as List,
                                                    );
                                                  },
                                                  error:
                                                      (error, stackTrace) =>
                                                          kNoData(
                                                            subtitle: "$error",
                                                          ),
                                                  loading: () => dummyData(),
                                                ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          error:
                              (error, stackTrace) =>
                                  kNoData(subtitle: "$error"),
                          loading:
                              () => Skeletonizer(
                                child: Padding(
                                  padding: const EdgeInsets.all(kPadding),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Skeleton.leaf(
                                        child: KCard(
                                          width: double.infinity,
                                          height: 100,
                                        ),
                                      ),
                                      Label(
                                        "Store Name",
                                        fontSize: 30,
                                        weight: 900,
                                      ).title,
                                      Label(
                                        "store address store address store address store address store address",
                                      ).regular,
                                    ],
                                  ),
                                ),
                              ),
                        ),
                      ],
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(kPadding),
                    child: dummyData(),
                  );
                },
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

  Widget itemListData(List itemList) {
    if (itemList.isNotEmpty) {
      return Consumer(
        builder: (context, ref, _) {
          final cartData = ref.watch(cartProvider);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Label("Relevant Items").regular,
              height10,
              if (itemList.isNotEmpty)
                ListView.separated(
                  physics: NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => height15,
                  itemCount: itemList.length,
                  padding: EdgeInsets.only(bottom: 100),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final item = CartItemModel.fromMap(itemList[index]);
                    return KCard(
                      onTap: () {},

                      child: Row(
                        spacing: 20,
                        children: [
                          Column(
                            spacing: 10,
                            children: [
                              Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: kRadius(10),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(
                                      "$itemImageBaseUrl/${item.item_image}",
                                    ),
                                  ),
                                ),
                              ),
                              if (cartData.any(
                                (element) => element.item_id == item.item_id,
                              ))
                                Row(
                                  spacing: 10,
                                  children: [
                                    KCard(
                                      onTap: () {
                                        final qty =
                                            ref
                                                .read(cartProvider)
                                                .where(
                                                  (element) =>
                                                      element.item_id ==
                                                      item.item_id,
                                                )
                                                .toList()[0]
                                                .quantity;

                                        if (qty > 1) {
                                          ref
                                              .read(cartProvider.notifier)
                                              .updateQuantity(
                                                item.item_id,
                                                qty - 1,
                                              );
                                        } else {
                                          ref
                                              .read(cartProvider.notifier)
                                              .removeItem(item.item_id);
                                        }
                                      },
                                      borderWidth: 1,
                                      borderColor: Colors.grey.shade700,
                                      radius: 5,
                                      padding: EdgeInsets.all(5),
                                      child: Icon(
                                        Icons.horizontal_rule,
                                        size: 15,
                                      ),
                                    ),
                                    Label(
                                      "${cartData.where((element) => element.item_id == item.item_id).toList()[0].quantity}",
                                    ).regular,
                                    KCard(
                                      onTap: () {
                                        final qty =
                                            ref
                                                .read(cartProvider)
                                                .where(
                                                  (element) =>
                                                      element.item_id ==
                                                      item.item_id,
                                                )
                                                .toList()[0]
                                                .quantity;

                                        ref
                                            .read(cartProvider.notifier)
                                            .updateQuantity(
                                              item.item_id,
                                              qty + 1,
                                            );
                                      },
                                      borderWidth: 1,
                                      borderColor: Colors.grey.shade700,
                                      radius: 5,
                                      padding: EdgeInsets.all(5),
                                      child: Icon(Icons.add, size: 15),
                                    ),
                                  ],
                                )
                              else
                                KButton(
                                  onPressed: () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .addItem(item);
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(item.item_id, 1);
                                  },
                                  label: "Add to bag",
                                  visualDensity: VisualDensity.compact,
                                  style: KButtonStyle.outlined,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 15,
                                  ),
                                  radius: 7,
                                  foregroundColor: Kolor.primary,
                                ),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Label(item.category_name_item).regular,
                                Label(
                                  item.item_name,
                                  weight: 800,
                                  fontSize: 17,
                                ).regular,
                                height15,
                                Label(
                                  kCurrencyFormat(item.item_price / 100),
                                  decoration: TextDecoration.lineThrough,
                                ).subtitle,
                                Label(
                                  item.promo_price <= 0
                                      ? kCurrencyFormat(item.item_price / 100)
                                      : kCurrencyFormat(item.promo_price / 100),
                                  fontSize: 22,
                                  weight: 900,
                                ).regular,
                                height10,
                                Label("About").subtitle,
                                Label(item.item_desc).regular,
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                kNoData(subtitle: "No Items."),
            ],
          );
        },
      );
    }

    return kNoData(subtitle: "No Items.");
  }
}
