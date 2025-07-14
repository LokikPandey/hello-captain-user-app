import 'dart:convert';

class AppSettingsModel {
  String app_aboutus = "";
  String stripe_active = "";
  String stripe_publish = "";
  String paypal_key = "";
  String paypal_mode = "";
  String paypal_active = "";
  String flutterwave_secret_key = "";
  String flutterwave_published_key = "";
  String flutterwave_mode = "";
  String flutterwave_active = "";
  String razorpay_secret_key = "";
  String razorpay_mode = "";
  String razorpay_active = "";
  String khaliti_secret_key = "";
  String khaliti_mode = "";
  String khaliti_active = "";
  String decimal = "";
  String mapsride = "";
  AppSettingsModel({
    required this.app_aboutus,
    required this.stripe_active,
    required this.stripe_publish,
    required this.paypal_key,
    required this.paypal_mode,
    required this.paypal_active,
    required this.flutterwave_secret_key,
    required this.flutterwave_published_key,
    required this.flutterwave_mode,
    required this.flutterwave_active,
    required this.razorpay_secret_key,
    required this.razorpay_mode,
    required this.razorpay_active,
    required this.khaliti_secret_key,
    required this.khaliti_mode,
    required this.khaliti_active,
    required this.decimal,
    required this.mapsride,
  });

  AppSettingsModel copyWith({
    String? app_aboutus,
    String? stripe_active,
    String? stripe_publish,
    String? paypal_key,
    String? paypal_mode,
    String? paypal_active,
    String? flutterwave_secret_key,
    String? flutterwave_published_key,
    String? flutterwave_mode,
    String? flutterwave_active,
    String? razorpay_secret_key,
    String? razorpay_mode,
    String? razorpay_active,
    String? khaliti_secret_key,
    String? khaliti_mode,
    String? khaliti_active,
    String? decimal,
    String? mapsride,
  }) {
    return AppSettingsModel(
      app_aboutus: app_aboutus ?? this.app_aboutus,
      stripe_active: stripe_active ?? this.stripe_active,
      stripe_publish: stripe_publish ?? this.stripe_publish,
      paypal_key: paypal_key ?? this.paypal_key,
      paypal_mode: paypal_mode ?? this.paypal_mode,
      paypal_active: paypal_active ?? this.paypal_active,
      flutterwave_secret_key:
          flutterwave_secret_key ?? this.flutterwave_secret_key,
      flutterwave_published_key:
          flutterwave_published_key ?? this.flutterwave_published_key,
      flutterwave_mode: flutterwave_mode ?? this.flutterwave_mode,
      flutterwave_active: flutterwave_active ?? this.flutterwave_active,
      razorpay_secret_key: razorpay_secret_key ?? this.razorpay_secret_key,
      razorpay_mode: razorpay_mode ?? this.razorpay_mode,
      razorpay_active: razorpay_active ?? this.razorpay_active,
      khaliti_secret_key: khaliti_secret_key ?? this.khaliti_secret_key,
      khaliti_mode: khaliti_mode ?? this.khaliti_mode,
      khaliti_active: khaliti_active ?? this.khaliti_active,
      decimal: decimal ?? this.decimal,
      mapsride: mapsride ?? this.mapsride,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'app_aboutus': app_aboutus,
      'stripe_active': stripe_active,
      'stripe_publish': stripe_publish,
      'paypal_key': paypal_key,
      'paypal_mode': paypal_mode,
      'paypal_active': paypal_active,
      'flutterwave_secret_key': flutterwave_secret_key,
      'flutterwave_published_key': flutterwave_published_key,
      'flutterwave_mode': flutterwave_mode,
      'flutterwave_active': flutterwave_active,
      'razorpay_secret_key': razorpay_secret_key,
      'razorpay_mode': razorpay_mode,
      'razorpay_active': razorpay_active,
      'khaliti_secret_key': khaliti_secret_key,
      'khaliti_mode': khaliti_mode,
      'khaliti_active': khaliti_active,
      'decimal': decimal,
      'mapsride': mapsride,
    };
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      app_aboutus: map['app_aboutus'] ?? '',
      stripe_active: map['stripe_active'] ?? '',
      stripe_publish: map['stripe_publish'] ?? '',
      paypal_key: map['paypal_key'] ?? '',
      paypal_mode: map['paypal_mode'] ?? '',
      paypal_active: map['paypal_active'] ?? '',
      flutterwave_secret_key: map['flutterwave_secret_key'] ?? '',
      flutterwave_published_key: map['flutterwave_published_key'] ?? '',
      flutterwave_mode: map['flutterwave_mode'] ?? '',
      flutterwave_active: map['flutterwave_active'] ?? '',
      razorpay_secret_key: map['razorpay_secret_key'] ?? '',
      razorpay_mode: map['razorpay_mode'] ?? '',
      razorpay_active: map['razorpay_active'] ?? '',
      khaliti_secret_key: map['khaliti_secret_key'] ?? '',
      khaliti_mode: map['khaliti_mode'] ?? '',
      khaliti_active: map['khaliti_active'] ?? '',
      decimal: map['decimal'] ?? '',
      mapsride: map['mapsride'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AppSettingsModel.fromJson(String source) =>
      AppSettingsModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AppSettingsModel(app_aboutus: $app_aboutus, stripe_active: $stripe_active, stripe_publish: $stripe_publish, paypal_key: $paypal_key, paypal_mode: $paypal_mode, paypal_active: $paypal_active, flutterwave_secret_key: $flutterwave_secret_key, flutterwave_published_key: $flutterwave_published_key, flutterwave_mode: $flutterwave_mode, flutterwave_active: $flutterwave_active, razorpay_secret_key: $razorpay_secret_key, razorpay_mode: $razorpay_mode, razorpay_active: $razorpay_active, khaliti_secret_key: $khaliti_secret_key, khaliti_mode: $khaliti_mode, khaliti_active: $khaliti_active, decimal: $decimal, mapsride: $mapsride)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSettingsModel &&
        other.app_aboutus == app_aboutus &&
        other.stripe_active == stripe_active &&
        other.stripe_publish == stripe_publish &&
        other.paypal_key == paypal_key &&
        other.paypal_mode == paypal_mode &&
        other.paypal_active == paypal_active &&
        other.flutterwave_secret_key == flutterwave_secret_key &&
        other.flutterwave_published_key == flutterwave_published_key &&
        other.flutterwave_mode == flutterwave_mode &&
        other.flutterwave_active == flutterwave_active &&
        other.razorpay_secret_key == razorpay_secret_key &&
        other.razorpay_mode == razorpay_mode &&
        other.razorpay_active == razorpay_active &&
        other.khaliti_secret_key == khaliti_secret_key &&
        other.khaliti_mode == khaliti_mode &&
        other.khaliti_active == khaliti_active &&
        other.decimal == decimal &&
        other.mapsride == mapsride;
  }

  @override
  int get hashCode {
    return app_aboutus.hashCode ^
        stripe_active.hashCode ^
        stripe_publish.hashCode ^
        paypal_key.hashCode ^
        paypal_mode.hashCode ^
        paypal_active.hashCode ^
        flutterwave_secret_key.hashCode ^
        flutterwave_published_key.hashCode ^
        flutterwave_mode.hashCode ^
        flutterwave_active.hashCode ^
        razorpay_secret_key.hashCode ^
        razorpay_mode.hashCode ^
        razorpay_active.hashCode ^
        khaliti_secret_key.hashCode ^
        khaliti_mode.hashCode ^
        khaliti_active.hashCode ^
        decimal.hashCode ^
        mapsride.hashCode;
  }
}
