import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Pages/Auth/Forgot_password_UI.dart';
import 'package:hello_captain_user/Pages/Auth/Login_UI.dart';
import 'package:hello_captain_user/Pages/News/News_Detail_UI.dart';
import 'package:hello_captain_user/Pages/News/News_UI.dart';
import 'package:hello_captain_user/Pages/Orders/Order_Detail_UI.dart';
import 'package:hello_captain_user/Pages/Orders/Orders_UI.dart';
import 'package:hello_captain_user/Pages/Profile/Emergency_Contact_UI.dart';
import 'package:hello_captain_user/Pages/Profile/Khalti_UI.dart';
import 'package:hello_captain_user/Pages/Profile/Subscription_Pass_UI.dart';
import 'package:hello_captain_user/Pages/Profile/Transaction_History_UI.dart';
import 'package:hello_captain_user/Pages/Service/Confirmation_UI.dart';
import 'package:hello_captain_user/Pages/Service/Locate_Driver_UI.dart';
import 'package:hello_captain_user/Pages/Service/Merchant/Merchant_Checkout_UI.dart';
import 'package:hello_captain_user/Pages/Service/Merchant/Merchant_Detail_UI.dart';
import 'package:hello_captain_user/Pages/Service/Passenger_Transportation_UI.dart';
import 'package:hello_captain_user/Pages/Chat/Chat_Detail_UI.dart';
import 'package:hello_captain_user/Pages/Chat/Chat_UI.dart';
import 'package:hello_captain_user/Pages/Places/Search_Place_UI.dart';
import 'package:hello_captain_user/Pages/Profile/About_UI.dart';
import 'package:hello_captain_user/Pages/Profile/Change_Password_UI.dart';
import 'package:hello_captain_user/Pages/Profile/Edit_Profile_UI.dart';
import 'package:hello_captain_user/Pages/Profile/Privacy_UI.dart';
import 'package:hello_captain_user/Pages/Profile/Profile_UI.dart';
import 'package:hello_captain_user/Pages/Profile/Promo_UI.dart';
import 'package:hello_captain_user/Pages/Profile/Recharge_UI.dart';
import 'package:hello_captain_user/Pages/Profile/Withdraw_UI.dart';
import 'package:hello_captain_user/Pages/Service/Purchasing_Service_UI.dart';
import 'package:hello_captain_user/Pages/Service/Rental_UI.dart';
import 'package:hello_captain_user/Pages/Request_Location_UI.dart';
import 'package:hello_captain_user/Pages/Service/Shipment/Shipment_Detail_UI.dart';
import 'package:hello_captain_user/Pages/Service/Shipment/Shipment_UI.dart';
import 'package:hello_captain_user/Pages/Splash_UI.dart';
import 'package:hello_captain_user/Pages/Welcome_UI.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Pages/Auth/LoginOtp_UI.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Pages/Auth/Register_UI.dart';
import '../Pages/Error/Server_Error_UI.dart';
import '../Pages/Root_UI.dart';
import 'Location_Helper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AuthNotifier extends ChangeNotifier {
  final Ref ref;
  bool locationPermissionGranted = false;

  bool _isLoading = false;

  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  AuthNotifier(this.ref) {
    _init();
  }

  Future<void> _init() async {
    isLoading = true;
    notifyListeners();
    locationPermissionGranted = await LocationService.requestPermission();
    isLoading = false;
    notifyListeners();
  }

  Future<void> checkLocationPermission() async {
    isLoading = true;
    notifyListeners();
    locationPermissionGranted = await LocationService.requestPermission();
    isLoading = false;
    notifyListeners();
  }
}

final authNotifierProvider = ChangeNotifierProvider((ref) => AuthNotifier(ref));

final routeProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authFuture);
  final user = ref.watch(userProvider);
  // final authNotifier = ref.watch(authNotifierProvider); //TODO
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: "/",
    // refreshListenable: authNotifier, //TODO
    redirect: (context, state) async {
      // if (authState.isLoading || authNotifier.isLoading) return "/splash"; //TODO
      if (authState.isLoading) return "/splash";

      if (user == null &&
          ![
            '/login',
            '/register',
            '/forgot-password',
            '/welcome',
            '/splash',
            '/login-otp',
          ].contains(state.fullPath)) {
        return '/login-otp';
      }
      if (user != null && state.fullPath == '/login') {
        return '/';
      }

      final locationPermissionStatus =
          await Permission.locationWhenInUse.status;
      // log("Location Permission Status: $locationPermissionStatus");

      if (user != null &&
          state.fullPath == '/' &&
          locationPermissionStatus != PermissionStatus.granted &&
          Platform.isAndroid) {
        return '/request-location';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/server-error',
        builder: (context, state) => const Server_Error_UI(),
      ),
      GoRoute(path: "/splash", builder: (context, state) => Splash_UI()),
      GoRoute(path: "/welcome", builder: (context, state) => Welcome_UI()),
      GoRoute(
        path: "/request-location",
        builder: (context, state) => Request_Location_UI(),
      ),
      GoRoute(path: "/", builder: (context, state) => Root_UI()),
      GoRoute(path: "/login", builder: (context, state) => Login_UI()),
      GoRoute(path: "/login-otp", builder: (context, state) => LoginOtp_UI()),

      GoRoute(path: "/register", builder: (context, state) => Register_UI()),
      GoRoute(
        path: "/forgot-password",
        builder: (context, state) => Forgot_Password_UI(),
      ),
      GoRoute(
        path: "/chat",
        builder: (context, state) => Chat_UI(),
        routes: [
          GoRoute(
            path: "/detail/:id",
            builder:
                (context, state) => Chat_Detail_UI(
                  receiverId: state.pathParameters["id"] ?? "",
                  pic: (state.extra as Map<String, dynamic>)['pic'],
                  name: (state.extra as Map<String, dynamic>)['name'],
                ),
          ),
        ],
      ),
      GoRoute(
        path: "/profile",
        builder: (context, state) => Profile_UI(),
        routes: [
          GoRoute(
            path: "recharge",
            builder: (context, state) => Recharge_UI(),
            routes: [
              GoRoute(
                path: "pay-khalti",
                builder:
                    (context, state) => Khalti_UI(
                      pidx: (state.extra as Map<String, dynamic>)['pidx'],
                    ),
              ),
            ],
          ),
          GoRoute(path: "withdraw", builder: (context, state) => Withdraw_UI()),
          GoRoute(
            path: "change-password",
            builder: (context, state) => Change_Password_UI(),
          ),
          GoRoute(path: "promo", builder: (context, state) => Promo_UI()),
          GoRoute(
            path: "subscription-pass",
            builder: (context, state) => Subscription_Pass_UI(),
          ),
          GoRoute(
            path: "transaction-history",
            builder: (context, state) => Transaction_History_UI(),
          ),
          GoRoute(path: "edit", builder: (context, state) => Edit_Profile_UI()),
          GoRoute(path: "privacy", builder: (context, state) => Privacy_UI()),
          GoRoute(path: "about-us", builder: (context, state) => About_UI()),
          GoRoute(
            path: "emergency-contact",
            builder: (context, state) => Emergency_Contact_UI(),
          ),
        ],
      ),
      GoRoute(
        path: "/passenger-transportation",
        builder:
            (context, state) => Passenger_Transportation_UI(
              serviceData: state.extra as Map<String, dynamic>,
              serviceImage:
                  (state.extra as Map<String, dynamic>)['serviceImage'],
              serviceName: (state.extra as Map<String, dynamic>)['serviceName'],
            ),
      ),
      GoRoute(
        path: "/rental",
        builder:
            (context, state) => Rental_UI(
              serviceData: state.extra as Map<String, dynamic>,
              serviceImage:
                  (state.extra as Map<String, dynamic>)['serviceImage'],
              serviceName: (state.extra as Map<String, dynamic>)['serviceName'],
            ),
      ),
      GoRoute(
        path: "/shipment",
        builder:
            (context, state) => Shipment_UI(
              serviceData: state.extra as Map<String, dynamic>,
              serviceImage:
                  (state.extra as Map<String, dynamic>)['serviceImage'],
              serviceName: (state.extra as Map<String, dynamic>)['serviceName'],
            ),
        routes: [
          GoRoute(
            path: "detail",
            builder:
                (context, state) => Shipment_Detail_UI(
                  serviceData: state.extra as Map<String, dynamic>,
                ),
          ),
        ],
      ),
      GoRoute(
        path: "/purchasing-service",
        builder:
            (context, state) => Purchasing_Service_UI(
              serviceData: state.extra as Map<String, dynamic>,
            ),
      ),
      GoRoute(
        path: "/search-place",
        builder: (context, state) => Search_Place_UI(),
      ),
      GoRoute(path: "/all-news", builder: (context, state) => News_UI()),
      GoRoute(
        path: "/news-detail/:id",
        builder:
            (context, state) =>
                News_Detail_UI(newsId: state.pathParameters['id'] ?? ""),
      ),
      GoRoute(
        path: "/merchant/detail",
        builder: (context, state) {
          Map<String, dynamic> serviceData =
              state.extra as Map<String, dynamic>;

          return Merchant_Detail_UI(
            serviceId: "${serviceData['service_id']}",
            merchantId: "${serviceData['merchant_id']}",
            serviceName: (state.extra as Map<String, dynamic>)['service'] ?? "",
          );
        },

        routes: [
          GoRoute(
            path: "checkout",
            builder:
                (context, state) => Merchant_Checkout_UI(
                  serviceId: (state.extra as Map)['serviceId'] ?? "",
                  serviceName: (state.extra as Map)['serviceName'] ?? "",
                ),
          ),
        ],
      ),

      GoRoute(
  path: "/confirmation",
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return Confirmation_UI(
      subtitle: extra['subtitle'],
      description: extra['description'],
      transactionId: extra['transactionId'],
      driverId: extra['driverId'],
    );
  },
),


      GoRoute(
        path: "/order-detail/:transactionId/:driverId",
        builder:
            (context, state) => Order_Detail_UI(
              driverId: state.pathParameters['driverId']!,
              transactionId: state.pathParameters['transactionId']!,
            ),
      ),
      GoRoute(path: "/orders", builder: (context, state) => const Orders_UI()),

      GoRoute(
        path: "/locate-driver/:driverId",
        builder:
            (context, state) => Locate_Driver_UI(
              driverId: state.pathParameters['driverId']!,
              serviceId: (state.extra as Map<String, dynamic>)['serviceId'],
              pickupPos: (state.extra as Map<String, dynamic>)['pickupPos'],
              dropPos: (state.extra as Map<String, dynamic>)['dropPos'],
            ),
      ),
    ],
  );
});
