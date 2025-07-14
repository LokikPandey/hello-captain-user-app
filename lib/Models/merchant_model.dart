import 'dart:convert';

import 'package:hello_captain_user/Resources/constants.dart';

class MerchantModel {
  String merchant_id = "";
  String merchant_name = "";
  String merchant_address = "";
  String merchant_latitude = "";
  String merchant_longitude = "";
  String open_hour = "";
  String close_hour = "";
  String merchant_desc = "";
  String merchant_category = "";
  String merchant_image = "";
  String merchant_telephone_number = "";
  String merchant_status = "";
  String merchant_open_status = "";
  double balance = 0;
  double distance = 0;
  String promo_status = "";
  double minimum_distance = 0;
  double minimum_wallet = 0;
  String category_name = "";
  String ext_id = "";
  MerchantModel({
    required this.merchant_id,
    required this.merchant_name,
    required this.merchant_address,
    required this.merchant_latitude,
    required this.merchant_longitude,
    required this.open_hour,
    required this.close_hour,
    required this.merchant_desc,
    required this.merchant_category,
    required this.merchant_image,
    required this.merchant_telephone_number,
    required this.merchant_status,
    required this.merchant_open_status,
    required this.balance,
    required this.distance,
    required this.promo_status,
    required this.minimum_distance,
    required this.minimum_wallet,
    required this.category_name,
    required this.ext_id,
  });

  MerchantModel copyWith({
    String? merchant_id,
    String? merchant_name,
    String? merchant_address,
    String? merchant_latitude,
    String? merchant_longitude,
    String? open_hour,
    String? close_hour,
    String? merchant_desc,
    String? merchant_category,
    String? merchant_image,
    String? merchant_telephone_number,
    String? merchant_status,
    String? merchant_open_status,
    double? balance,
    double? distance,
    String? promo_status,
    double? minimum_distance,
    double? minimum_wallet,
    String? category_name,
    String? ext_id,
  }) {
    return MerchantModel(
      merchant_id: merchant_id ?? this.merchant_id,
      merchant_name: merchant_name ?? this.merchant_name,
      merchant_address: merchant_address ?? this.merchant_address,
      merchant_latitude: merchant_latitude ?? this.merchant_latitude,
      merchant_longitude: merchant_longitude ?? this.merchant_longitude,
      open_hour: open_hour ?? this.open_hour,
      close_hour: close_hour ?? this.close_hour,
      merchant_desc: merchant_desc ?? this.merchant_desc,
      merchant_category: merchant_category ?? this.merchant_category,
      merchant_image: merchant_image ?? this.merchant_image,
      merchant_telephone_number:
          merchant_telephone_number ?? this.merchant_telephone_number,
      merchant_status: merchant_status ?? this.merchant_status,
      merchant_open_status: merchant_open_status ?? this.merchant_open_status,
      balance: balance ?? this.balance,
      distance: distance ?? this.distance,
      promo_status: promo_status ?? this.promo_status,
      minimum_distance: minimum_distance ?? this.minimum_distance,
      minimum_wallet: minimum_wallet ?? this.minimum_wallet,
      category_name: category_name ?? this.category_name,
      ext_id: ext_id ?? this.ext_id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchant_id': merchant_id,
      'merchant_name': merchant_name,
      'merchant_address': merchant_address,
      'merchant_latitude': merchant_latitude,
      'merchant_longitude': merchant_longitude,
      'open_hour': open_hour,
      'close_hour': close_hour,
      'merchant_desc': merchant_desc,
      'merchant_category': merchant_category,
      'merchant_image': merchant_image,
      'merchant_telephone_number': merchant_telephone_number,
      'merchant_status': merchant_status,
      'merchant_open_status': merchant_open_status,
      'balance': balance,
      'distance': distance,
      'promo_status': promo_status,
      'minimum_distance': minimum_distance,
      'minimum_wallet': minimum_wallet,
      'category_name': category_name,
      'ext_id': ext_id,
    };
  }

  factory MerchantModel.fromMap(Map<String, dynamic> map) {
    return MerchantModel(
      merchant_id: map['merchant_id'] ?? '',
      merchant_name: map['merchant_name'] ?? '',
      merchant_address: map['merchant_address'] ?? '',
      merchant_latitude: map['merchant_latitude'] ?? '',
      merchant_longitude: map['merchant_longitude'] ?? '',
      open_hour: map['open_hour'] ?? '',
      close_hour: map['close_hour'] ?? '',
      merchant_desc: map['merchant_desc'] ?? '',
      merchant_category: map['merchant_category'] ?? '',
      merchant_image: map['merchant_image'] ?? '',
      merchant_telephone_number: map['merchant_telephone_number'] ?? '',
      merchant_status: map['merchant_status'] ?? '',
      merchant_open_status: map['merchant_open_status'] ?? '',
      balance: parseToDouble(map['balance']),
      distance: parseToDouble(map['distance']),
      promo_status: map['promo_status'] ?? '',
      minimum_distance: parseToDouble(map['minimum_distance']),
      minimum_wallet: parseToDouble(map['minimum_wallet']),
      category_name: map['category_name'] ?? '',
      ext_id: map['ext_id'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory MerchantModel.fromJson(String source) =>
      MerchantModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'MerchantModel(merchant_id: $merchant_id, merchant_name: $merchant_name, merchant_address: $merchant_address, merchant_latitude: $merchant_latitude, merchant_longitude: $merchant_longitude, open_hour: $open_hour, close_hour: $close_hour, merchant_desc: $merchant_desc, merchant_category: $merchant_category, merchant_image: $merchant_image, merchant_telephone_number: $merchant_telephone_number, merchant_status: $merchant_status, merchant_open_status: $merchant_open_status, balance: $balance, distance: $distance, promo_status: $promo_status, minimum_distance: $minimum_distance, minimum_wallet: $minimum_wallet, category_name: $category_name, ext_id: $ext_id)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MerchantModel &&
        other.merchant_id == merchant_id &&
        other.merchant_name == merchant_name &&
        other.merchant_address == merchant_address &&
        other.merchant_latitude == merchant_latitude &&
        other.merchant_longitude == merchant_longitude &&
        other.open_hour == open_hour &&
        other.close_hour == close_hour &&
        other.merchant_desc == merchant_desc &&
        other.merchant_category == merchant_category &&
        other.merchant_image == merchant_image &&
        other.merchant_telephone_number == merchant_telephone_number &&
        other.merchant_status == merchant_status &&
        other.merchant_open_status == merchant_open_status &&
        other.balance == balance &&
        other.distance == distance &&
        other.promo_status == promo_status &&
        other.minimum_distance == minimum_distance &&
        other.minimum_wallet == minimum_wallet &&
        other.category_name == category_name &&
        other.ext_id == ext_id;
  }

  @override
  int get hashCode {
    return merchant_id.hashCode ^
        merchant_name.hashCode ^
        merchant_address.hashCode ^
        merchant_latitude.hashCode ^
        merchant_longitude.hashCode ^
        open_hour.hashCode ^
        close_hour.hashCode ^
        merchant_desc.hashCode ^
        merchant_category.hashCode ^
        merchant_image.hashCode ^
        merchant_telephone_number.hashCode ^
        merchant_status.hashCode ^
        merchant_open_status.hashCode ^
        balance.hashCode ^
        distance.hashCode ^
        promo_status.hashCode ^
        minimum_distance.hashCode ^
        minimum_wallet.hashCode ^
        category_name.hashCode ^
        ext_id.hashCode;
  }
}
