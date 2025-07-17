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

enum CurrentState { Picking, Checkout, Searching }

class Passenger_Transportation_UI extends ConsumerStatefulWidget {
  final Map<String, dynamic> serviceData;
  final String serviceImage;
  final String serviceName;
  const Passenger_Transportation_UI({
    super.key,
    required this.serviceData,
    required this.serviceImage,
    required this.serviceName,
  });

  @override
  ConsumerState<Passenger_Transportation_UI> createState() =>
      _Passenger_Transportation_UIState();
}

class _Passenger_Transportation_UIState
    extends ConsumerState<Passenger_Transportation_UI> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final isLoading = ValueNotifier(false);

  Position? pickupCoordinates;
  Map<String, dynamic>? pickupAddressData;
  PointAnnotation? pickupPoint;
  PointAnnotation? dropPoint;

  Position? dropCoordinates;
  Map<String, dynamic>? dropAddressData;
  final currentCenter = ValueNotifier<Position?>(null);
  bool isFetching = false;

  geo.Position? myPos;
  MapboxMap? mapController;
  late PointAnnotationManager pointManager;
  late PolylineAnnotationManager polylineManager;
  CurrentState currentState = CurrentState.Picking;

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

  final promoCode = TextEditingController();
  String discountText = "";

  String paymentMethod = "Wallet";
  String distanceText = "";

  final searchCounter = ValueNotifier(120);
  List<PointAnnotation> driversMarkers = [];
  List<DriverModel> driversList = [];
  Map<String, dynamic> promoData = {};
  Timer? _searchTimer;

  String? transactionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setCameraToCoordinates();
      fetchSubscriptionDetails();

      costPerKm = parseToDouble(widget.serviceData["cost"]) / 100;
      minimumFare = parseToDouble(widget.serviceData["minimum_cost"]) / 100;
    });
  }

  Future<void> _searchAndSetLocation(String type) async {
    final res = await context.push("/search-place") as Map<String, dynamic>?;

    if (res != null) {
      final coordinates = Position(res["lng"], res["lat"]);
      await setMarkerPoint(type, coordinates);
      setState(() {
        if (type == "Pickup") {
          pickupCoordinates = coordinates;
          pickupAddressData = res;
        } else {
          dropCoordinates = coordinates;
          dropAddressData = res;
        }
      });
      await setPolyline();
      await setCameraToCoordinates(bounds: coordinates);
    }
  }

  @override
  void dispose() {
    promoCode.dispose();
    if (_searchTimer != null) {
      _searchTimer!.cancel();
    }
    super.dispose();
  }

  Future<void> sendNotificationToDrivers(
    Map<String, dynamic> transactionData,
  ) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) throw "User not logged in!";

      transactionData["layanan"] = user.customer_fullname;
      transactionData["layanandesc"] = widget.serviceName;
      transactionData["bid"] = "true";
      for (DriverModel driver in driversList) {
        await NotificationRepo.sendNotification(
          driver.reg_id,
          "New ${widget.serviceName} Order Available",
          transactionData,
        );
      }
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    }
  }

  Future<void> setDriverMarkers() async {
    try {
      if (myPos == null) return;

      final driverRes = await ref.read(
        listRideFuture(widget.serviceData["service_id"]).future,
      );
      driversList =
          (driverRes['data'] as List)
              .map((e) => DriverModel.fromMap(e))
              .toList();
      if (driversList.isNotEmpty) {
        for (DriverModel driver in driversList) {
          setMarkerPoint(
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
      log("$e");
    }
  }

  Future<void> setCameraToCoordinates({Position? bounds}) async {
    try {
      isLoading.value = true;
      _sheetController.animateTo(
        .3,
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      );
      double lng = 0;
      double lat = 0;
      if (bounds == null) {
        // Check whether it is iOS or Android. If Android, then the below commented line will execute.
        if (Platform.isAndroid) {
          final status = await Permission.locationWhenInUse.request();

          if (status.isDenied || status.isPermanentlyDenied) {
            await showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Label("Location Permission").title,
                    content:
                        Label(
                          "Location permission is required to use this feature. Please enable it in the app settings.",
                        ).regular,
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child:
                            Label("Cancel", color: StatusText.danger).regular,
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await openAppSettings();
                        },
                        child: Label("Open Settings").regular,
                      ),
                    ],
                  ),
            );
            return;
          }

          final location = Location();
          final isServiceOn = await location.requestService();

          if (!isServiceOn) {
            await showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text("Location Service"),
                    content: Text(
                      "Location service is required to use this feature. Please enable it.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await location.requestService();
                        },
                        child: Text("Enable Service"),
                      ),
                    ],
                  ),
            );
            return;
          }
        }

        myPos = await LocationService.getCurrentLocation();
        if (myPos == null) return;

        setDriverMarkers();

        lat = myPos!.latitude;
        lng = myPos!.longitude;
      } else {
        lat = parseToDouble(bounds.lat);
        lng = parseToDouble(bounds.lng);
      }
      setState(() {});
      if (myPos != null && mapController != null) {
        await mapController!.easeTo(
          CameraOptions(
            zoom: 15,
            center: Point(coordinates: Position(lng, lat)),
          ),
          MapAnimationOptions(),
        );
      }
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setMarkerPoint(
    String type,
    Position pos, {
    double bearing = 0,
  }) async {
    try {
      isLoading.value = true;

      switch (type) {
        case "Pickup":
          final ByteData bytes = await rootBundle.load('$kImagePath/pin.png');
          final Uint8List imageData = bytes.buffer.asUint8List();
          if (pickupPoint != null) {
            pointManager.delete(pickupPoint!);
          }
          final point = PointAnnotationOptions(
            geometry: Point(coordinates: pos),
            image: imageData,
            iconSize: .2,
          );
          pickupPoint = await pointManager.create(point);
          break;

        case "Drop":
          final ByteData bytes = await rootBundle.load(
            '$kImagePath/drop-pin.png',
          );
          final Uint8List imageData = bytes.buffer.asUint8List();
          if (dropPoint != null) {
            pointManager.delete(dropPoint!);
          }
          final point = PointAnnotationOptions(
            geometry: Point(coordinates: pos),
            image: imageData,
            iconSize: .2,
          );
          dropPoint = await pointManager.create(point);
          break;

        case "Driver":
          final serviceDetailsList = ref.read(serviceDetailsProvider);

          // Now we will find that element from list where widget.serviceData["service_id"] = serviceDetailsList[i]["service_id"]
          final Map<dynamic, dynamic>? serviceDetails = serviceDetailsList
              .firstWhere(
                (element) =>
                    element["service_id"] == widget.serviceData["service_id"],
                orElse: () => null,
              );

          final mapsIconsId = serviceDetails?["icon_driver"] ?? "0";

          final ByteData bytes = await rootBundle.load(
            '${mapsIcons[mapsIconsId]}',
          );
          final Uint8List imageData = bytes.buffer.asUint8List();
          if (driversMarkers.isNotEmpty) {
            for (var element in driversMarkers) {
              pointManager.delete(element);
            }
          }
          final point = PointAnnotationOptions(
            geometry: Point(coordinates: pos),
            image: imageData,
            iconSize: .7,
            iconRotate: bearing,
          );
          final driver = await pointManager.create(point);

          driversMarkers.add(driver);
          break;
        default:
      }
    } catch (e) {
      KSnackbar(context, message: "Marker Error: $e", error: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setPolyline() async {
    try {
      isLoading.value = true;
      if (pickupAddressData != null && dropAddressData != null) {
        final res = await MapboxRepo().getDirections(
          pickupCoordinates!,
          dropCoordinates!,
        );
        if (res != null) {
          distance = parseToDouble(res["distance"]);
          duration = parseToDouble(res["duration"]);

          polylineManager.deleteAll();
          final coordinatesList = MapboxRepo().decodePolylines(
            res["encodedPolylines"],
          );

          PolylineAnnotationOptions polylines = PolylineAnnotationOptions(
            geometry: LineString(coordinates: coordinatesList),
            lineWidth: 3,
          );

          await polylineManager.create(polylines);
        }
      }
    } catch (e) {
      KSnackbar(context, message: "Polyline Error: $e", error: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getAddress(String type, Position pos) async {
    try {
      isLoading.value = true;
      setState(() {
        isFetching = true;
      });
      final res = await MapboxRepo.getAddressFromCoordinates(pos);

      if (res != null) {
        await setMarkerPoint(type, pos);

        setState(() {
          if (type == "Pickup") {
            pickupAddressData = res;
          } else {
            dropAddressData = res;
          }
        });

        await setPolyline();
      }
    } catch (e) {
      KSnackbar(
        context,
        message: "Error while fetching address: $e",
        error: true,
      );
    } finally {
      isLoading.value = false;
      setState(() {
        isFetching = false;
      });
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

  Future<void> calculateBreakdown() async {
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
      setState(() {
        currentState = CurrentState.Picking;
      });
      KSnackbar(context, message: "Please try again!", error: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> orderRide() async {
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
        "service_order": widget.serviceData["service_id"],
        "start_latitude": pickupCoordinates!.lat,
        "start_longitude": pickupCoordinates!.lng,
        "end_latitude": dropCoordinates!.lat,
        "end_longitude": dropCoordinates!.lng,
        "distance": distanceInMeters,
        "price": price,
        "estimasi": "$duration",
        "pickup_address": pickupAddressData!["address"],
        "destination_address": dropAddressData!["address"],
        "promo_discount": subscriptionDiscount + promoDiscount,
        "wallet_payment": paymentMethod == "Wallet" ? 1 : 0,
      };

      final res = await RideRepo.sendOrderRequest(data);

      setState(() {
        transactionId = res['data'][0]['id'];
      });
      KSnackbar(context, message: "Request Generated!");

      isLoading.value = false;
      setState(() {
        currentState = CurrentState.Searching;
      });
      _sheetController.animateTo(
        .8,
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      );

      sendNotificationToDrivers(res['data'][0]);

      await FirebaseFirestore.instance
          .collection("ride_bids")
          .doc(res['data'][0]['id'])
          .set(res['data'][0]);

      // -----------120 seconds countdown starts
      searchCounter.value = 120;
      _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (searchCounter.value == 0) {
          // ---------------after countdown ends
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
      KSnackbar(context, message: e, error: true);
    } finally {
      isLoading.value = false;
    }
  }

  void _searchCancel() {
    if (_searchTimer != null) {
      _searchTimer!.cancel();
    }
    setState(() {
      currentState = CurrentState.Checkout;
    });

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Label("No Driver Found").title,
            content:
                Label(
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
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                label: "Try Again",
              ),
            ],
          ),
    );
  }

  Future<int> checkStatus(String transaction_id) async {
    try {
      isLoading.value = true;
      final data = {"transaction_id": transaction_id};

      final res = await RideRepo.checkOrderRequest(data);

      return int.parse("${res['data'][0]['status']}");
    } catch (e) {
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  void acceptBid(String driverId, double amount) async {
    try {
      isLoading.value = true;
      if (transactionId == null) throw "Transaction ID Null!";
      await PurchasingRepo.acceptBid(
        transactionId: transactionId!,
        driverId: driverId,
        amount: amount.round(),
      );

      KSnackbar(context, message: "Bid Accepted!");

      final status = await checkStatus(transactionId!);

      if (status > 1) {
        context.go(
          "/confirmation",
          extra:
              Map.from({
                'subtitle': "${widget.serviceName} Booked",
                'description': "You can track in the order details page.",
              }).cast<String, dynamic>(),
        );
      } else {
        _searchCancel();
      }
    } catch (e) {
      KSnackbar(context, message: e, error: true);
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
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: double.infinity,
                  height: screenHeight * .7,
                  child: MapWidget(
                    cameraOptions: CameraOptions(
                      center: Point(
                        coordinates: Position(85.292377, 27.689283),
                      ),
                      zoom: 15,
                      bearing: 0,
                      pitch: 0,
                    ),
                    onCameraChangeListener: (cameraChangedEventData) {
                      currentCenter.value =
                          cameraChangedEventData.cameraState.center.coordinates;
                      _sheetController.animateTo(
                        .3,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                      );
                    },
                    onMapCreated: (controller) async {
                      mapController = controller;
                      if (mapController != null) {
                        mapController!.location.updateSettings(
                          LocationComponentSettings(
                            enabled: true,
                            pulsingEnabled: false,
                            showAccuracyRing: true,
                          ),
                        );
                      }
                      pointManager =
                          await mapController!.annotations
                              .createPointAnnotationManager();
                      polylineManager =
                          await mapController!.annotations
                              .createPolylineAnnotationManager();
                      setState(() {});
                      if (myPos != null) {
                        await setCameraToCoordinates(
                          bounds: Position(myPos!.longitude, myPos!.latitude),
                        );

                        currentCenter.value = Position(
                          myPos!.longitude,
                          myPos!.latitude,
                        );
                      }
                    },
                  ),
                ),
                if (currentState == CurrentState.Picking &&
                    (pickupAddressData == null || dropAddressData == null))
                  ValueListenableBuilder(
                    valueListenable: currentCenter,
                    builder: (context, center, _) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 80),
                        height: 70,
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child:
                                  pickupAddressData == null
                                      ? KButton(
                                        onPressed: () async {
                                          if (center != null) {
                                            setState(() {
                                              pickupCoordinates = center;
                                            });
                                            await getAddress("Pickup", center);
                                          }
                                        },
                                        label: "Pick Location",
                                        fontSize: 12,
                                        visualDensity: VisualDensity.compact,
                                        radius: 100,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 2,
                                        ),
                                      )
                                      : KButton(
                                        onPressed: () async {
                                          if (center != null) {
                                            setState(() {
                                              dropCoordinates = center;
                                            });
                                            await getAddress("Drop", center);
                                            mapController!.easeTo(
                                              await MapboxRepo.cameraOptionsForBounds(
                                                mapController: mapController!,
                                                pickup: pickupCoordinates!,
                                                drop: dropCoordinates!,
                                              ),
                                              MapAnimationOptions(),
                                            );
                                          }
                                        },
                                        label: "Drop Location",
                                        fontSize: 12,
                                        visualDensity: VisualDensity.compact,
                                        radius: 100,
                                        backgroundColor: StatusText.danger,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 2,
                                        ),
                                      ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: SvgPicture.asset(
                                "$kIconPath/pin.svg",
                                height: 40,
                                colorFilter: kSvgColor(
                                  pickupAddressData == null
                                      ? Colors.black
                                      : StatusText.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
            headerActions(),

            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: currentState == CurrentState.Picking ? 0.6 : 0.9,
              builder:
                  (context, scrollController) => Container(
                    decoration: BoxDecoration(
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
                                  padding: const EdgeInsets.all(
                                    kPadding,
                                  ).copyWith(bottom: 0),
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
                                      height20,
                                      KCard(
                                        padding: EdgeInsets.all(10),
                                        child: Row(
                                          spacing: 15,
                                          children: [
                                            KCard(
                                              color: Kolor.scaffold,
                                              padding: EdgeInsets.all(5),
                                              child: Image.network(
                                                widget.serviceImage,
                                                height: 50,
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Label(
                                                    widget.serviceName,
                                                    fontSize: 17,
                                                  ).regular,
                                                  Label(
                                                    widget.serviceData['description'] ??
                                                        "Ride Service",
                                                    fontSize: 11,
                                                  ).subtitle,
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                sheetBody(),
                              ],
                            ),
                          ),
                        ),
                        if (currentState != CurrentState.Searching)
                          Padding(
                            padding: EdgeInsets.all(kPadding).copyWith(top: 0),
                            child:
                                currentState == CurrentState.Picking
                                    ? KButton(
                                      onPressed:
                                          pickupAddressData != null &&
                                                  dropAddressData != null
                                              ? () {
                                                if (driversList.isEmpty) {
                                                  KSnackbar(
                                                    context,
                                                    message:
                                                        "Driver not available!",
                                                    error: true,
                                                  );
                                                  return;
                                                }
                                                distanceInMeters = distance;
                                                calculateBreakdown();

                                                setState(() {
                                                  currentState =
                                                      CurrentState.Checkout;
                                                  _sheetController.animateTo(
                                                    .7,
                                                    duration: Duration(
                                                      milliseconds: 200,
                                                    ),
                                                    curve: Curves.easeIn,
                                                  );
                                                });
                                              }
                                              : null,
                                      style: KButtonStyle.expanded,
                                      backgroundColor: Kolor.secondary,
                                      label: "Confirm Location",
                                    )
                                    : currentState == CurrentState.Checkout
                                    ? KButton(
                                      onPressed: orderRide,
                                      style: KButtonStyle.expanded,
                                      label: "Place Order",
                                    )
                                    : KButton(
                                      onPressed: null,
                                      style: KButtonStyle.expanded,
                                      backgroundColor: StatusText.danger,
                                      label: "Cancel Order",
                                    ),
                          )
                        else
                          KCard(
                            margin: EdgeInsets.all(10),
                            padding: EdgeInsets.all(10),
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
                                      builder:
                                          (context, value, child) =>
                                              Label(
                                                formatDuration(value),
                                                fontSize: 17,
                                              ).title,
                                    ),
                                  ],
                                ),
                                KButton(
                                  onPressed:
                                      transactionId != null
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
                          ),
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
            ),
            const SizedBox(width: 10),
            // Search bar (make it slightly less wide)
            Expanded(
              child: InkWell(
                onTap: () async {
                  if (pickupCoordinates == null) {
                    final myPos = await LocationService.getCurrentLocation();
                    if (myPos != null) {
                      setState(() {
                        pickupCoordinates = Position(
                          myPos.longitude,
                          myPos.latitude,
                        );
                        pickupAddressData = {"address": "Current Location"};
                        if (pickupPoint != null) {
                          pointManager.delete(pickupPoint!);
                        }
                      });
                    }
                  }
                  _searchAndSetLocation("Drop");
                },
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child:
                            Label(
                              dropAddressData == null
                                  ? "Search Drop Location"
                                  : dropAddressData!["address"],
                              fontSize: 14,
                              weight: 500,
                              color: Colors.black,
                            ).regular,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Zoom to location icon
            IconButton(
              onPressed: () async {
                if (pickupCoordinates != null && dropCoordinates != null) {
                  mapController!.easeTo(
                    await MapboxRepo.cameraOptionsForBounds(
                      mapController: mapController!,
                      pickup: pickupCoordinates!,
                      drop: dropCoordinates!,
                    ),
                    MapAnimationOptions(),
                  );
                } else if (pickupCoordinates != null &&
                    dropCoordinates == null) {
                  setCameraToCoordinates(
                    bounds: Position(
                      pickupCoordinates!.lng,
                      pickupCoordinates!.lat,
                    ),
                  );
                } else {
                  setCameraToCoordinates();
                }
              },
              icon: const Icon(Icons.my_location_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickStage() {
    return Padding(
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Label("Set your location").title,
              TextButton(
                onPressed: () {
                  setState(() {
                    pickupCoordinates = null;
                    pickupAddressData = null;
                    dropAddressData = null;
                    dropCoordinates = null;
                    pointManager.delete(pickupPoint!);
                    pointManager.delete(dropPoint!);
                    polylineManager.deleteAll();
                  });
                },
                child:
                    Label(
                      "Clear",
                      weight: 900,
                      color: kColor(context).primary,
                    ).regular,
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () async {
              myPos = await LocationService.getCurrentLocation();
              if (myPos == null) return;

              setState(() {
                pickupCoordinates = Position(myPos!.longitude, myPos!.latitude);
                pickupAddressData = {
                  "address": "Current Location", // optional placeholder
                };

                // (optional) reset or create pickupPoint marker if needed
                if (pickupPoint != null) {
                  pointManager.delete(pickupPoint!);
                }

                // optionally center camera
                setCameraToCoordinates(bounds: pickupCoordinates!);
              });
            },
            icon: Icon(Icons.my_location),
            label: Text("Use Current Location as Pickup"),
          ),
          height15,
          _pickupDropBtn("Pickup"),
          height15,
          _pickupDropBtn("Drop"),
        ],
      ),
    );
  }

  Widget sheetBody() {
    switch (currentState) {
      case CurrentState.Picking:
        return _pickStage();
      case CurrentState.Checkout:
        return _checkoutStage();
      case CurrentState.Searching:
        return _searchingStage();
    }
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
              StreamBuilder(
                stream:
                    FirebaseFirestore.instance
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
                        title: "No Bids!",
                        subtitle:
                            'Please wait for riders to bids for this ride.',
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
                              child:
                                  Label(
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
                          separatorBuilder: (context, index) => height15,
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final bid = snapshot.data!.docs[index].data();

                            return KCard(
                              child: Row(
                                spacing: 15,
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Label(
                                          kCurrencyFormat(bid["amount"]),
                                          weight: 900,
                                          fontSize: 20,
                                          height: 1,
                                          color: Kolor.primary,
                                        ).title,
                                      ],
                                    ),
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
                                            (index) =>
                                                Icon(Icons.star, size: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  KButton(
                                    onPressed:
                                        () => acceptBid(
                                          bid['driver_id'],
                                          parseToDouble(bid['amount']),
                                        ),
                                    padding: EdgeInsets.symmetric(
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

  KCard _pickupDropBtn(String type) {
    bool isPickup = type == "Pickup";
    return KCard(
      onTap: () async {
        if (type == "Drop" && pickupCoordinates == null) {
          final myPos = await LocationService.getCurrentLocation();
          if (myPos != null) {
            setState(() {
              pickupCoordinates = Position(myPos.longitude, myPos.latitude);
              pickupAddressData = {"address": "Current Location"};
              if (pickupPoint != null) {
                pointManager.delete(pickupPoint!);
              }
            });
          }
        }

        _searchAndSetLocation(type); // Now open the search
      },
      borderWidth: 1,
      color: Kolor.scaffold,
      child: Row(
        spacing: 15,
        children: [
          Icon(
            Icons.location_on,
            size: 27,
            color: isPickup ? StatusText.neutral : StatusText.danger,
          ),
          if (isPickup)
            Expanded(
              child: Skeletonizer(
                enabled: isFetching,
                child:
                    pickupCoordinates == null || pickupAddressData == null
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Label("Choose Pickup Location", fontSize: 15).title,
                            Label("Tap to pick location from list").subtitle,
                          ],
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Label(
                              pickupAddressData!["address"],
                              fontSize: 15,
                            ).title,
                            Label(
                              "${pickupCoordinates!.lat}, ${pickupCoordinates!.lng}",
                            ).subtitle,
                          ],
                        ),
              ),
            )
          else
            Expanded(
              child: Skeletonizer(
                enabled: isFetching,
                child:
                    dropCoordinates == null || dropAddressData == null
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Label("Choose Drop Location", fontSize: 15).title,
                            Label("Tap to pick location from list").subtitle,
                          ],
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Label(
                              dropAddressData!["address"],
                              fontSize: 15,
                            ).title,
                          ],
                        ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _checkoutStage() {
    return Consumer(
      builder: (context, ref, _) {
        final user = ref.watch(userProvider)!;
        return Padding(
          padding: const EdgeInsets.all(kPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Label("Location").title),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        currentState = CurrentState.Picking;
                      });
                    },
                    child: Label("Change").regular,
                  ),
                ],
              ),
              height10,
              Row(
                spacing: 15,
                children: [
                  Icon(Icons.location_on, color: StatusText.neutral),
                  Expanded(
                    child: Label("${pickupAddressData?["address"]}").regular,
                  ),
                ],
              ),
              height10,
              Row(
                spacing: 15,
                children: [
                  Icon(Icons.location_on, color: StatusText.danger),
                  Expanded(
                    child: Label("${dropAddressData?["address"]}").regular,
                  ),
                ],
              ),
              _div,
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
                  Label("$distanceText Km").regular, // Use calculated distance
                ],
              ),
              height5,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Label("Price (NPR)").regular,
                  Label(kCurrencyFormat(price)).regular, // Use calculated price
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
              _div,
              Label("Promo Code").title,
              height15,
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
                      child: Icon(Icons.close, color: Kolor.scaffold, size: 15),
                    ),
                  ],
                ),
              _div,
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
        );
      },
    );
  }
}

Widget get _div => Divider(height: 30, color: Kolor.border);
