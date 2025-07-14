import 'dart:convert';

import 'package:hello_captain_user/Resources/app_config.dart';
import 'package:hello_captain_user/Resources/constants.dart';

class UserModel {
  String id = '';
  String customer_fullname = '';
  String email = '';
  String phone_number = '';
  String country_code = '';
  String create_on = '';
  String dob = '';
  int customer_rating = 0;
  String customer_image = '';
  double balance = 0;
  UserModel({
    required this.id,
    required this.customer_fullname,
    required this.email,
    required this.phone_number,
    required this.country_code,
    required this.create_on,
    required this.dob,
    required this.customer_rating,
    required this.customer_image,
    required this.balance,
  });

  UserModel copyWith({
    String? id,
    String? customer_fullname,
    String? email,
    String? phone_number,
    String? country_code,
    String? create_on,
    String? dob,
    int? customer_rating,
    String? customer_image,
    double? balance,
  }) {
    return UserModel(
      id: id ?? this.id,
      customer_fullname: customer_fullname ?? this.customer_fullname,
      email: email ?? this.email,
      phone_number: phone_number ?? this.phone_number,
      country_code: country_code ?? this.country_code,
      create_on: create_on ?? this.create_on,
      dob: dob ?? this.dob,
      customer_rating: customer_rating ?? this.customer_rating,
      customer_image: customer_image ?? this.customer_image,
      balance: balance ?? this.balance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_fullname': customer_fullname,
      'email': email,
      'phone_number': phone_number,
      'country_code': country_code,
      'create_on': create_on,
      'dob': dob,
      'customer_rating': customer_rating,
      'customer_image': customer_image,
      'balance': balance,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      customer_fullname: map['customer_fullname'] ?? '',
      email: map['email'] ?? '',
      phone_number: map['phone_number'] ?? '',
      country_code: map['country_code'] ?? '',
      create_on: map['create_on'] ?? '',
      dob: map['dob'] ?? '',
      customer_rating: int.parse("${map['customer_rating']}"),
      customer_image: "$kImageBaseUrl${map['customer_image']}",
      balance: (parseToDouble(map['balance']) / 100),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'UserModel(id: $id, customer_fullname: $customer_fullname, email: $email, phone_number: $phone_number, country_code: $country_code, create_on: $create_on, dob: $dob, customer_rating: $customer_rating, customer_image: $customer_image, balance: $balance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.customer_fullname == customer_fullname &&
        other.email == email &&
        other.phone_number == phone_number &&
        other.country_code == country_code &&
        other.create_on == create_on &&
        other.dob == dob &&
        other.customer_rating == customer_rating &&
        other.customer_image == customer_image &&
        other.balance == balance;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        customer_fullname.hashCode ^
        email.hashCode ^
        phone_number.hashCode ^
        country_code.hashCode ^
        create_on.hashCode ^
        dob.hashCode ^
        customer_rating.hashCode ^
        customer_image.hashCode ^
        balance.hashCode;
  }
}
