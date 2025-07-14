// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hello_captain_user/Helper/route_config.dart';
import 'package:path_provider/path_provider.dart';

class NotificationConstants {
  static const String groupBaseUrl =
      "https://fcm.googleapis.com/fcm/notification";
}

class FirebaseNotificationService {
  final FirebaseMessaging _fcmMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Platform-specific channel configuration
  late final AndroidNotificationChannel _androidChannel;
  late final DarwinNotificationDetails _iosNotificationDetails;

  Future<void> initialize() async {
    await _setupPlatformSpecifics();
    await _requestPermissions();
    await _initializeLocalNotifications();
    await _setupFirebaseListeners();
    await _subscribeToDefaultTopics();
  }

  Future<void> _setupPlatformSpecifics() async {
    if (Platform.isAndroid) {
      _androidChannel = const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications only',
        importance: Importance.high,
        playSound: true,
      );
    } else if (Platform.isIOS) {
      _iosNotificationDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (Platform.isIOS) {
        await _fcmMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
      } else if (Platform.isAndroid) {
        // Android 13+ requires runtime permission

        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
    } catch (e) {
      log('Error requesting notification permissions: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false, // Already requested
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          if (details.payload != null) {
            final message = RemoteMessage.fromMap(jsonDecode(details.payload!));
            _handleMessage(message);
          }
        },
      );

      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(_androidChannel);
      }
    } catch (e) {
      log('Error initializing local notifications: $e');
    }
  }

  Future<void> _setupFirebaseListeners() async {
    try {
      await _fcmMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle initial message when app is launched from terminated state
      final initialMessage = await _fcmMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      // Listen for messages when app is in foreground
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);

      // Listen for when app is opened from background state
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      // Setup background handler
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    } catch (e) {
      log('Error setting up Firebase listeners: $e');
    }
  }

  Future<void> _subscribeToDefaultTopics() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final isSimulator = await _isSimulator();
        if (!isSimulator) {
          final apnsToken = await _retrieveAPNSToken();
          if (apnsToken != null) {
            log('iOS APNS token: $apnsToken');
          }
        }
      }

      // Subscribe to default topics
      await _fcmMessaging.subscribeToTopic('ouride');
      await _fcmMessaging.subscribeToTopic('customer');
      log('Subscribed to default topic: ouride & customer');
    } catch (e) {
      log('Error subscribing to topics: $e');
    }
  }

  Future<bool> _isSimulator() async {
    try {
      if (Platform.isIOS) {
        final result = await Process.run('sw_vers', []);
        return result.stdout.toString().contains('ProductVersion');
      }
      return false;
    } catch (e) {
      log('Error checking simulator status: $e');
      return false;
    }
  }

  Future<String?> _retrieveAPNSToken({int maxRetries = 10}) async {
    try {
      String? apnsToken;
      int retryCount = 0;

      while (apnsToken == null && retryCount < maxRetries) {
        apnsToken = await _fcmMessaging.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(milliseconds: 300));
          retryCount++;
        }
      }
      return apnsToken;
    } catch (e) {
      log('Error retrieving APNS token: $e');
      return null;
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      String? imagePath;
      if (Platform.isAndroid && notification.android?.imageUrl != null) {
        imagePath = await _downloadImage(
          notification.android!.imageUrl!,
          'bigPicture',
        );
      }

      final platformDetails = _getPlatformNotificationDetails(
        notification,
        imagePath: imagePath,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: jsonEncode(message.toMap()),
      );
    } catch (e) {
      log('Error showing foreground notification: $e');
    }
  }

  NotificationDetails _getPlatformNotificationDetails(
    RemoteNotification notification, {
    String? imagePath,
  }) {
    if (Platform.isAndroid) {
      return NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@drawable/ic_stat_ic_launcher',
          styleInformation:
              imagePath != null
                  ? BigPictureStyleInformation(FilePathAndroidBitmap(imagePath))
                  : null,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: _iosNotificationDetails,
      );
    } else if (Platform.isIOS) {
      return NotificationDetails(iOS: _iosNotificationDetails);
    }
    return const NotificationDetails();
  }

  Future<String?> _downloadImage(String url, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final response = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final file = File(filePath);
      await file.writeAsBytes(response.data!);
      return filePath;
    } catch (e) {
      log('Error downloading notification image: $e');
      return null;
    }
  }

  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;
    log('Handling message: ${message.messageId}');

    // Example navigation - adjust based on your app's needs
    navigatorKey.currentState?.pushNamed("/chat");

    // You could also parse data payload for specific routing:
    // final route = message.data['route'];
    // if (route != null) {
    //   navigatorKey.currentState?.pushNamed(route);
    // }
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();

  // You might want to show a notification here as well
  log('Handling background message: ${message.messageId}');
  // Process your background message here
}
