import 'package:facelog/firebase_options.dart';
import 'package:facelog/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// ------------------------
/// BACKGROUND NOTIFICATION HANDLER
/// ------------------------
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("🔔 Background Notification: ${message.notification?.title}");
}

/// ------------------------
/// LOCAL NOTIFICATION SETUP
/// ------------------------
final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> setupLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await localNotifications.initialize(initSettings);
}

/// ------------------------
/// SHOW LOCAL NOTIFICATION
/// ------------------------
Future<void> showLocalNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'default_channel',
    'General Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails notifDetails = NotificationDetails(
    android: androidDetails,
  );

  await localNotifications.show(
    DateTime.now().millisecond,
    message.notification?.title,
    message.notification?.body,
    notifDetails,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------
  // Firebase Initialization
  // ------------------------
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ------------------------
  // Firebase Messaging Setup
  // ------------------------
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local notification setup
  await setupLocalNotifications();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // 🔔 Request notification permission
    requestNotificationPermission();

    // 🔔 Listen for foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground message received!");
      showLocalNotification(message);
    });

    // 🔔 When app opened by tapping the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🚀 Notification Clicked!");
    });

    // 🔥 Retrieve FCM token
    getFcmToken();
  }

  Future<void> requestNotificationPermission() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      sound: true,
      badge: true,
    );

    print("🔐 Notification Permission: ${settings.authorizationStatus}");
  }

  Future<void> getFcmToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("📱 FCM Token: $token");

    // TODO: Save this token to Firestore under the user's document
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facelog Attendance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginPage(),
    );
  }
}
