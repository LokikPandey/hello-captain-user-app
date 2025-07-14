import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Essentials/kField.dart';
import 'package:hello_captain_user/Models/driver_model.dart';
import 'package:hello_captain_user/Pages/Auth/CountryDialog.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Repository/notification_repo.dart';
import 'package:hello_captain_user/Repository/ride_repo.dart';
import 'package:hello_captain_user/Repository/shipment_repo.dart';
import 'package:hello_captain_user/Repository/subscription_repo.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import '../../../Essentials/kButton.dart';
import '../../../Resources/colors.dart';

class Shipment_Detail_UI extends ConsumerStatefulWidget {
  final Map<String, dynamic> serviceData;
  const Shipment_Detail_UI({super.key, required this.serviceData});

  @override
  ConsumerState<Shipment_Detail_UI> createState() => _Shipment_Detail_UIState();
}

class _Shipment_Detail_UIState extends ConsumerState<Shipment_Detail_UI> {
  final isLoading = ValueNotifier(false);
  Map<String, dynamic> promoData = {};
  final promoCode = TextEditingController();
  String? transactionId;
  String serviceName = "";
  String senderSelectedCountry = "+977";
  String receiverSelectedCountry = "+977";
  double duration = 0;
  double distanceInMeters = 0;
  int price = 0;
  int minimumFare = 50;
  double costPerKm = 10.0;
  int netPayable = 0;
  int promoDiscount = 0;
  int subscriptionDiscount = 0;
  int subscriptionPercent = 0;
  int subscriptionMaxDiscount = 0;

  String paymentMethod = "Wallet";
  String distanceText = "";
  String itemType = "";
  final formKey = GlobalKey<FormState>();
  final senderName = TextEditingController();
  final senderPhone = TextEditingController();

  final receiverName = TextEditingController();
  final receiverPhone = TextEditingController();

  @override
  void initState() {
    super.initState();
    serviceName = widget.serviceData["service_name"];
    distanceInMeters = widget.serviceData["distance"];
    minimumFare = widget.serviceData["minimum_cost"];
    costPerKm = widget.serviceData["cost"];
    duration = widget.serviceData["time_distance"];

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      fetchSubscriptionDetails();
    });
  }

  @override
  void dispose() {
    promoCode.dispose();
    senderPhone.dispose();
    senderName.dispose();
    receiverPhone.dispose();
    receiverName.dispose();
    super.dispose();
  }

  Future<void> sendNotificationToDrivers(
    Map<String, dynamic> transactionData,
  ) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) throw "User not logged in!";

      transactionData["layanan"] = user.customer_fullname;
      transactionData["layanandesc"] = serviceName;
      transactionData["bid"] = "false";
      for (DriverModel driver in widget.serviceData["driver"]) {
        await NotificationRepo.sendNotification(
          driver.reg_id,
          "New $serviceName Order Available",
          transactionData,
        );
      }
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    }
  }

  Future<void> fetchSubscriptionDetails() async {
    try {
      // re-init
      subscriptionPercent = 0;
      subscriptionMaxDiscount = 0;

      //call api
      final subData = await ref.read(activeSubscriptionFuture.future);
      // log("$subData");

      // check if ext id exist
      if ("${subData['service_types']}"
          .split(",")
          .contains(widget.serviceData['ext_id'])) {
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
        widget.serviceData['service_id'],
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

  void calculateBreakdown() {
    try {
      isLoading.value = true;

      final user = ref.read(userProvider);
      if (user == null) throw "User not logged in!";
      // Convert distance to kilometers
      double distanceInKm = distanceInMeters / 1000.0;

      // Get minimum and maximum distance from service data
      double maxDistance = parseToDouble(widget.serviceData["maks_distance"]);

      // Check if the distance is within the allowed range
      if (distanceInKm <= maxDistance) {
        distanceText = distanceInKm.toStringAsFixed(1);

        // Calculate sub-total
        price = kRound(costPerKm * distanceInKm);
        if (price < minimumFare) {
          price = kRound(minimumFare);
        }
        // log("Cost/Km: $costPerKm");
        // log("Distance Km: $distanceInKm");
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
          message:
              "The distance of $distanceInKm Km is outside the allowed range of $maxDistance Km",
          error: true,
        );
      }
    } catch (e) {
      KSnackbar(context, message: "Please try again!", error: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> orderShipment() async {
    try {
      FocusScope.of(context).unfocus();
      if (widget.serviceData["driver"].isEmpty) {
        KSnackbar(context, message: "No drivers available!", error: true);
        return;
      }

      if (itemType.isEmpty) throw "Please select item type";
      if (!formKey.currentState!.validate()) throw "All fields are required!";
      isLoading.value = true;
      final user = ref.read(userProvider);
      if (user == null) throw "User not logged in!";
      final data = {
        "customer_id": user.id,
        "service_order": widget.serviceData["service_id"],
        "start_latitude": widget.serviceData['pickup_latitude'],
        "start_longitude": widget.serviceData['pickup_longitude'],
        "end_latitude": widget.serviceData['destination_latitude'],
        "end_longitude": widget.serviceData['destination_longitude'],
        "distance": distanceInMeters,
        "price": price,
        "estimasi":
            (parseToDouble("${widget.serviceData['time_distance']}") * 3600)
                .round(),
        "sender_name": senderName.text.trim(),
        "sender_phone": senderSelectedCountry + senderPhone.text.trim(),
        "receiver_name": receiverName.text.trim(),
        "receiver_phone": receiverSelectedCountry + receiverPhone.text.trim(),
        "goods_item": itemType,
        "pickup_address": widget.serviceData['pickup'],
        "destination_address": widget.serviceData['destination'],
        "promo_discount": subscriptionDiscount + promoDiscount,
        "wallet_payment": paymentMethod == "Wallet" ? 1 : 0,
      };

      final res = await ShipmentRepo.orderShipment(data);

      // log("Order Placed: $res");

      setState(() {
        transactionId = res['data'][0]['id'];
      });
      KSnackbar(context, message: "Request Generated!");

      isLoading.value = false;

      sendNotificationToDrivers(res['data'][0]);

      context.go(
        "/confirmation",
        extra:
            Map.from({
              'subtitle': "$serviceName Booked",
              'description': "You can track in the order details page.",
            }).cast<String, dynamic>(),
      );
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return RefreshIndicator(
      onRefresh: () async {
        calculateBreakdown();
      },
      child: KScaffold(
        isLoading: isLoading,
        appBar: KAppBar(context, title: "Confirm Shipment"),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(kPadding).copyWith(bottom: 100),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label("Select Item Type").regular,
                  height10,
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        ["Document", "Fashion", "Box", "Other"]
                            .map(
                              (e) => KCard(
                                onTap: () {
                                  setState(() {
                                    itemType = e;
                                  });
                                },
                                radius: 7,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                color:
                                    itemType == e
                                        ? Kolor.secondary
                                        : Kolor.scaffold,
                                borderWidth: 1,
                                child:
                                    Label(
                                      e,
                                      fontSize: 15,
                                      color:
                                          itemType == e
                                              ? Colors.white
                                              : Colors.grey,
                                    ).regular,
                              ),
                            )
                            .toList(),
                  ),
                  height20,
                  Label("Sender Details").title,
                  height10,

                  KField(
                    controller: senderName,
                    label: "Name",
                    hintText: "Sender name",
                    validator: (val) => KValidation.required(val),
                  ),
                  height10,
                  KField(
                    controller: senderPhone,
                    label: "Phone Number",
                    prefixText: senderSelectedCountry,
                    prefix: IconButton(
                      onPressed: () async {
                        final res = await showDialog(
                          context: context,
                          builder: (context) => CountryDialog(),
                        );

                        senderSelectedCountry = res["code"];
                        setState(() {});
                      },
                      icon: Row(
                        spacing: 5,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Label(
                            senderSelectedCountry,
                            fontSize: 15,
                            height: 1.5,
                          ).regular,
                          Flexible(
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                      visualDensity: VisualDensity.compact,
                    ),

                    hintText: "700XXXXXX1",
                    maxLength: 10,
                    keyboardType: TextInputType.phone,
                    validator: (val) => KValidation.phone(val),
                  ),
                  height20,
                  Label("Receiver Details").title,
                  height10,

                  KField(
                    controller: receiverName,
                    label: "Name",
                    hintText: "Receiver name",
                    validator: (val) => KValidation.required(val),
                  ),
                  height10,
                  KField(
                    controller: receiverPhone,
                    label: "Phone Number",
                    prefixText: receiverSelectedCountry,
                    prefix: IconButton(
                      onPressed: () async {
                        final res = await showDialog(
                          context: context,
                          builder: (context) => CountryDialog(),
                        );

                        receiverSelectedCountry = res["code"];
                        setState(() {});
                      },
                      icon: Row(
                        spacing: 5,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Label(
                            receiverSelectedCountry,
                            fontSize: 15,
                            height: 1.5,
                          ).regular,
                          Flexible(
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                      visualDensity: VisualDensity.compact,
                    ),

                    hintText: "700XXXXXX1",
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (val) => KValidation.phone(val),
                  ),

                  height20,
                  Label("Payment Details").title,
                  height15,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Label("Estimated Time").regular,
                      Label(
                        "${(widget.serviceData['time_distance'] / 60).round()} mins",
                      ).regular,
                    ],
                  ),
                  height5,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Label("Distance (Km)").regular,
                      Label(
                        "$distanceText Km",
                      ).regular, // Use calculated distance
                    ],
                  ),
                  height5,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Label("Price (NPR)").regular,
                      Label(
                        kCurrencyFormat(price),
                      ).regular, // Use calculated price
                    ],
                  ),
                  height5,
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
                  height5,
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
                  div,
                  height15,
                  Label("Promo Code").title,
                  height10,
                  if (promoData.isEmpty)
                    KField(
                      controller: promoCode,
                      hintText: "Have a promo code?",
                      textCapitalization: TextCapitalization.characters,
                      suffix: TextButton(
                        onPressed: validatePromoCode,
                        child:
                            Label(
                              "Use Promo",
                              color: StatusText.neutral,
                              weight: 900,
                            ).regular,
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
                          child: Icon(
                            Icons.close,
                            color: Kolor.scaffold,
                            size: 15,
                          ),
                        ),
                      ],
                    ),
                  height15,
                  Label("Payment Method").title,
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
                ],
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(kPadding),
            child: KButton(
              onPressed: orderShipment,
              label: "Order",
              style: KButtonStyle.expanded,
            ),
          ),
        ),
      ),
    );
  }
}
