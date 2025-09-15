// lib/UI/Services/passenger_transportation_ui_2.dart

// ignore_for_file: unused_result

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Essentials/kField.dart';
import 'package:hello_captain_user/Helper/Location_Helper.dart';
import 'package:hello_captain_user/Models/driver_model.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Repository/home_repo.dart';
import 'package:hello_captain_user/Repository/mapBox_repo.dart';
import 'package:hello_captain_user/Repository/notification_repo.dart';
import 'package:hello_captain_user/Repository/purchasing_repo.dart';
import 'package:hello_captain_user/Repository/ride_repo.dart';
import 'package:hello_captain_user/Repository/subscription_repo.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:location/location.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Essentials/kField.dart';
import 'package:hello_captain_user/Models/driver_model.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Repository/home_repo.dart';
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

enum RideSelectionState { ServiceSelection, Checkout, Searching }

class PassengerTransportationUI2 extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialPickup;
  final Map<String, dynamic> initialDrop;

  const PassengerTransportationUI2({
    super.key,
    required this.initialPickup,
    required this.initialDrop,
  });

  @override
  ConsumerState<PassengerTransportationUI2> createState() =>
      _PassengerTransportationUI2State();
}

class _PassengerTransportationUI2State
    extends ConsumerState<PassengerTransportationUI2> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final isLoading = ValueNotifier(false);

  late Position pickupCoordinates;
  late Map<String, dynamic> pickupAddressData;
  PointAnnotation? pickupPoint;
  PointAnnotation? dropPoint;

  late Position dropCoordinates;
  late Map<String, dynamic> dropAddressData;

  MapboxMap? mapController;
  late PointAnnotationManager pointManager;
  late PolylineAnnotationManager polylineManager;
  RideSelectionState currentState = RideSelectionState.ServiceSelection;
  Map<String, dynamic>? selectedServiceData;

  double duration = 0;
  double distanceInMeters = 0;
  int price = 0;
  double insurance = 10.0;
  double minimumFare = 50.0;
  double costPerKm = 10.0;
  int netPayable = 0;
  int promoDiscount = 0;
  int subscriptionDiscount = 0;
  int subscriptionPercent = 0;
  int subscriptionMaxDiscount = 0;
  double servicediscount = 0;
  int serviceDiscountAmount = 0;
  final promoCode = TextEditingController();

  String paymentMethod = "Wallet";
  String distanceText = "";
  bool _isRouteCalculated = false; // <-- NEW: To track if distance is ready

  final searchCounter = ValueNotifier(120);
  List<PointAnnotation> driversMarkers = [];
  List<DriverModel> driversList = [];
  Map<String, dynamic> promoData = {};
  Timer? _searchTimer;

  String? transactionId;

  @override
  void initState() {
    super.initState();

    pickupAddressData = widget.initialPickup;
    dropAddressData = widget.initialDrop;
    pickupCoordinates =
        Position(widget.initialPickup['lng'], widget.initialPickup['lat']);
    dropCoordinates =
        Position(widget.initialDrop['lng'], widget.initialDrop['lat']);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _initializeMapWithRoute();
    });
  }

  @override
  void dispose() {
    promoCode.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMapWithRoute() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    if (mapController != null && mounted) {
      await setMarkerPoint("Pickup", pickupCoordinates);
      await setMarkerPoint("Drop", dropCoordinates);
      await setPolyline(); // This will now set _isRouteCalculated to true
      mapController!.easeTo(
        await MapboxRepo.cameraOptionsForBounds(
          mapController: mapController!,
          pickup: pickupCoordinates,
          drop: dropCoordinates,
        ),
        MapAnimationOptions(),
      );
      await setDriverMarkersForServiceSelection();
    }
    isLoading.value = false;
  }

  Future<void> setDriverMarkers(String serviceId) async {
    try {
      final driverRes = await ref.read(listRideFuture(serviceId).future);
      driversList = (driverRes['data'] as List)
          .map((e) => DriverModel.fromMap(e))
          .toList();

      for (var marker in driversMarkers) {
        if (mounted) await pointManager.delete(marker);
      }
      driversMarkers.clear();

      if (driversList.isNotEmpty) {
        for (DriverModel driver in driversList) {
          await setMarkerPoint(
            "Driver",
            Position(
              parseToDouble(driver.longitude),
              parseToDouble(driver.latitude),
            ),
            bearing: parseToDouble(driver.bearing),
          );
        }
      }
    } catch (e) {
      log("Error in setDriverMarkers: $e");
    }
  }

  Future<void> setDriverMarkersForServiceSelection() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;
      
      final homeData = await ref.read(homeFuture(jsonEncode({
        "id": user.id,
        "latitude": 0,
        "longitude": 0,
        "phone_number": user.phone_number,
      })).future);

      final transportServices = (homeData["service"] as List)
          .where((s) => s['title'] == 'Passenger Transportation')
          .toList();

      driversList.clear();
      Set<String> uniqueDriverIds = {};

      for (var service in transportServices) {
        final driverRes =
            await ref.read(listRideFuture(service["service_id"]).future);
        final serviceDrivers = (driverRes['data'] as List)
            .map((e) => DriverModel.fromMap(e))
            .toList();
        for (var driver in serviceDrivers) {
          if (uniqueDriverIds.add(driver.id)) {
            driversList.add(driver);
          }
        }
      }

      for (var marker in driversMarkers) {
        if (mounted) await pointManager.delete(marker);
      }
      driversMarkers.clear();

      if (driversList.isNotEmpty) {
        for (DriverModel driver in driversList) {
          await setMarkerPoint(
            "Driver",
            Position(
              parseToDouble(driver.longitude),
              parseToDouble(driver.latitude),
            ),
            bearing: parseToDouble(driver.bearing),
          );
        }
      }
    } catch (e) {
      log("Error fetching all drivers: $e");
    }
  }

  Future<void> sendNotificationToDrivers(
      Map<String, dynamic> transactionData) async {
    if (selectedServiceData == null) return;
    try {
      final user = ref.read(userProvider);
      if (user == null) throw "User not logged in!";

      transactionData["layanan"] = user.customer_fullname;
      transactionData["layanandesc"] = selectedServiceData!['service'];
      transactionData["bid"] = "true";
      for (DriverModel driver in driversList) {
        await NotificationRepo.sendNotification(
          driver.reg_id,
          "New ${selectedServiceData!['service']} Order Available",
          transactionData,
        );
      }
    } catch (e) {
      if (mounted) KSnackbar(context, message: e.toString(), error: true);
    }
  }

  Future<void> setMarkerPoint(
    String type,
    Position pos, {
    double bearing = 0,
  }) async {
    if (!mounted) return;
    try {
      isLoading.value = true;

      switch (type) {
        case "Pickup":
          final ByteData bytes = await rootBundle.load('$kImagePath/pin.png');
          final Uint8List imageData = bytes.buffer.asUint8List();
          if (pickupPoint != null) {
            await pointManager.delete(pickupPoint!);
          }
          final point = PointAnnotationOptions(
            geometry: Point(coordinates: pos),
            image: imageData,
            iconSize: .2,
          );
          pickupPoint = await pointManager.create(point);
          break;

        case "Drop":
          final ByteData bytes =
              await rootBundle.load('$kImagePath/drop-pin.png');
          final Uint8List imageData = bytes.buffer.asUint8List();
          if (dropPoint != null) {
            await pointManager.delete(dropPoint!);
          }
          final point = PointAnnotationOptions(
            geometry: Point(coordinates: pos),
            image: imageData,
            iconSize: .2,
          );
          dropPoint = await pointManager.create(point);
          break;

        case "Driver":
          final mapsIconsId = selectedServiceData?["icon_driver"] ?? "0";
          final ByteData bytes = await rootBundle.load(
            '${mapsIcons[mapsIconsId]}',
          );
          final Uint8List imageData = bytes.buffer.asUint8List();

          final point = PointAnnotationOptions(
            geometry: Point(coordinates: pos),
            image: imageData,
            iconSize: .7,
            iconRotate: bearing,
          );
          final driverMarker = await pointManager.create(point);

          driversMarkers.add(driverMarker);
          break;
        default:
      }
    } catch (e) {
      if (mounted) KSnackbar(context, message: "Marker Error: $e", error: true);
    } finally {
      if(mounted) isLoading.value = false;
    }
  }

  Future<void> setPolyline() async {
    try {
      isLoading.value = true;
      final res = await MapboxRepo().getDirections(
        pickupCoordinates,
        dropCoordinates,
      );
      if (res != null) {
        distanceInMeters = parseToDouble(res["distance"]);
        duration = parseToDouble(res["duration"]);

        if (mounted) await polylineManager.deleteAll();
        final coordinatesList = MapboxRepo().decodePolylines(
          res["encodedPolylines"],
        );

        PolylineAnnotationOptions polylines = PolylineAnnotationOptions(
          geometry: LineString(coordinates: coordinatesList),
          lineWidth: 3,
        );

        if (mounted) await polylineManager.create(polylines);
        
        // --- NEW: Set state to true after distance is calculated ---
        if(mounted){
          setState(() {
            _isRouteCalculated = true;
          });
        }
      }
    } catch (e) {
      if (mounted)
        KSnackbar(context, message: "Polyline Error: $e", error: true);
    } finally {
      if(mounted) isLoading.value = false;
    }
  }

  Future<void> fetchSubscriptionDetails() async {
    if (selectedServiceData == null) return;
    try {
      subscriptionPercent = 0;
      subscriptionMaxDiscount = 0;

      final subData = await ref.read(activeSubscriptionFuture.future);

      if ("${subData['service_types']}"
          .split(",")
          .contains(selectedServiceData!['ext_id'])) {
        subscriptionPercent = kRound(subData["discount_percent"]);
        subscriptionMaxDiscount = kRound(subData["max_discount"]);
      }
    } catch (e) {
      log("Subscription error (can be ignored if not subscribed): $e");
    }
  }

  Future<void> validatePromoCode() async {
    if (selectedServiceData == null) return;
    try {
      promoDiscount = 0;
      FocusScope.of(context).unfocus();
      isLoading.value = true;

      final res = await RideRepo.validatePromocode(
        selectedServiceData!['service_id'],
        promoCode.text.trim(),
      );
      if (res['code'] != '200') throw res['message'] ?? 'Promo Code invalid!';

      if (mounted) KSnackbar(context, message: "Promo applied!");
      double nominal = parseToDouble(res['nominal']);

      promoData = {
        "discount": (netPayable * (nominal / 100)),
        "code": promoCode.text,
      };
      promoDiscount = kRound(netPayable * (nominal / 100));
      if (res['type'] == 'fix') {
        promoData = {"discount": kRound(nominal), "code": promoCode.text};
        promoDiscount = kRound(nominal);
      }

      await calculateBreakdown();
    } catch (e) {
      if (mounted) KSnackbar(context, message: e.toString(), error: true);
    } finally {
      if(mounted) isLoading.value = false;
    }
  }

  Future<void> calculateBreakdown() async {
    if (selectedServiceData == null) return;
    try {
      isLoading.value = true;

      costPerKm = parseToDouble(selectedServiceData!["cost"]) / 100;
      minimumFare =
          parseToDouble(selectedServiceData!["minimum_cost"]) / 100;
      insurance =
          parseToDouble(selectedServiceData!["insurance"].toString()) / 100;
      servicediscount =
          parseToDouble(selectedServiceData!["discount"].toString());

      final user = ref.read(userProvider);
      if (user == null) throw "User not logged in!";

      double distanceInKm = distanceInMeters / 1000.0;
      double maxDistance =
          parseToDouble(selectedServiceData!["maks_distance"]);

      if (distanceInKm <= maxDistance) {
        distanceText = distanceInKm.toStringAsFixed(1);
        double extraDistance = (distanceInKm - 1).clamp(0, double.infinity);
        double extraCost = costPerKm * extraDistance;
        price = kRound(minimumFare + extraCost);

        await fetchSubscriptionDetails();

        subscriptionDiscount = kRound(price * (subscriptionPercent / 100));
        if (subscriptionDiscount > subscriptionMaxDiscount) {
          subscriptionDiscount = subscriptionMaxDiscount;
        }

        int priceAfterSubscriptionDiscount = price - subscriptionDiscount;

        if (promoData.isNotEmpty) {
          if (promoDiscount > priceAfterSubscriptionDiscount) {
            promoDiscount = priceAfterSubscriptionDiscount;
          }
        } else {
          promoDiscount = 0;
        }

        int priceAfterSubAndPromo =
            price - subscriptionDiscount - promoDiscount;
        serviceDiscountAmount = kRound(
          priceAfterSubAndPromo * (servicediscount / 100),
        );

        int ins = insurance.round();
        netPayable = price -
            subscriptionDiscount -
            promoDiscount -
            serviceDiscountAmount +
            ins;

        if (netPayable < 1) {
          int diff = 1 - netPayable;
          serviceDiscountAmount -= diff;
          if (serviceDiscountAmount < 0) serviceDiscountAmount = 0;
          netPayable = 1;
        }

        paymentMethod = "Wallet";
        if (user.balance < netPayable) {
          paymentMethod = "Cash";
        }

        if(mounted) setState(() {});
      } else {
        if (mounted)
          KSnackbar(
              context,
              message:
                  "The distance of $distanceInKm Km is outside the allowed range of $maxDistance Km",
              error: true);
      }
    } catch (e) {
      if (mounted)
        KSnackbar(context, message: "Error calculating price: $e", error: true);
    } finally {
      if(mounted) isLoading.value = false;
    }
  }

  Future<void> orderRide() async {
    if (selectedServiceData == null) return;
    try {
      if (driversList.isEmpty) {
        KSnackbar(context, message: "No drivers available!", error: true);
        return;
      }
      isLoading.value = true;
      final user = ref.read(userProvider);
      if (user == null) throw "User not logged in!";
      final data = {
        "customer_id": user.id,
        "service_order": selectedServiceData!["service_id"],
        "start_latitude": pickupCoordinates.lat,
        "start_longitude": pickupCoordinates.lng,
        "end_latitude": dropCoordinates.lat,
        "end_longitude": dropCoordinates.lng,
        "distance": distanceInMeters,
        "price": netPayable,
        "estimasi": "$duration",
        "pickup_address": pickupAddressData["address"],
        "destination_address": dropAddressData["address"],
        "promo_discount": promoDiscount,
        "wallet_payment": paymentMethod == "Wallet" ? 1 : 0,
      };

      final res = await RideRepo.sendOrderRequest(data);

      setState(() {
        transactionId = res['data'][0]['id'];
      });
      if (mounted) KSnackbar(context, message: "Request Generated!");

      isLoading.value = false;
      setState(() {
        currentState = RideSelectionState.Searching;
      });
      _sheetController.animateTo(
        .8,
        duration: const Duration(milliseconds: 200),
        curve: Curves.ease,
      );

      sendNotificationToDrivers(res['data'][0]);

      await FirebaseFirestore.instance
          .collection("ride_bids")
          .doc(res['data'][0]['id'])
          .set(res['data'][0]);

      searchCounter.value = 120;
      _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (searchCounter.value == 0) {
          timer.cancel();
          final status = await checkStatus(res['data'][0]['id']);

          if (status == 1) {
            _searchCancel();
          }
        } else {
          searchCounter.value--;
        }
      });
    } catch (e) {
      if (mounted) KSnackbar(context, message: e.toString(), error: true);
    } finally {
      if(mounted) isLoading.value = false;
    }
  }

  void _searchCancel() {
    _searchTimer?.cancel();

    if(mounted) {
      setState(() {
        currentState = RideSelectionState.Checkout;
      });
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Label("No Driver Found").title,
        content: Label(
          "Unfortunately, no driver accepted your ride request. Please try again or go back to home.",
        ).regular,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go("/");
            },
            child: Label("Go to Home", color: StatusText.danger).regular,
          ),
          KButton(
            onPressed: () {
              Navigator.of(context).pop();
              orderRide();
            },
            radius: 100,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            label: "Try Again",
          ),
        ],
      ),
    );
  }

  Future<int> checkStatus(String transactionId) async {
    try {
      isLoading.value = true;
      final data = {"transaction_id": transactionId};
      final res = await RideRepo.checkOrderRequest(data);
      return int.parse("${res['data'][0]['status']}");
    } catch (e) {
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  void acceptBid(String driverId, double amount) async {
    if (selectedServiceData == null) return;
    try {
      isLoading.value = true;
      if (transactionId == null) throw "Transaction ID Null!";
      await PurchasingRepo.acceptBid(
        transactionId: transactionId!,
        driverId: driverId,
        amount: amount.round(),
      );

      if (mounted) KSnackbar(context, message: "Bid Accepted!");

      final status = await checkStatus(transactionId!);

      if (status > 1) {
        context.go(
          "/confirmation",
          extra: {
            'subtitle': "${selectedServiceData!['service']} Booked",
            'description': "You can track in the order details page.",
            'transactionId': transactionId!,
            'driverId': driverId,
          },
        );
      } else {
        _searchCancel();
      }
    } catch (e) {
      if (mounted) KSnackbar(context, message: e.toString(), error: true);
    } finally {
      isLoading.value = false;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return KScaffold(
      isLoading: isLoading,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: screenHeight * .7,
              child: MapWidget(
                cameraOptions: CameraOptions(
                  center: Point(
                    coordinates: Position(85.292377, 27.689283),
                  ),
                  zoom: 15,
                ),
                onMapCreated: (controller) async {
                  mapController = controller;
                  if (mapController != null) {
                    mapController!.location.updateSettings(
                       LocationComponentSettings(enabled: true),
                    );
                  }
                  pointManager = await mapController!.annotations
                      .createPointAnnotationManager();
                  polylineManager = await mapController!.annotations
                      .createPolylineAnnotationManager();
                  if (mounted) setState(() {});
                  _initializeMapWithRoute();
                },
              ),
            ),
            headerActions(),
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              builder: (context, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Kolor.scaffold,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(kPadding)
                                  .copyWith(bottom: 0),
                              child: Column(
                                children: [
                                  Center(
                                    child: KCard(
                                      color: Kolor.border,
                                      width: 60,
                                      height: 7,
                                      radius: 100,
                                    ),
                                  ),
                                  height10,
                                ],
                              ),
                            ),
                            sheetBody(),
                          ],
                        ),
                      ),
                    ),
                    if (currentState == RideSelectionState.Checkout)
                      Padding(
                        padding:
                            const EdgeInsets.all(kPadding).copyWith(top: 0),
                        child: KButton(
                          onPressed: orderRide,
                          style: KButtonStyle.expanded,
                          label: "Place Order",
                        ),
                      )
                    else if (currentState == RideSelectionState.Searching)
                      KCard(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(10),
                        color: Kolor.card,
                        child: Column(
                          spacing: 15,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Label("Bid Ends in", fontSize: 17).title,
                                ValueListenableBuilder(
                                  valueListenable: searchCounter,
                                  builder: (context, value, child) => Label(
                                    formatDuration(value),
                                    fontSize: 17,
                                  ).title,
                                ),
                              ],
                            ),
                            KButton(
                              onPressed: transactionId != null
                                  ? () async {
                                      _searchCancel();
                                    }
                                  : null,
                              label: "Cancel Bid",
                              backgroundColor: StatusText.danger,
                              style: KButtonStyle.expanded,
                              radius: 10,
                            ),
                          ],
                        ),
                      )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget headerActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              style: IconButton.styleFrom(backgroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget sheetBody() {
    switch (currentState) {
      case RideSelectionState.ServiceSelection:
        return _serviceSelectionStage();
      case RideSelectionState.Checkout:
        return _checkoutStage();
      case RideSelectionState.Searching:
        return _searchingStage();
      default:
        return const Center(child: Text("An error has occurred."));
    }
  }

  Widget _serviceSelectionStage() {
    final user = ref.watch(userProvider);
    if (user == null) {
      return const Center(child: Text("Please log in to see services."));
    }

    final homeDataAsync = ref.watch(homeFuture(jsonEncode({
      "id": user.id,
      "latitude": 0,
      "longitude": 0,
      "phone_number": user.phone_number,
    })));

    return homeDataAsync.when(
      data: (data) {
        final serviceList = data['service'] as List<dynamic>? ?? [];
        final transportServices = serviceList
            .where((s) => s['title'] == 'Passenger Transportation')
            .toList();

        if (transportServices.isEmpty) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Label(
                    "No passenger transportation services available at the moment.")
                .regular,
          ));
        }

        // --- NEW: Wait for route calculation before showing services ---
        if (!_isRouteCalculated) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  height10,
                  Text("Calculating route and fares..."),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            ListView.separated(
              padding: const EdgeInsets.all(kPadding),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: transportServices.length,
              separatorBuilder: (_, __) => height10,
              itemBuilder: (context, index) {
                final service = transportServices[index] as Map<String, dynamic>;
                final isSelected = selectedServiceData != null &&
                    selectedServiceData!['service_id'] == service['service_id'];

                final costPerKmS = parseToDouble(service["cost"]) / 100;
                final minFareS =
                    parseToDouble(service["minimum_cost"]) / 100;
                final distInKm = distanceInMeters / 1000.0;
                final extraDist = (distInKm - 1).clamp(0, double.infinity);
                final estimatedPrice = kRound(minFareS + (costPerKmS * extraDist));

                final iconUrl = service['icon'] != null
                    ? "$serviceImageBaseUrl/${service['icon']}"
                    : null;

                return KCard(
                  onTap: () async {
                    setState(() {
                      selectedServiceData = service;
                    });
                  },
                  color: isSelected ? Kolor.primary.withOpacity(0.1) : Kolor.card,
                  borderWidth: isSelected ? 2 : 1,
                  borderColor: isSelected ? Kolor.primary : Kolor.border,
                  child: Row(
                    children: [
                      if (iconUrl != null)
                        Image.network(
                          iconUrl,
                          height: 50,
                          width: 50,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.directions_car,
                                  size: 50, color: Colors.grey),
                        )
                      else
                        const Icon(Icons.directions_car,
                            size: 50, color: Colors.grey),
                      width15,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Label(service['service'] ?? 'Unknown Service', weight: 700)
                                .regular,
                            Label(service['description'] ?? '', fontSize: 11)
                                .subtitle,
                          ],
                        ),
                      ),
                      Label(kCurrencyFormat(estimatedPrice),
                              weight: 800, fontSize: 16)
                          .title,
                    ],
                  ),
                );
              },
            ),
            if (selectedServiceData != null)
              Padding(
                padding: const EdgeInsets.all(kPadding).copyWith(top: 10),
                child: KButton(
                  label: "Confirm Ride",
                  style: KButtonStyle.expanded,
                  onPressed: () async {
                    setState(() {
                      currentState = RideSelectionState.Checkout;
                    });
                    await setDriverMarkers(selectedServiceData!['service_id']);
                    await calculateBreakdown();
                  },
                ),
              )
          ],
        );
      },
      error: (e, st) => Center(child: Text("Could not load services: $e")),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _checkoutStage() {
    final user = ref.watch(userProvider);
    if (user == null) return const Center(child: Text("User not found"));
    if (selectedServiceData == null)
      return const Center(child: Text("No service selected"));

    return Padding(
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- NEW: Back button to change service ---
          KCard(
            padding: const EdgeInsets.all(10),
            child: Row(
              spacing: 15,
              children: [
                if (selectedServiceData!['icon'] != null)
                  Image.network(
                    "$serviceImageBaseUrl/${selectedServiceData!["icon"]}",
                    height: 50,
                    width: 50,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error, size: 50),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Label(selectedServiceData!['service'], fontSize: 17)
                          .regular,
                      Label(selectedServiceData!['description'] ?? "Ride Service",
                              fontSize: 11)
                          .subtitle,
                    ],
                  ),
                ),
                TextButton(onPressed: (){
                   setState(() {
                      currentState = RideSelectionState.ServiceSelection;
                      selectedServiceData = null;
                      promoData.clear();
                      promoDiscount = 0;
                      setDriverMarkersForServiceSelection();
                    });
                }, child: Label("Change").regular)
              ],
            ),
          ),

          Divider(height: 30, color: Kolor.border),
          Label("Payment Details").title,
          height15,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Label("Estimated Time").regular,
              Label(secondsToHoursMinutes(duration)).regular,
            ],
          ),
          height5,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Label("Distance (Km)").regular,
              Label("$distanceText Km").regular,
            ],
          ),
          height5,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Label("Price (NPR)").regular,
              Label(kCurrencyFormat(price)).regular,
            ],
          ),
          height5,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Label("Base Fare").regular,
              Label(kCurrencyFormat(minimumFare)).regular,
            ],
          ),
          height5,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Label("Promo Discount", color: StatusText.success).regular,
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
              Label("Service Discount", color: StatusText.success).regular,
              Label(
                kCurrencyFormat((serviceDiscountAmount)),
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
          height5,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Label("Insurance").regular,
              Label(kCurrencyFormat(insurance)).regular,
            ],
          ),
          const Divider(height: 20, thickness: 1.5),
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
          Divider(height: 30, color: Kolor.border),
          Label("Promo Code").title,
          height15,
          if (promoData.isEmpty)
            KField(
              controller: promoCode,
              hintText: "Have a promo code?",
              textCapitalization: TextCapitalization.characters,
              suffix: TextButton(
                onPressed: validatePromoCode,
                child: Label(
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
                  color: Colors.lime.shade100,
                  width: double.infinity,
                  child: Row(
                    spacing: 10,
                    children: [
                      const Icon(Icons.discount),
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
                  padding: const EdgeInsets.all(5),
                  radius: 100,
                  color: Kolor.secondary,
                  onTap: () {
                    setState(() {
                      promoData = {};
                      promoDiscount = 0;
                      calculateBreakdown();
                    });
                  },
                  child: const Icon(Icons.close,
                      color: Kolor.scaffold, size: 15),
                ),
              ],
            ),
          Divider(height: 30, color: Kolor.border),
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
                  backgroundColor: paymentMethod == "Wallet"
                      ? Kolor.secondary
                      : Kolor.card,
                  child: Icon(
                    Icons.check,
                    color: paymentMethod == "Wallet"
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 5,
                            ),
                            color: Kolor.secondary,
                            child: Label(
                              kCurrencyFormat(user.balance),
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
                      paymentMethod == "Cash" ? Kolor.secondary : Kolor.card,
                  child: Icon(
                    Icons.check,
                    color: paymentMethod == "Cash"
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
    );
  }

  Center _searchingStage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kPadding),
        child: Column(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (transactionId != null)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection("ride_bids")
                    .doc(transactionId!)
                    .collection("bids")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return kNoData();
                  } else if (snapshot.hasData) {
                    if (snapshot.data!.docs.isEmpty) {
                      return kNoData(
                        title: "Searching for drivers...",
                        subtitle:
                            'Please wait for riders to bid for this ride.',
                      );
                    }

                    return Column(
                      spacing: 15,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 10,
                          children: [
                            Label("Available Bids", weight: 900).title,
                            CircleAvatar(
                              radius: 12,
                              child: Label(
                                "${snapshot.data!.docs.length}",
                                weight: 900,
                                fontSize: 12,
                              ).regular,
                            ),
                          ],
                        ),
                        ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (context, index) => height15,
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final bid = snapshot.data!.docs[index].data();

                            return KCard(
                              child: Row(
                                spacing: 15,
                                children: [
                                  Expanded(
                                    child: Label(
                                      kCurrencyFormat(bid["amount"]),
                                      weight: 900,
                                      fontSize: 20,
                                      height: 1,
                                      color: Kolor.primary,
                                    ).title,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Label(
                                          bid["name"],
                                          weight: 700,
                                          fontSize: 16,
                                        ).regular,
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          spacing: 2,
                                          children: List.generate(
                                            kRound(bid['rating']),
                                            (index) => const Icon(Icons.star,
                                                size: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  KButton(
                                    onPressed: () => acceptBid(
                                      bid['driver_id'],
                                      parseToDouble(bid['amount']),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 2,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    radius: 6,
                                    backgroundColor: StatusText.success,
                                    label: "Accept",
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }

                  return kSmallLoading;
                },
              ),
          ],
        ),
      ),
    );
  }
}