import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Essentials/kField.dart';
import 'package:hello_captain_user/Essentials/kWidgets.dart';
import 'package:hello_captain_user/Helper/Location_Helper.dart';
import 'package:hello_captain_user/Models/driver_model.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Repository/cart_repo.dart';
import 'package:hello_captain_user/Repository/mapBox_repo.dart';
import 'package:hello_captain_user/Repository/notification_repo.dart';
import 'package:hello_captain_user/Repository/purchasing_repo.dart';
import 'package:hello_captain_user/Repository/ride_repo.dart';
import 'package:hello_captain_user/Repository/subscription_repo.dart';
import 'package:hello_captain_user/Resources/app_config.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class Merchant_Checkout_UI extends ConsumerStatefulWidget {
  final String serviceId;
  final String serviceName;
  const Merchant_Checkout_UI({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  ConsumerState<Merchant_Checkout_UI> createState() =>
      _Merchant_Checkout_UIState();
}

class _Merchant_Checkout_UIState extends ConsumerState<Merchant_Checkout_UI> {
  final isLoading = ValueNotifier(false);
  String displayAddress = "";
  final isFetching = ValueNotifier(false);
  Map<String, dynamic> promoData = {};
  final promoCode = TextEditingController();
  String paymentMethod = "Wallet";
  List<DriverModel> driversList = [];
  double duration = 0;
  double distance = 0.0;
  double distanceInMeters = 0;
  int price = 0;
  double minimumFare = 50.0;
  double costPerKm = 10.0;
  int netPayable = 0;
  int promoDiscount = 0;
  int subscriptionDiscount = 0;
  int subscriptionPercent = 0;
  int subscriptionMaxDiscount = 0;

  @override
  void dispose() {
    promoCode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      fetchSubscriptionDetails();
      fetchAddress();
      setDriverMarkers();
    });
  }

  Future<void> setDriverMarkers() async {
    try {
      final merchant = ref.read(currentMerchantProvider);
      // log("$merchant");
      if (merchant == null) throw "Missing merchant's location!";

      final driverRes = await ref.read(
        listMerchantRidersFuture(
          jsonEncode({
            "latitude": merchant.merchant_latitude,
            "longitude": merchant.merchant_longitude,
            "serviceId": widget.serviceId,
          }),
        ).future,
      );
      driversList =
          (driverRes['data'] as List)
              .map((e) => DriverModel.fromMap(e))
              .toList();

      // log("$driversList");
    } catch (e) {
      log("$e");
    }
  }

  Future<void> fetchSubscriptionDetails() async {
    try {
      // re-init
      subscriptionPercent = 0;
      subscriptionMaxDiscount = 0;

      final merchant = ref.read(currentMerchantProvider);
      if (merchant == null) throw "No Merchant Selected!";

      //call api
      final subData = await ref.read(activeSubscriptionFuture.future);
      // log("$subData");

      // check if ext id exist
      if ("${subData['service_types']}".split(",").contains(merchant.ext_id)) {
        subscriptionPercent = kRound(subData["discount_percent"]);
        subscriptionMaxDiscount = kRound(subData["max_discount"]);
      }

      // log("Subscription Percent: $subscriptionPercent");
      // log("Subscription Max-Discount: $subscriptionMaxDiscount");

      calculateBreakdown();
    } catch (e) {
      log("$e");
    }
  }

  Future<void> validatePromoCode() async {
    try {
      // re-init
      promoDiscount = 0;

      FocusScope.of(context).unfocus();
      isLoading.value = true;

      // api call
      final res = await RideRepo.validatePromocode(
        widget.serviceId,
        promoCode.text.trim(),
      );
      if (res['code'] != '200') throw res['message'] ?? 'Promo Code invalid!';

      KSnackbar(context, message: "Promo applied!");
      double nominal = parseToDouble(res['nominal']);

      // if type is fix/parsen
      promoData = {
        "discount": (netPayable * (nominal / 100)),
        "code": promoCode.text,
      };
      promoDiscount = kRound(netPayable * (nominal / 100));
      if (res['type'] == 'fix') {
        promoData = {"discount": kRound(nominal), "code": promoCode.text};
        promoDiscount = kRound(nominal);
      }

      calculateBreakdown();
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> calculateBreakdown() async {
    try {
      isLoading.value = true;

      final user = ref.read(userProvider);
      if (user == null) throw "User not logged in!";

      final cartData = ref.read(cartProvider);

      // Check if cart is not empty
      if (cartData.isNotEmpty) {
        // Calculate sub-total
        price = 0;
        for (var item in cartData) {
          double item_cost =
              (item.promo_price <= 0 ? item.item_price : item.promo_price) /
              100;
          price += kRound(item.quantity * item_cost);
        }
        // log("Price: $price");

        // calculate subscription discount
        subscriptionDiscount = kRound(price * (subscriptionPercent / 100));
        if (subscriptionDiscount > subscriptionMaxDiscount) {
          subscriptionDiscount = subscriptionMaxDiscount;
        }

        int priceAfterSubscriptionDiscount = price - subscriptionDiscount;

        // calculate promo code discount safely
        if (promoDiscount > priceAfterSubscriptionDiscount) {
          promoDiscount = priceAfterSubscriptionDiscount;
        }

        // calculate net-payable
        netPayable = price - subscriptionDiscount - promoDiscount;

        // log("Sub-Total: $price");
        // log("Subscription-Discount: $subscriptionDiscount");
        // log("Promo-Discount: $promoDiscount");
        // log("Net-Payable: $netPayable");

        // enforce minimum payable amount
        if (netPayable < 1) {
          promoDiscount -= (1 - netPayable).ceil();
          if (promoDiscount < 0) promoDiscount = 0;
          netPayable = 1;
        }

        // enforce payment method
        paymentMethod = "Wallet";
        if (user.balance < netPayable) {
          paymentMethod = "Cash";
        }

        setState(() {});
      } else {
        KSnackbar(
          context,
          message: "Cart is empty! Add products in cart",
          error: true,
        );
      }
    } catch (e) {
      KSnackbar(context, message: "Please try again!", error: true);
    } finally {
      isLoading.value = false;
    }
  }

  void buyNow() async {
    try {
      if (driversList.isEmpty) {
        KSnackbar(context, message: "No drivers available!", error: true);
        return;
      }
      isLoading.value = true;
      final userId = ref.read(userProvider)?.id;

      if (userId == null) throw "User not logged in!";

      final merchant = ref.read(currentMerchantProvider);
      if (merchant == null) throw "No Merchant Selected!";

      final myPos = await LocationService.getCurrentLocation();
      if (myPos == null) throw "Unable to determine location!";

      final cartList = ref.read(cartProvider);

      List pesanan = [];

      for (var element in cartList) {
        pesanan.add({
          "note": "",
          "item_id": element.item_id,
          "id_resto": element.merchant_id,
          "qty": element.quantity,
          "total_cost":
              element.promo_price <= 0
                  ? element.item_price
                  : element.promo_price,
        });
      }

      final int estimatedTime = kRound((merchant.distance / 4) * 3600);
      final String distance = merchant.distance.toString();

      final res = await PurchasingRepo.buyCartItems({
        "customer_id": userId,
        "service_order": widget.serviceId,
        "start_latitude": merchant.merchant_latitude,
        "start_longitude": merchant.merchant_longitude,
        "end_latitude": myPos.latitude,
        "end_longitude": myPos.longitude,
        "distance": parseToDouble(distance) * 1000,
        "price": price,
        "estimasi": estimatedTime,
        "pickup_address": merchant.merchant_address,
        "destination_address": displayAddress,
        "promo_discount": subscriptionDiscount + promoDiscount,
        "wallet_payment": paymentMethod == "Cash" ? "0" : "1",
        "total_biaya_belanja": 0,
        "id_resto": merchant.merchant_id,
        "pesanan": pesanan,
      });

      // log("$res");
      KSnackbar(context, message: "Order Successfully Placed!");
      await sendNotificationToDrivers(res['data'][0]);
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendNotificationToDrivers(
    Map<String, dynamic> transactionData,
  ) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) throw "User not logged in!";

      transactionData["layanan"] = user.customer_fullname;
      transactionData["layanandesc"] = widget.serviceName;
      transactionData["bid"] = "false";
      for (DriverModel driver in driversList) {
        await NotificationRepo.sendNotification(
          driver.reg_id,
          "New ${widget.serviceName} Order Available",
          transactionData,
        );
      }
      ref.read(cartProvider.notifier).clearCart();
      context.go(
        "/confirmation",
        extra:
            Map.from({
              'subtitle': "${widget.serviceName} Booked",
              'description': "You can track in the order details page.",
            }).cast<String, dynamic>(),
      );
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    }
  }

  void fetchAddress() async {
    try {
      isFetching.value = true;
      final myPos = await LocationService.getCurrentLocation();
      if (myPos == null) throw "Unable to determine user location!";
      final res = await MapboxRepo.getAddressFromCoordinates(
        Position(myPos.longitude, myPos.latitude),
      );

      if (res == null) throw "Unable to fetch Address";
      setState(() {
        displayAddress = res['address'];
      });
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    } finally {
      isFetching.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartData = ref.watch(cartProvider);
    final user = ref.watch(userProvider);
    final merchant = ref.watch(currentMerchantProvider);

    return KScaffold(
      isLoading: isLoading,
      appBar: KAppBar(context, title: "Checkout"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(kPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Label("Deliver At", color: Kolor.primary, weight: 800).regular,
              height15,
              ValueListenableBuilder(
                valueListenable: isFetching,
                builder:
                    (context, value, child) => Skeletonizer(
                      enabled: value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Label(user?.customer_fullname ?? "").regular,
                          Label(user?.phone_number ?? "").regular,
                          Label(
                            displayAddress.isEmpty
                                ? "address" * 20
                                : displayAddress,
                          ).subtitle,
                        ],
                      ),
                    ),
              ),
              height20,
              Label(
                "Products (${cartData.length})",
                color: Kolor.primary,
                weight: 800,
              ).regular,
              height15,

              Column(
                spacing: 15,
                children:
                    cartData
                        .map(
                          (e) => Row(
                            spacing: 15,
                            children: [
                              Container(
                                height: 70,
                                width: 70,
                                decoration: BoxDecoration(
                                  borderRadius: kRadius(5),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      "$itemImageBaseUrl/${e.item_image}",
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Label(e.item_name, weight: 800).regular,
                                    Label(
                                      "QTY: ${e.quantity}",
                                      fontSize: 12,
                                    ).regular,
                                    height5,
                                    Label(
                                      e.promo_price <= 0
                                          ? kCurrencyFormat(e.item_price / 100)
                                          : kCurrencyFormat(
                                            e.promo_price / 100,
                                          ),
                                      weight: 800,
                                    ).regular,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
              ),

              height20,
              Label(
                "Price Breakdown",
                color: Kolor.primary,
                weight: 800,
              ).regular,
              height15,
              KCard(
                borderWidth: 1,
                color: Kolor.scaffold,
                padding: EdgeInsets.all(10),
                child: Column(
                  spacing: 10,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Label("Estimated Time").regular,
                        Label(
                          merchant?.distance != null
                              ? secondsToHoursMinutes(
                                ((merchant!.distance / 4) * 3600),
                              )
                              : "-",
                        ).regular,
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Label("Distance (Km)").regular,
                        Label(
                          merchant?.distance != null
                              ? "${merchant!.distance.toStringAsFixed(2)} Km"
                              : "-",
                        ).regular,
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Label("Price (NPR)").regular,
                        Label(
                          kCurrencyFormat(price),
                        ).regular, // Use calculated price
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Label(
                          "Promo Discount",
                          color: StatusText.success,
                        ).regular,
                        Label(
                          kCurrencyFormat((promoDiscount)),
                          color: StatusText.success,
                        ).regular,
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Label(
                          "Subscription Discount",
                          color: StatusText.success,
                        ).regular,
                        Label(
                          kCurrencyFormat(subscriptionDiscount),
                          color: StatusText.success,
                        ).regular,
                      ],
                    ),
                    div,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Label("Total", fontSize: 17, weight: 900).regular,
                        Label(
                          kCurrencyFormat(netPayable),
                          fontSize: 17,
                          weight: 900,
                        ).regular,
                      ],
                    ),
                  ],
                ),
              ),

              height20,
              Label("Promo Code", color: Kolor.primary, weight: 800).regular,
              height15,

              if (promoData.isEmpty)
                KField(
                  controller: promoCode,
                  hintText: "Have a promo code?",
                  textCapitalization: TextCapitalization.characters,
                  suffix: KButton(
                    onPressed: () => validatePromoCode(),
                    label: "Use",
                    backgroundColor: StatusText.success,
                    visualDensity: VisualDensity.compact,
                    radius: 5,
                  ),
                )
              else
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    KCard(
                      color: Colors.lime.lighten(.5),
                      width: double.infinity,
                      child: Row(
                        spacing: 10,
                        children: [
                          Icon(Icons.discount),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Label(
                                  "Offer Applied! ${promoData['code']}",
                                  color: StatusText.success,
                                  weight: 900,
                                ).regular,
                                Label(
                                  "${kCurrencyFormat(promoDiscount)} will be discounted from net payable.",
                                ).regular,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    KCard(
                      padding: EdgeInsets.all(5),
                      radius: 100,
                      color: Kolor.secondary,
                      onTap: () {
                        setState(() {
                          promoData = {};
                          promoDiscount = 0;
                          calculateBreakdown();
                        });
                      },
                      child: Icon(Icons.close, color: Kolor.scaffold, size: 15),
                    ),
                  ],
                ),

              height20,
              Label(
                "Payment Method",
                color: Kolor.primary,
                weight: 800,
              ).regular,
              height15,

              InkWell(
                onTap: () {
                  setState(() {
                    paymentMethod = "Wallet";
                  });
                },
                child: Row(
                  spacing: 15,
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          paymentMethod == "Wallet"
                              ? Kolor.secondary
                              : Kolor.card,
                      child: Icon(
                        Icons.check,
                        color:
                            paymentMethod == "Wallet"
                                ? Colors.white
                                : Colors.transparent,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 10,
                            children: [
                              Label("Wallet", weight: 900).regular,
                              KCard(
                                radius: 5,
                                padding: EdgeInsets.symmetric(
                                  vertical: 2,
                                  horizontal: 5,
                                ),
                                color: Kolor.secondary,
                                child:
                                    Label(
                                      kCurrencyFormat(user?.balance ?? 0),
                                      weight: 800,
                                      fontSize: 10,
                                      color: Colors.white,
                                    ).regular,
                              ),
                            ],
                          ),
                          Label("Pay using wallet").subtitle,
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push("/profile/recharge"),
                      child: Label("Recharge").regular,
                    ),
                  ],
                ),
              ),
              height10,
              InkWell(
                onTap: () {
                  setState(() {
                    paymentMethod = "Cash";
                  });
                },
                child: Row(
                  spacing: 15,
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          paymentMethod == "Cash"
                              ? Kolor.secondary
                              : Kolor.card,
                      child: Icon(
                        Icons.check,
                        color:
                            paymentMethod == "Cash"
                                ? Colors.white
                                : Colors.transparent,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Label("Cash", weight: 900).regular,
                          Label("Pay by cash").subtitle,
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              height20,
              disclaimer(),
              height20,
              ValueListenableBuilder(
                valueListenable: isFetching,
                builder:
                    (context, value, child) => KButton(
                      onPressed: value ? null : () => buyNow(),
                      label: "Confirm Order",
                      style: KButtonStyle.expanded,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
