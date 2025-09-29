import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
  final bool isFullscreen; // Added flag for fullscreen mode

  const Order_Detail_Map_Widget({
    super.key,
    required this.startPosition,
    required this.endPosition,
    required this.serviceId,
    required this.driverId,
    this.isFullscreen = false, // Default to false
  });

  @override
  ConsumerState<Order_Detail_Map_Widget> createState() =>
      _Order_Detail_Map_WidgetState();
}

class _Order_Detail_Map_WidgetState extends ConsumerState<Order_Detail_Map_Widget> {
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
    // Start the periodic timer to refresh the driver's location
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchAndUpdateDriverLocation();
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
    // ... (rest of the setMarkerPoint method remains the same)
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
    // ... (rest of the setPolyline method remains the same)
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
    // ... (rest of the _fitCameraToBounds method remains the same)
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

  Position? _currentDriverPos;

  Future<void> _animateDriverMovement(Position from, Position to) async {
    // ... (rest of the _animateDriverMovement method remains the same)
    const int steps = 30;
    const Duration totalDuration = Duration(seconds: 2);
    final stepDuration = totalDuration ~/ steps;

    for (int i = 1; i <= steps; i++) {
      if (!mounted) return;
      final double lng = from.lng + (to.lng - from.lng) * (i / steps);
      final double lat = from.lat + (to.lat - from.lat) * (i / steps);

      if (driverMarker != null && pointManager != null) {
        driverMarker!.geometry = Point(coordinates: Position(lng, lat));
        await pointManager!.update(driverMarker!);
      }
      await Future.delayed(stepDuration);
    }
  }

  Future<void> fetchAndUpdateDriverLocation() async {
    // ... (rest of the fetchAndUpdateDriverLocation method remains the same)
    try {
      print("Reloading location for driver ID: ${widget.driverId}");
      final res = await RideRepo.locateDriver(driverId: widget.driverId);

      if (res["status"] == true && mounted) {
        final newDriverPos = Position(
          parseToDouble(res['data'][0]['longitude']),
          parseToDouble(res['data'][0]['latitude']),
        );

        if (_currentDriverPos == null) {
          await setMarkerPoint("Driver", newDriverPos);
        } else {
          await _animateDriverMovement(_currentDriverPos!, newDriverPos);
        }
        _currentDriverPos = newDriverPos;
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

  void _navigateToFullscreenMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenMap(
          startPosition: widget.startPosition,
          endPosition: widget.endPosition,
          serviceId: widget.serviceId,
          driverId: widget.driverId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Use full screen dimensions when in fullscreen mode
      width: widget.isFullscreen ? double.infinity : double.infinity,
      height: widget.isFullscreen ? double.infinity : 400,
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
                    await mapController!.annotations.createPointAnnotationManager();
                polylineManager =
                    await mapController!.annotations.createPolylineAnnotationManager();
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
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'recenter',
                  onPressed: _fitCameraToBounds,
                  tooltip: 'Recenter Map',
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                // Only show fullscreen button when not in fullscreen mode
                if (!widget.isFullscreen)
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'fullscreen',
                    onPressed: _navigateToFullscreenMap,
                    tooltip: 'Fullscreen Map',
                    child: const Icon(Icons.fullscreen),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FullscreenMap extends StatelessWidget {
  final Position startPosition;
  final Position endPosition;
  final String serviceId;
  final String driverId;

  const FullscreenMap({
    super.key,
    required this.startPosition,
    required this.endPosition,
    required this.serviceId,
    required this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: Colors.transparent,
      ),
      body: Order_Detail_Map_Widget(
        startPosition: startPosition,
        endPosition: endPosition,
        serviceId: serviceId,
        driverId: driverId,
        isFullscreen: true, // Pass true to indicate fullscreen mode
      ),
    );
  }
}