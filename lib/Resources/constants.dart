import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

const double kPadding = 20;
const String kIconPath = "assets/icons";
const String kImagePath = "assets/images";

int kRound(dynamic value) {
  value = parseToDouble(value);
  if (value < 1) {
    return 1;
  }
  return value.round();
}

String kCurrencyFormat(
  dynamic number, {
  String symbol = "रु",
  int decimalDigits = 2,
}) {
  var f = NumberFormat.currency(
    symbol: symbol,
    locale: 'en_IN',
    decimalDigits: decimalDigits,
  );
  return decimalDigits == 0
      ? f.format(double.parse("$number").round())
      : f.format(double.parse("$number"));
}

double parseToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0; // Default fallback if the value is of an unexpected type
}

String thousandToK(dynamic number) {
  final num = parseToDouble(number);
  if (num < 1000) return num.toStringAsFixed(0);
  return "${(num / 1000).toStringAsFixed(1)}K";
}

String calculateDiscount(dynamic mrp, dynamic salePrice) {
  return (((parseToDouble(mrp) - parseToDouble(salePrice)) /
              parseToDouble(mrp)) *
          100)
      .round()
      .toString();
}

String kDateFormat(String date, {bool showTime = false, String? format}) {
  String formatter = "dd MMM, yyyy";
  if (showTime) {
    formatter += " - hh:mm a";
  }
  return DateFormat(format ?? formatter).format(DateTime.parse(date));
}

String formatDuration(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

Future<void> openMap(String latitude, String longitude) async {
  final Uri googleMapUrl = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
  );

  if (await canLaunchUrl(googleMapUrl)) {
    await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $googleMapUrl';
  }
}

String secondsToHoursMinutes(double seconds) {
  final int totalSeconds = seconds.round();
  final int hours = totalSeconds ~/ 3600;
  final int minutes = (totalSeconds % 3600) ~/ 60;
  if (hours > 0) return '${hours}h ${minutes}m';

  return '$minutes mins';
}

Map<String, String> mapsIcons = {
  "0": "assets/icons/maps-icon/driver.png",
  "1": "assets/icons/maps-icon/bike.png",
  "2": "assets/icons/maps-icon/sedan.png",
  "3": "assets/icons/maps-icon/truck.png",
  "4": "assets/icons/maps-icon/deliverybike.png",
  "5": "assets/icons/maps-icon/hatchback.png",
  "6": "assets/icons/maps-icon/suv.png",
  "7": "assets/icons/maps-icon/van.png",
  "8": "assets/icons/maps-icon/bicycle.png",
  "9": "assets/icons/maps-icon/tuktuk.png",
};

Future<bool> get isSimulator async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    // iOS Simulator devices have isPhysicalDevice == false
    return iosInfo.isPhysicalDevice == false;
  } else if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    // Android emulators have isPhysicalDevice == false
    return androidInfo.isPhysicalDevice == false;
  }
  // For other platforms, assume not a simulator/emulator
  return false;
}
