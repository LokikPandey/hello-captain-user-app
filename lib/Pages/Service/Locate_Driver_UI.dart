import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Helper/Location_Helper.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Repository/contact_repo.dart';
import 'package:hello_captain_user/Repository/home_repo.dart';
import 'package:hello_captain_user/Repository/mapBox_repo.dart';
import 'package:hello_captain_user/Repository/ride_repo.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:location/location.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class Locate_Driver_UI extends ConsumerStatefulWidget {
  final String driverId;
  final String serviceId;
  final Position pickupPos;
  final Position dropPos;
  const Locate_Driver_UI({
    super.key,
    required this.driverId,
    required this.serviceId,
    required this.pickupPos,
    required this.dropPos,
  });

  @override
  ConsumerState<Locate_Driver_UI> createState() => _Locate_Driver_UIState();
}

class _Locate_Driver_UIState extends ConsumerState<Locate_Driver_UI> {
  MapboxMap? mapController;
  late PointAnnotationManager pointManager;
  late PolylineAnnotationManager polylineManager;

  final isLoading = ValueNotifier(false);
  PointAnnotation? pickupPoint;
  PointAnnotation? dropPoint;
  PointAnnotation? driverMarker;

  Future<void> sendSos() async {
    try {
      isLoading.value = true;
      final user = ref.read(userProvider);
      if (user == null) throw "User not logged in!";

      final serviceEnabled = await Location.instance.requestService();

      if (!serviceEnabled) throw "Need Location Services to send SOS!";

      final myPos = await LocationService.getCurrentLocation();
      if (myPos == null) throw "Location unresolved!";

      final res = await ContactRepo.sos(
        userId: user.id,
        lat: "${myPos.latitude}",
        lng: "${myPos.longitude}",
      );

      if (res['error'] != null) {
        KSnackbar(context, message: res['error'], error: true);
      } else {
        KSnackbar(context, message: "SOS Sent!");
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
                (element) => element["service_id"] == widget.serviceId,
                orElse: () => null,
              );

          final mapsIconsId = serviceDetails?["icon_driver"] ?? "0";

          final ByteData bytes = await rootBundle.load(
            '${mapsIcons[mapsIconsId]}',
          );
          final Uint8List imageData = bytes.buffer.asUint8List();

          final point = PointAnnotationOptions(
            geometry: Point(coordinates: pos),
            image: imageData,
            iconSize: .7,
          );
          final driver = await pointManager.create(point);
          driverMarker = driver;
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
      final res = await MapboxRepo().getDirections(
        widget.pickupPos,
        widget.dropPos,
      );

      if (res != null) {
        // distance = parseToDouble(res["distance"]);
        // duration = parseToDouble(res["duration"]);

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
    } catch (e) {
      KSnackbar(context, message: "Polyline Error: $e", error: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KScaffold(
      body: Stack(
        alignment: Alignment.topRight,
        children: [
          MapWidget(
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(81.4895189, 28.3768359)),
              zoom: 15,
              bearing: 0,
              pitch: 0,
            ),

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

              final driverLoc = await ref.read(
                locateDriverFuture(widget.driverId).future,
              );

              await mapController!.easeTo(
                CameraOptions(
                  center: Point(
                    coordinates: Position(
                      parseToDouble(driverLoc['data'][0]['longitude']),
                      parseToDouble(driverLoc['data'][0]['latitude']),
                    ),
                  ),
                ),
                MapAnimationOptions(),
              );
              setMarkerPoint("Pickup", widget.pickupPos);
              setMarkerPoint("Drop", widget.dropPos);
              setMarkerPoint(
                "Driver",
                Position(
                  parseToDouble(driverLoc['data'][0]['longitude']),
                  parseToDouble(driverLoc['data'][0]['latitude']),
                ),
              );

              setPolyline();
            },
          ),
          ValueListenableBuilder(
            valueListenable: isLoading,
            builder: (context, loading, _) {
              if (loading) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(kPadding),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return SizedBox();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: sendSos,
        elevation: 0,
        backgroundColor: StatusText.danger,
        foregroundColor: Colors.white,
        child: Icon(Icons.sos),
      ),
    );
  }
}
