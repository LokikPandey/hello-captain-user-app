import 'dart:convert';

import 'package:hello_captain_user/Resources/constants.dart';

class DriverModel {
  String id = "";
  String driver_name = "";
  double latitude = 0;
  double longitude = 0;
  String updateAt = "";
  String phone_number = "";
  String photo = "";
  String reg_id = "";
  String driver_job = "";
  String distance = "";
  String brand = "";
  String vehicle_registration_number = "";
  String color = "";
  String type = "";
  String bearing = "";
  DriverModel({
    required this.id,
    required this.driver_name,
    required this.latitude,
    required this.longitude,
    required this.updateAt,
    required this.phone_number,
    required this.photo,
    required this.reg_id,
    required this.driver_job,
    required this.distance,
    required this.brand,
    required this.vehicle_registration_number,
    required this.color,
    required this.type,
    required this.bearing,
  });

  DriverModel copyWith({
    String? id,
    String? driver_name,
    double? latitude,
    double? longitude,
    String? updateAt,
    String? phone_number,
    String? photo,
    String? reg_id,
    String? driver_job,
    String? distance,
    String? brand,
    String? vehicle_registration_number,
    String? color,
    String? type,
    String? bearing,
  }) {
    return DriverModel(
      id: id ?? this.id,
      driver_name: driver_name ?? this.driver_name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updateAt: updateAt ?? this.updateAt,
      phone_number: phone_number ?? this.phone_number,
      photo: photo ?? this.photo,
      reg_id: reg_id ?? this.reg_id,
      driver_job: driver_job ?? this.driver_job,
      distance: distance ?? this.distance,
      brand: brand ?? this.brand,
      vehicle_registration_number:
          vehicle_registration_number ?? this.vehicle_registration_number,
      color: color ?? this.color,
      type: type ?? this.type,
      bearing: bearing ?? this.bearing,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_name': driver_name,
      'latitude': latitude,
      'longitude': longitude,
      'updateAt': updateAt,
      'phone_number': phone_number,
      'photo': photo,
      'reg_id': reg_id,
      'driver_job': driver_job,
      'distance': distance,
      'brand': brand,
      'vehicle_registration_number': vehicle_registration_number,
      'color': color,
      'type': type,
      'bearing': bearing,
    };
  }

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      id: map['id'] ?? '',
      driver_name: map['driver_name'] ?? '',
      latitude: parseToDouble(map['latitude']),
      longitude: parseToDouble(map['longitude']),
      updateAt: map['updateAt'] ?? '',
      phone_number: map['phone_number'] ?? '',
      photo: map['photo'] ?? '',
      reg_id: map['reg_id'] ?? '',
      driver_job: map['driver_job'] ?? '',
      distance: map['distance'] ?? '',
      brand: map['brand'] ?? '',
      vehicle_registration_number: map['vehicle_registration_number'] ?? '',
      color: map['color'] ?? '',
      type: map['type'] ?? '',
      bearing: map['bearing'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DriverModel.fromJson(String source) =>
      DriverModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'DriverModel(id: $id, driver_name: $driver_name, latitude: $latitude, longitude: $longitude, updateAt: $updateAt, phone_number: $phone_number, photo: $photo, reg_id: $reg_id, driver_job: $driver_job, distance: $distance, brand: $brand, vehicle_registration_number: $vehicle_registration_number, color: $color, type: $type, bearing: $bearing)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DriverModel &&
        other.id == id &&
        other.driver_name == driver_name &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.updateAt == updateAt &&
        other.phone_number == phone_number &&
        other.photo == photo &&
        other.reg_id == reg_id &&
        other.driver_job == driver_job &&
        other.distance == distance &&
        other.brand == brand &&
        other.vehicle_registration_number == vehicle_registration_number &&
        other.color == color &&
        other.type == type &&
        other.bearing == bearing;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        driver_name.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        updateAt.hashCode ^
        phone_number.hashCode ^
        photo.hashCode ^
        reg_id.hashCode ^
        driver_job.hashCode ^
        distance.hashCode ^
        brand.hashCode ^
        vehicle_registration_number.hashCode ^
        color.hashCode ^
        type.hashCode ^
        bearing.hashCode;
  }
}
