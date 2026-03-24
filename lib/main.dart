
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
  print("Background Notification: ${message.notification?.title}");
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
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    message.notification?.title,
    message.notification?.body,
    notifDetails,
  );
}

/// ------------------------
/// MAIN FUNCTION
/// ------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Run app FIRST (important for speed)
  runApp(const MyApp());

  // Setup notifications AFTER UI loads
  await setupLocalNotifications();
}

/// ------------------------
/// APP ROOT
/// ------------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

    // Run async setup WITHOUT blocking UI
    Future.microtask(() {
      initNotifications();
    });
  }

  /// ------------------------
  /// INIT NOTIFICATIONS (NON-BLOCKING)
  /// ------------------------
  Future<void> initNotifications() async {
    print("Step 1: Request Permission");
    await requestNotificationPermission();

    print("Step 2: Setup Listeners");
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message received!");
      showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🚀 Notification Clicked!");
    });

    print("Step 3: Get Token");
    await getFcmToken();

    print("✅ Notification setup complete");
  }

  /// ------------------------
  /// REQUEST PERMISSION
  /// ------------------------
  Future<void> requestNotificationPermission() async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        sound: true,
        badge: true,
      );

      print("🔐 Permission: ${settings.authorizationStatus}");
    } catch (e) {
      print("Permission error: $e");
    }
  }

  /// ------------------------
  /// GET FCM TOKEN (WITH TIMEOUT)
  /// ------------------------
  Future<void> getFcmToken() async {
    try {
      String? token = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 5));

      print("📱 FCM Token: $token");

      // TODO: Save token to Firestore
    } catch (e) {
      print("❌ FCM Token error: $e");
    }
  }

  /// ------------------------
  /// UI
  /// ------------------------
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facelog Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginPage(),
    );
  }
}

