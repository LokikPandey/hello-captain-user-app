import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class LocationService {
  // Get current location
  static Future<bool> hasPermission() async {
    return await Permission.locationWhenInUse.isGranted;
  }

  // Request location permission
  static Future<bool> requestPermission() async {
    PermissionStatus status = await Permission.locationWhenInUse.request();
    return status == PermissionStatus.granted;
  }

  // Check if location enabled
  static Future<bool> serviceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location
  static Future<Position?> getCurrentLocation() async {
    // Check if location services are enabled
    if (!await Geolocator.isLocationServiceEnabled()) {
      bool serviceEnabled = await Geolocator.openLocationSettings();

      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }
    }

    // Check location permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return Future.error('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied. Please enable them in settings.',
      );
    }

    // Get the current location
    try {
      LocationSettings locationSettings =
          Platform.isAndroid
              ? AndroidSettings(accuracy: LocationAccuracy.high)
              : AppleSettings(accuracy: LocationAccuracy.high);

      final geol = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      return geol;
    } catch (e) {
      return Future.error('Failed to get current location: $e');
    }
  }
}
