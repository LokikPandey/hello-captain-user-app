import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Repository/home_repo.dart';
import 'package:hello_captain_user/Repository/ride_repo.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:hello_captain_user/Repository/mapBox_repo.dart';                                    
import 'dart:async';

Timer? _refreshTimer;

class Order_Detail_Map_Widget extends ConsumerStatefulWidget {
  final Position startPosition;
  final Position endPosition;
  final String serviceId;
  final String driverId;
  const Order_Detail_Map_Widget({
    super.key,
    required this.startPosition,
    required this.endPosition,
    required this.serviceId,
    required this.driverId,
  });

  @override
  ConsumerState<Order_Detail_Map_Widget> createState() =>
      _Order_Detail_Map_WidgetState();
}

class _Order_Detail_Map_WidgetState
    extends ConsumerState<Order_Detail_Map_Widget> {
  MapboxMap? mapController;
  PointAnnotationManager? pointManager;
  PolylineAnnotationManager? polylineManager;
  final isLoading = ValueNotifier(false);

  PointAnnotation? pickupPoint;
  PointAnnotation? dropPoint;
  PointAnnotation? driverMarker;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      fetchAndUpdateDriverLocation();
      // print("✅ Driver location refreshed at ${DateTime.now()}");
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    pointManager?.deleteAll();
    polylineManager?.deleteAll();
    super.dispose();
  }

  
  Future<void> setMarkerPoint(String type, Position pos) async {
    try {
      isLoading.value = true;

      switch (type) {
        case "Pickup":
          final ByteData bytes = await rootBundle.load('$kImagePath/pin.png');
          final Uint8List imageData = bytes.buffer.asUint8List();

          if (pickupPoint != null) {
            pointManager?.delete(pickupPoint!);
          }
          final point = PointAnnotationOptions(
            geometry: Point(coordinates: pos),
            image: imageData,
            iconSize: .2,
          );
          pickupPoint = await pointManager?.create(point);
          break;

        case "Drop":
          final ByteData bytes = await rootBundle.load(
            '$kImagePath/drop-pin.png',
          );
          final Uint8List imageData = bytes.buffer.asUint8List();
          if (dropPoint != null) {
            pointManager?.delete(dropPoint!);
          }
          final point = PointAnnotationOptions(
            geometry: Point(coordinates: pos),
            image: imageData,
            iconSize: .2,
          );
          dropPoint = await pointManager?.create(point);
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
          final driver = await pointManager?.create(point);
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
        widget.startPosition,
        widget.endPosition,
      );

      if (res != null) {
        final coordinatesList = MapboxRepo().decodePolylines(
          res["encodedPolylines"],
        );
        PolylineAnnotationOptions polylines = PolylineAnnotationOptions(
          geometry: LineString(coordinates: coordinatesList),
          lineWidth: 3,
        );
        await polylineManager!.create(polylines);
      }
    } catch (e) {
      KSnackbar(context, message: "Polyline Error: $e", error: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fitCameraToBounds() async {
    await mapController!.easeTo(
      await MapboxRepo.cameraOptionsForBounds(
        mapController: mapController!,
        pickup: widget.startPosition,
        drop: widget.endPosition,
      ),
      MapAnimationOptions(),
    );
  }

  Future<void> fetchAndUpdateDriverLocation() async {
    try {
      final res = await RideRepo.locateDriver(driverId: widget.driverId);

      if (res["status"] == true) {
        final newDriverPos = Position(
          parseToDouble(res['data'][0]['latitude']),
          parseToDouble(res['data'][0]['longitude']),
        );
        await setMarkerPoint("Driver", newDriverPos);

        KSnackbar(context, message: "Captain Location Updated");
      }
    } catch (e) {
      KSnackbar(
        context,
        message: "Failed to fetch driver location: $e",
        error: true,
      );
    }
  }

Future<void> _moveMapBy({required double dx, required double dy}) async {
  final cameraState = await mapController?.getCameraState();
  if (cameraState != null) {
    final currentCenter = cameraState.center;
    final newCenter = Point(
      coordinates: Position(
        currentCenter.coordinates.lng + dx,
        currentCenter.coordinates.lat + dy,
      ),
    );
    mapController?.flyTo(
      CameraOptions(center: newCenter),
      MapAnimationOptions(duration: 500),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 400,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: MapWidget(
              cameraOptions: CameraOptions(
                zoom: 8.5,
                center: Point(coordinates: widget.startPosition),
              ),
              onMapCreated: (controller) async {
                mapController = controller;

                await mapController!.scaleBar.updateSettings(
                  ScaleBarSettings(enabled: false),
                );
                pointManager =
                    await mapController!.annotations
                        .createPointAnnotationManager();
                polylineManager =
                    await mapController!.annotations
                        .createPolylineAnnotationManager();

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

                setMarkerPoint("Pickup", widget.startPosition);
                setMarkerPoint("Drop", widget.endPosition);
                setMarkerPoint(
                  "Driver",
                  Position(
                    parseToDouble(driverLoc['data'][0]['longitude']),
                    parseToDouble(driverLoc['data'][0]['latitude']),
                  ),
                );

                setPolyline();

                await _fitCameraToBounds();
              },
            ),
          ),
          Positioned(
  top: 10,
  right: 10,
  child: Column(
    children: [
      FloatingActionButton(
        mini: true,
        heroTag: 'refresh',
        onPressed: fetchAndUpdateDriverLocation,
        child: Icon(Icons.refresh),
      ),
      SizedBox(height: 8),
    FloatingActionButton(
      mini: true,
      heroTag: 'zoomIn',
      onPressed: () async {
        final state = await mapController?.getCameraState();
        final currentZoom = state?.zoom ?? 10;
        mapController?.flyTo(
          CameraOptions(zoom: currentZoom + 1),
          MapAnimationOptions(duration: 500),
        );
      },
  child: Icon(Icons.zoom_in),
),
      SizedBox(height: 8),
FloatingActionButton(
  mini: true,
  heroTag: 'zoomOut',
  onPressed: () async {
    final state = await mapController?.getCameraState();
    final currentZoom = state?.zoom ?? 10;
    mapController?.flyTo(
      CameraOptions(zoom: currentZoom - 1),
      MapAnimationOptions(duration: 500),
    );
  },
  child: Icon(Icons.zoom_out),
),

      SizedBox(height: 8),
      FloatingActionButton(
        mini: true,
        heroTag: 'moveNorth',
        onPressed: () {
          _moveMapBy(dx: 0, dy: 0.005);
        },
        child: Icon(Icons.arrow_upward),
      ),
      FloatingActionButton(
        mini: true,
        heroTag: 'moveSouth',
        onPressed: () {
          _moveMapBy(dx: 0, dy: -0.005);
        },
        child: Icon(Icons.arrow_downward),
      ),
      FloatingActionButton(
        mini: true,
        heroTag: 'moveEast',
        onPressed: () {
          _moveMapBy(dx: 0.005, dy: 0);
        },
        child: Icon(Icons.arrow_forward),
      ),
      FloatingActionButton(
        mini: true,
        heroTag: 'moveWest',
        onPressed: () {
          _moveMapBy(dx: -0.005, dy: 0);
        },
        child: Icon(Icons.arrow_back),
      ),
    ],
  ),
),
        ],
      ),
    );
  }
}
