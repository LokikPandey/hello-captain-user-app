import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Helper/Location_Helper.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../Essentials/kButton.dart';
import '../Helper/route_config.dart';

class Request_Location_UI extends ConsumerStatefulWidget {
  const Request_Location_UI({super.key});

  @override
  ConsumerState<Request_Location_UI> createState() =>
      _Request_Location_UIState();
}

class _Request_Location_UIState extends ConsumerState<Request_Location_UI> {
  final isLoading = ValueNotifier(false);
  geo.Position? myPos;

  Future<void> _checkLocationPermission() async {
    try {
      isLoading.value = true;

      if (Platform.isIOS) {
        myPos = await LocationService.getCurrentLocation();
        // log(
        //   "IOS Location Permission Status: ${myPos == null ? "Denied" : "Granted"}",
        // );
        if (myPos != null) {
          // final authNotifier = ref.read(authNotifierProvider);
          // await authNotifier.checkLocationPermission();
          context.go("/");
        } else {
          KSnackbar(
            context,
            message:
                "Location permission permanently denied. Please enable it from settings.",
            error: true,
          );
        }
      } else {
        final status = await Permission.locationWhenInUse.request();
        // log("Android Location Permission Status: $status");

        if (status.isGranted) {
          final authNotifier = ref.read(authNotifierProvider);
          await authNotifier.checkLocationPermission();

          context.go("/");
        } else if (status.isDenied) {
          KSnackbar(
            context,
            message: "Location permission denied. Please allow access.",
            error: true,
          );
        } else if (status.isPermanentlyDenied) {
          KSnackbar(
            context,
            message:
                "Location permission permanently denied. Please enable it from settings.",
            error: true,
          );

          final res = await openAppSettings();
          if (res) {
            _checkLocationPermission();
          }
        }
      }
    } catch (e) {
      if (mounted) KSnackbar(context, message: "$e", error: true);
    } finally {
      if (mounted) isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KScaffold(
      body: Padding(
        padding: const EdgeInsets.all(kPadding),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 100, color: StatusText.danger),
              kHeight(50),
              Label(
                'Enable Location',
                textAlign: TextAlign.center,
                fontSize: 30,
                weight: 600,
              ).title,
              height20,
              Label(
                'We use your location to find nearby ride opportunities for you. It\'s one of the most important parts of your experience on Hello Captain.',
                textAlign: TextAlign.center,
              ).subtitle,
              kHeight(25),
              ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, loading, child) {
                  return KButton(
                    onPressed: loading ? null : _checkLocationPermission,
                    label: loading ? 'Loading...' : 'Allow Access',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
