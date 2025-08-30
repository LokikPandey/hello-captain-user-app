import 'dart:async';
import 'package:flutter/foundation.dart'; // <-- ADD THIS IMPORT
import 'package:flutter/gestures.dart'; // <-- AND THIS ONE
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Repository/home_repo.dart';
import 'package:hello_captain_user/Repository/ride_repo.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:hello_captain_user/Repository/mapBox_repo.dart';

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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Start the periodic timer to refresh the driver's location every 15 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchAndUpdateDriverLocation();
      // print("✅ Driver location refreshed by Timer at ${DateTime.now()}");
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed to prevent memory leaks
    _refreshTimer?.cancel();
    pointManager?.deleteAll();
    polylineManager?.deleteAll();
    super.dispose();
  }

  Future<void> setMarkerPoint(String type, Position pos) async {
    try {
      isLoading.value = true;
      Uint8List imageData;
      PointAnnotationOptions point;

      if (pointManager == null) {
        throw Exception("PointAnnotationManager is not initialized.");
      }

      switch (type) {
        case "Pickup":
          final ByteData bytes = await rootBundle.load('$kImagePath/pin.png');
          imageData = bytes.buffer.asUint8List();

          if (pickupPoint != null) {
            await pointManager!.delete(pickupPoint!);
          }
          point = PointAnnotationOptions(
            geometry: Point(coordinates: pos),
            image: imageData,
            iconSize: .2,
          );
          pickupPoint = await pointManager!.create(point);
          break;

        case "Drop":
          final ByteData bytes = await rootBundle.load(
            '$kImagePath/drop-pin.png',
          );
          imageData = bytes.buffer.asUint8List();
          if (dropPoint != null) {
            await pointManager!.delete(dropPoint!);
          }
          point = PointAnnotationOptions(
            geometry: Point(coordinates: pos),
            image: imageData,
            iconSize: .2,
          );
          dropPoint = await pointManager!.create(point);
          break;

        case "Driver":
          final serviceDetailsList = ref.read(serviceDetailsProvider);
          final Map<dynamic, dynamic>? serviceDetails = serviceDetailsList
              .firstWhere(
                (element) => element["service_id"] == widget.serviceId,
                orElse: () => null,
              );
          final mapsIconsId = serviceDetails?["icon_driver"] ?? "0";
          final ByteData bytes = await rootBundle.load(
            '${mapsIcons[mapsIconsId]}',
          );
          imageData = bytes.buffer.asUint8List();

          if (driverMarker != null) {
            await pointManager!.delete(driverMarker!);
          }
          point = PointAnnotationOptions(
            geometry: Point(coordinates: pos),
            image: imageData,
            iconSize: .7,
          );
          driverMarker = await pointManager!.create(point);
          break;
        default:
          return;
      }
    } catch (e) {
      if (!mounted) return;
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
        if (polylineManager != null) {
          await polylineManager!.deleteAll();
          await polylineManager!.create(polylines);
        }
      }
    } catch (e) {
      if (!mounted) return;
      KSnackbar(context, message: "Polyline Error: $e", error: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fitCameraToBounds() async {
    if (mapController == null) return;
    await mapController!.easeTo(
      await MapboxRepo.cameraOptionsForBounds(
        mapController: mapController!,
        pickup: widget.startPosition,
        drop: widget.endPosition,
      ),
      MapAnimationOptions(),
    );
  }

  Position? _currentDriverPos; // store last known position

  Future<void> _animateDriverMovement(Position from, Position to) async {
    const int steps = 30; // higher = smoother
    const Duration totalDuration = Duration(seconds: 2); // longer animation
    final stepDuration = totalDuration ~/ steps;

    for (int i = 1; i <= steps; i++) {
      if (!mounted) return;
      // Linear interpolation for smooth movement
      final double lng = from.lng + (to.lng - from.lng) * (i / steps);
      final double lat = from.lat + (to.lat - from.lat) * (i / steps);

      if (driverMarker != null && pointManager != null) {
        driverMarker!.geometry = Point(coordinates: Position(lng, lat));
        // Update the marker's position on the map
        await pointManager!.update(driverMarker!);
      }
      await Future.delayed(stepDuration);
    }
  }

  Future<void> fetchAndUpdateDriverLocation() async {
    try {
      print("Reloading location for driver ID: ${widget.driverId}");
      final res = await RideRepo.locateDriver(driverId: widget.driverId);

      if (res["status"] == true && mounted) {
        final newDriverPos = Position(
          parseToDouble(res['data'][0]['longitude']),
          parseToDouble(res['data'][0]['latitude']),
        );

        if (_currentDriverPos == null) {
          // First time, just place the marker without animation
          await setMarkerPoint("Driver", newDriverPos);
        } else {
          // Animate from the last known position to the new one
          await _animateDriverMovement(_currentDriverPos!, newDriverPos);
        }
        _currentDriverPos = newDriverPos; // Update the current position
      }
    } catch (e) {
      if (mounted) {
        KSnackbar(
          context,
          message: "Failed to fetch driver location: $e",
          error: true,
        );
      }
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
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
              },
              cameraOptions: CameraOptions(
                zoom: 8.5,
                center: Point(coordinates: widget.startPosition),
              ),
              onMapCreated: (controller) async {
                mapController = controller;

                // Update gesture settings on the controller
                await mapController!.gestures.updateSettings(
                  GesturesSettings(
                    scrollEnabled: true,
                    pinchToZoomEnabled: true,
                    rotateEnabled: true,
                  ),
                );

                await mapController!.scaleBar.updateSettings(
                  ScaleBarSettings(enabled: false),
                );

                pointManager =
                    await mapController!.annotations
                        .createPointAnnotationManager();
                polylineManager =
                    await mapController!.annotations
                        .createPolylineAnnotationManager();

                setMarkerPoint("Pickup", widget.startPosition);
                setMarkerPoint("Drop", widget.endPosition);
                setPolyline();
                await fetchAndUpdateDriverLocation();
                await _fitCameraToBounds();
              },
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'recenter',
              onPressed: _fitCameraToBounds,
              tooltip: 'Recenter Map',
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
