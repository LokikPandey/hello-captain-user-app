import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Helper/Location_Helper.dart';
import 'package:hello_captain_user/Pages/Orders/Order_Detail_Map_Widget.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Repository/contact_repo.dart';
import 'package:hello_captain_user/Repository/orders_repo.dart';
import 'package:hello_captain_user/Resources/app-data.dart';
import 'package:hello_captain_user/Resources/app_config.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:location/location.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class Order_Detail_UI extends ConsumerStatefulWidget {
  final String transactionId;
  final String driverId;
  const Order_Detail_UI({
    super.key,
    required this.transactionId,
    required this.driverId,
  });

  @override
  ConsumerState<Order_Detail_UI> createState() => _Order_Detail_UIState();
}

class _Order_Detail_UIState extends ConsumerState<Order_Detail_UI> {
  final isLoading = ValueNotifier(false);
  int selectedRating = 0;

  void shareRatings() async {
    try {
      isLoading.value = true;
      final uid = ref.read(userProvider)?.id;
      if (uid == null) throw "User not logged in!";
      final res = await OrdersRepo.shareRatings(
        body: {
          "customer_id": uid,
          "driver_id": widget.driverId,
          "rating": "$selectedRating",
          "transaction_id": widget.transactionId,
          "note": "",
        },
      );
      KSnackbar(
        context,
        message: res["message"],
        error: res["message"] != 'success',
      );
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    } finally {
      isLoading.value = false;
    }
  }

  void cancelRide() async {
    try {
      isLoading.value = true;

      final res = await OrdersRepo.cancelOrder(
        body: {"transaction_id": widget.transactionId},
      );

      KSnackbar(
        context,
        message: res["message"] ?? "Ride canceled",
        error: res["status"] != true,
      );

      if (res["status"] == true) {
        // Refresh the order details
        ref.invalidate(
          orderDetailFuture(
            jsonEncode({
              "driverId": widget.driverId,
              "transactionId": widget.transactionId,
            }),
          ),
        );
      }
    } catch (e) {
      KSnackbar(context, message: "$e", error: true);
    } finally {
      isLoading.value = false;
    }
  }

  void confirmCancelRide() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text("Cancel Ride?"),
            content: Text("Are you sure you want to cancel this ride?"),
            actions: [
              TextButton(
                child: Text("No"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text("Yes"),
                onPressed: () {
                  Navigator.pop(context);
                  cancelRide();
                },
              ),
            ],
          ),
    );
  }

void sendSos() async {
  try {
    const emergencyNumber = '100'; // Nepal Police emergency number
    await launchUrlString('tel:$emergencyNumber');
  } catch (e) {
    KSnackbar(context, message: "Unable to make SOS call: $e", error: true);
  }
}


  @override
  Widget build(BuildContext context) {
    final orderDetail = ref.watch(
      orderDetailFuture(
        jsonEncode({
          "driverId": widget.driverId,
          "transactionId": widget.transactionId,
        }),
      ),
    );

    return RefreshIndicator(
      onRefresh:
          () => ref.refresh(
            orderDetailFuture(
              jsonEncode({
                "driverId": widget.driverId,
                "transactionId": widget.transactionId,
              }),
            ).future,
          ),
      child: KScaffold(
        isLoading: isLoading,
        appBar: KAppBar(context, title: "Order #${widget.transactionId}"),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(kPadding),
            child: orderDetail.when(
              data: (data) {
                final order = data['data'][0];
                final driver = data['driver'][0];
                final items = data['item'];
                // log("$data");
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Label("Status", fontSize: 12).subtitle,
                            Label(
                              "${kStatus[order['status']]}",
                              color: statusColorMap[kStatus[order['status']]],
                            ).regular,
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Label(
                              "Service",
                              fontSize: 12,
                              color: Kolor.primary,
                            ).subtitle,
                            Label("${order['service']}").regular,
                          ],
                        ),
                      ],
                    ),
                    height20,

                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Order_Detail_Map_Widget(
                        startPosition: Position(
                          parseToDouble(order['start_longitude']),
                          parseToDouble(order['start_latitude']),
                        ),
                        endPosition: Position(
                          parseToDouble(order['end_longitude']),
                          parseToDouble(order['end_latitude']),
                        ),
                        serviceId: order["service_order"],
                        driverId: order["driver_id"],
                      ),
                    ),

                    if (driver["id"] != null)
                      KCard(
                        margin: EdgeInsets.only(bottom: 25),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    "$driverImageBaseUrl/${driver['photo']}",
                                  ),
                                ),
                                width10,
                                Expanded(
                                  child:
                                      Label("${driver['driver_name']}").regular,
                                ),
                                width15,
                                IconButton(
                                  onPressed: () {
                                    context.push(
                                      "/chat/detail/${driver['id']}",
                                      extra: {
                                        "pic":
                                            "$driverImageBaseUrl/${driver['photo']}",
                                        "name": driver['driver_name'],
                                      },
                                    );
                                  },
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  icon: Row(
                                    spacing: 5,
                                    children: [
                                      Icon(Icons.chat, size: 19),
                                      Label('Chat').regular,
                                    ],
                                  ),
                                ),
                                width10,

                                IconButton(
                                  onPressed: () async {
                                    try {
                                      await launchUrlString(
                                        "tel:${driver['countrycode']} ${driver['phone']}",
                                      );
                                    } catch (e) {
                                      KSnackbar(
                                        context,
                                        message: "Unable to call the driver!",
                                        error: true,
                                      );
                                    }
                                  },
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: StatusText.neutral,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: Row(
                                    spacing: 5,
                                    children: [
                                      Icon(Icons.call, size: 19),
                                      Label(
                                        'Call',
                                        weight: 700,
                                        color: Colors.white,
                                      ).regular,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            height10,
                            KCard(
                              radius: 10,
                              width: double.infinity,
                              color: Kolor.scaffold,
                              child: Row(
                                spacing: 15,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Label(
                                          "${driver['brand']}, ${driver['type']}",
                                        ).regular,
                                        Label(
                                          "${driver['vehicle_registration_number']}",
                                        ).regular,
                                        Label(
                                          "Color: ${driver['color']}",
                                          fontSize: 10,
                                        ).subtitle,
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: StatusText.warning,
                                      ),
                                      Label(
                                        parseToDouble(
                                          driver['rating'],
                                        ).toStringAsFixed(1),
                                      ).regular,
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Label(
                      "Order On - ${kDateFormat(order['order_time'], showTime: true)}",
                    ).subtitle,
                    height15,
                    Label("Pickup", color: Kolor.primary).regular,
                    height5,
                    if (order["merchant_name"] != null)
                      Label(
                        "${order['merchant_name']}, +${order['merchant_telephone_number']}",
                        weight: 900,
                      ).regular,

                    if (order["sender_name"] != null)
                      Label(
                        "${order['sender_name']}, +${order['sender_phone']}",
                        weight: 900,
                      ).regular,

                    Label("${order['pickup_address']}").regular,
                    height15,
                    Label("Destination", color: Kolor.primary).regular,
                    height5,
                    if (order["receiver_name"] != null)
                      Label(
                        "${order['receiver_name']}, +${order['receiver_phone']}",
                        weight: 900,
                      ).regular,
                    Label("${order['destination_address']}").regular,
                    height15,
                    if (order['validation_code'] != null) ...[
                      Label("Delivery Code", color: Kolor.primary).regular,
                      height5,
                      Label("${order['validation_code']}").regular,
                      height15,
                    ],

                    if (items.length > 0) ...[
                      Label("Items", color: Kolor.primary).regular,
                      ...items.map<Widget>(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child:
                                    Label(
                                      "${item['item_name']} x${item['item_amount']}",
                                    ).regular,
                              ),
                              Label(
                                kCurrencyFormat(
                                  parseToDouble(item['total_cost']) / 100,
                                ),
                              ).regular,
                            ],
                          ),
                        ),
                      ),
                      height15,
                    ],

                    if (order['goods_item'] != null) ...[
                      Label("Goods Item", color: Kolor.primary).regular,
                      height5,
                      Label("${order['goods_item']}").regular,
                      height15,
                    ],
                    Label("Payment Breakdown", color: Kolor.primary).regular,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Label("Net Payable").regular,
                        Label(kCurrencyFormat(order['price'])).regular,
                      ],
                    ),
                    height15,
                    Label("Payment Method", color: Kolor.primary).regular,
                    Label(
                      order['wallet_payment'] == "1" ? "Wallet" : "Cash",
                    ).regular,

                    height15,
                    if (kStatus[order['status']] == "Complete")
                      ratingsAndReview(order),

                    if (kStatus[order['status']] == "Pending" ||
                        kStatus[order['status']] == "Driver Found" ||
                        kStatus[order['status']] == "Accepted" ||
                        kStatus[order['status']] == "Process")
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: SizedBox(
                          width: double.infinity, // 👈 makes it full width
                          child: KButton(
                            onPressed: confirmCancelRide,
                            label: "Cancel Ride",
                            backgroundColor: Colors.red,
                            style: KButtonStyle.regular,
                            radius: 8,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                    kHeight(100),
                  ],
                );
              },
              error: (error, stackTrace) => Label("$error").subtitle,
              loading: () => kSmallLoading,
            ),
          ),
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: sendSos,
          elevation: 0,
          backgroundColor: StatusText.danger,
          foregroundColor: Colors.white,
          child: Icon(Icons.sos),
        ),
      ),
    );
  }

  Widget ratingsAndReview(dynamic data) => Consumer(
    builder: (context, ref, child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Label("Share Ratings", color: Kolor.primary).regular,

          Row(
            children: [
              Flexible(
                child: Center(
                  child: RatingBar.builder(
                    initialRating: parseToDouble(data['rate']),
                    minRating: 1,
                    glow: false,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    unratedColor: Colors.grey.shade300,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder:
                        (context, _) =>
                            const Icon(Icons.star, color: StatusText.warning),
                    onRatingUpdate: (rating) {
                      setState(() {
                        selectedRating = rating.toInt();
                      });
                    },
                  ),
                ),
              ),
              KButton(
                onPressed: shareRatings,
                label: "Rate",
                style: KButtonStyle.regular,
                radius: 5,
                backgroundColor: StatusText.success,
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              ),
            ],
          ),
        ],
      );
    },
  );
}
