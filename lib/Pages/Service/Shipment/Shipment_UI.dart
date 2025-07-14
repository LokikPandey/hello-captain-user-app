// ignore_for_file: unused_result

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Helper/Location_Helper.dart';
import 'package:hello_captain_user/Models/driver_model.dart';
import 'package:hello_captain_user/Repository/home_repo.dart';
import 'package:hello_captain_user/Repository/mapBox_repo.dart';
import 'package:hello_captain_user/Repository/ride_repo.dart';
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

class Shipment_UI extends ConsumerStatefulWidget {
  final Map<String, dynamic> serviceData;
  final String serviceImage;
  final String serviceName;
  const Shipment_UI({
    super.key,
    required this.serviceData,
    required this.serviceImage,
    required this.serviceName,
  });

  @override
  ConsumerState<Shipment_UI> createState() => _Shipment_UIState();
}

class _Shipment_UIState extends ConsumerState<Shipment_UI> {
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
  double distanceInMeters = 0.0;

  int minimumFare = 50;
  double costPerKm = 10.0; // Cost per kilometer

  List<PointAnnotation> driversMarkers = [];
  List<DriverModel> driversList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setCameraToCoordinates();

      costPerKm = parseToDouble(widget.serviceData["cost"]) / 100;
      minimumFare = kRound(
        parseToDouble(widget.serviceData["minimum_cost"]) / 100,
      );
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
          // log(driver.reg_id);
          setMarkerPoint(
            "Driver",
            Position(
              parseToDouble(driver.longitude),
              parseToDouble(driver.latitude),
            ),
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

  Future<void> setMarkerPoint(String type, Position pos) async {
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
          distanceInMeters = parseToDouble(res["distance"]);
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

                                            await _sheetController.animateTo(
                                              .8,
                                              duration: Duration(
                                                milliseconds: 200,
                                              ),
                                              curve: Curves.ease,
                                            );

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
                                                        "Shipment Service",
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
                            child: KButton(
                              onPressed:
                                  pickupAddressData != null &&
                                          dropAddressData != null
                                      ? () {
                                        if (driversList.isEmpty) {
                                          KSnackbar(
                                            context,
                                            message: "No drivers available!",
                                            error: true,
                                          );
                                          return;
                                        }
                                        context.push(
                                          "/shipment/detail",
                                          extra: {
                                            "ext_id":
                                                widget.serviceData['ext_id'],
                                            "distance": distanceInMeters,
                                            "cost":
                                                parseToDouble(
                                                  widget.serviceData['cost'],
                                                ) /
                                                100,
                                            "pickup_latitude":
                                                pickupCoordinates?.lat ?? 0,
                                            "pickup_longitude":
                                                pickupCoordinates?.lng ?? 0,
                                            "destination_latitude":
                                                dropCoordinates?.lat ?? 0,
                                            "destination_longitude":
                                                dropCoordinates?.lng ?? 0,
                                            "pickup":
                                                pickupAddressData?['address'] ??
                                                "",
                                            "destination":
                                                dropAddressData?['address'] ??
                                                "",
                                            "driver": driversList,
                                            "minimum_cost": minimumFare,
                                            "time_distance": duration,
                                            "icon": "",
                                            "layanan": "",
                                            "layanandesk": "",
                                            "maks_distance":
                                                widget
                                                    .serviceData["maks_distance"],
                                            "service_id":
                                                widget
                                                    .serviceData['service_id'],
                                            "service_name": widget.serviceName,
                                          },
                                        );
                                      }
                                      : null,
                              style: KButtonStyle.expanded,
                              backgroundColor: Kolor.secondary,
                              label: "Confirm Location",
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back),
            ),
            SimpleShadow(
              sigma: 15,
              color: StatusText.neutral,
              child: KCard(
                color: StatusText.neutral,
                margin: EdgeInsets.only(top: 10),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 7),

                radius: 100,
                child:
                    Label(
                      pickupAddressData == null
                          ? "Select Pickup"
                          : dropAddressData == null
                          ? "Select Drop Address"
                          : "Confirm Location",
                      weight: 700,
                      fontSize: 12,
                      color: Colors.white,
                    ).regular,
              ),
            ),
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
              icon: Icon(Icons.my_location_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget sheetBody() {
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
          height15,
          _pickupDropBtn("Pickup"),
          height15,
          _pickupDropBtn("Drop"),
        ],
      ),
    );
  }

  KCard _pickupDropBtn(String type) {
    bool isPickup = type == "Pickup";
    return KCard(
      onTap: () {
        _searchAndSetLocation(type);
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
                            // Label(
                            //   "${pickupCoordinates!.lat}, ${pickupCoordinates!.lng}",
                            // ).subtitle,
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
                            // Label(
                            //   "${dropCoordinates!.lat}, ${dropCoordinates!.lng}",
                            // ).subtitle,
                          ],
                        ),
              ),
            ),
        ],
      ),
    );
  }
}
