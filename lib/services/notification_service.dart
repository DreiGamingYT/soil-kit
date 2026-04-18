import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Must be top-level (outside any class) — required by Firebase
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled automatically by the OS tray.
  // No extra work needed here unless you want to log them.
  debugPrint('FCM background: ${message.notification?.title}');
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _db  = FirebaseFirestore.instance;

  /// Call once in main() after Firebase.initializeApp()
  Future<void> init() async {
    // 1. Register the background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permission (iOS + Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Handle messages while app is in the FOREGROUND
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'SoilMate';
      final body  = message.notification?.body  ?? '';
      _showToast('$title — $body');
    });

    // 4. Handle notification tap when app was in BACKGROUND (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped (background): ${message.data}');
      // You can navigate to MyOrdersScreen here if needed
    });

    // 5. Check if app was launched from a terminated state via notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      debugPrint('App launched from notification: ${initial.data}');
    }
  }

  /// Call this right after the user logs in successfully.
  /// Saves the device FCM token to Firestore so the Admin app can
  /// look it up and send targeted push notifications.
  Future<void> saveTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _fcm.getToken();
    if (token == null) return;

    await _db.collection('users').doc(uid).set(
      {'fcmToken': token, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );

    // Refresh token automatically when it rotates
    _fcm.onTokenRefresh.listen((newToken) async {
      await _db.collection('users').doc(uid).set(
        {'fcmToken': newToken, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    });
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFF3A5C38),
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
    );
  }
}