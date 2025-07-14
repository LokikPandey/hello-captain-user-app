import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:hello_captain_user/Secret/Map_Key.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxRepo {
  static Future<Map<String, dynamic>?> getAddressFromCoordinates(
    Position pos,
  ) async {
    try {
      final res = await Dio().get(
        "https://api.mapbox.com/search/geocode/v6/reverse?longitude=${pos.lng}&latitude=${pos.lat}&access_token=$MAPBOX_ACCESS_TOKEN",
      );
      if (res.data["features"] != null && res.data["features"].isNotEmpty) {
        final address = res.data["features"][0];
        return {
          "address": address["properties"]["full_address"],
          "lng": pos.lng,
          "lat": pos.lat,
        };
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getDirections(
    Position pickupPos,
    Position dropPos,
  ) async {
    try {
      final res = await Dio().get(
        "https://api.mapbox.com/directions/v5/mapbox/driving/${pickupPos.lng},${pickupPos.lat};${dropPos.lng},${dropPos.lat}?access_token=$MAPBOX_ACCESS_TOKEN",
      );
      if (res.data["routes"] != null && res.data["routes"].isNotEmpty) {
        final route = res.data["routes"][0];
        return {
          "encodedPolylines": route["geometry"],
          "duration": route["duration"],
          "distance": route["distance"],
        };
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  List<Position> decodePolylines(String encodedPolyline) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);

    List<Position> data =
        result.map((e) => Position(e.longitude, e.latitude)).toList();
    return data;
  }

  // Using Gmaps place search API

  Future<List> searchPlace(String searchKey) async {
    try {
      final res = await Dio().get(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$searchKey&components=country:NP&key=$GMAP_KEY",
      );
      // "https://api.mapbox.com/search/searchbox/v1/forward?q=$searchKey&country=NP&access_token=$MAPBOX_ACCESS_TOKEN");

      if (res.statusCode == 200 && res.data['status'] == 'OK') {
        final placesList = res.data['predictions'] as List;
        return placesList;
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> placeDetails(
    String placeId,
    String address,
  ) async {
    try {
      final res = await Dio().get(
        "https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=$GMAP_KEY",
      );
      if (res.statusCode == 200 && res.data['status'] == 'OK') {
        return {
          'address': address,
          'lat': res.data['result']['geometry']['location']['lat'],
          'lng': res.data['result']['geometry']['location']['lng'],
        };
      }
      throw "Api call error!";
    } catch (e) {
      rethrow;
    }
  }

  static Future<CameraOptions> cameraOptionsForBounds({
    required MapboxMap mapController,
    required Position pickup,
    required Position drop,
  }) async {
    return await mapController.cameraForCoordinateBounds(
      CoordinateBounds(
        southwest: Point(coordinates: pickup),
        northeast: Point(coordinates: drop),
        infiniteBounds: false,
      ),
      MbxEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
      0,
      0,
      13,
      ScreenCoordinate(x: 0, y: 0),
    );
  }
}
