import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Helper/notification_config.dart';
import 'package:hello_captain_user/Helper/route_config.dart';
import 'package:hello_captain_user/Resources/theme.dart';
import 'package:hello_captain_user/Secret/Map_Key.dart';
import 'package:hello_captain_user/firebase_options.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'Helper/hive_config.dart';
import 'Resources/commons.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  await FirebaseNotificationService().initialize();
  await HiveConfig.init();
  MapboxOptions.setAccessToken(MAPBOX_ACCESS_TOKEN);
  systemColors();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeConfig = ref.watch(routeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Hello Captain',
      theme: kTheme(context),
      routerConfig: routeConfig,
    );
  }
}
