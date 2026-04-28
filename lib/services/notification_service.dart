import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Must be top-level — required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _db  = FirebaseFirestore.instance;

  // Holds the active order-status listener so we can cancel it on sign-out
  StreamSubscription<QuerySnapshot>? _orderStatusSub;

  // Tracks last-known statuses to detect changes (not just first-load)
  final Map<String, String> _knownStatuses = {};

  // ── Init (call once in main after Firebase.initializeApp) ────────────────
  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Foreground: show a nice in-app banner
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'SoilMate';
      final body  = message.notification?.body  ?? '';
      _showBanner('$title — $body');
    });

    // Tapped while app was in background → navigate to orders
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped (background): ${message.data}');
      _navigatorKey?.currentState?.pushNamed('/orders');
    });

    // Launched from terminated state via notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      debugPrint('App launched from notification: ${initial.data}');
    }
  }

  // ── Navigator key (optional: wire this in MaterialApp for deep-linking) ──
  GlobalKey<NavigatorState>? _navigatorKey;
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // ── Called right after login ──────────────────────────────────────────────
  Future<void> saveTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _fcm.getToken();
    if (token == null) return;

    await _db.collection('users').doc(uid).set(
      {'fcmToken': token, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );

    // Auto-refresh token when it rotates
    _fcm.onTokenRefresh.listen((newToken) async {
      await _db.collection('users').doc(uid).set(
        {'fcmToken': newToken, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    });

    // Start listening for order status changes
    _startOrderStatusListener(uid);
  }

  // ── Firestore listener: in-app alert when order status changes ────────────
  void _startOrderStatusListener(String uid) {
    _orderStatusSub?.cancel();
    _knownStatuses.clear();

    _orderStatusSub = _db
        .collection('orders')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final data   = change.doc.data();
        if (data == null) continue;
        final id     = change.doc.id;
        final status = data['status'] as String? ?? 'pending';

        if (change.type == DocumentChangeType.added) {
          // First time we see this order — just record its status
          _knownStatuses[id] = status;
        } else if (change.type == DocumentChangeType.modified) {
          final prev = _knownStatuses[id];
          if (prev != null && prev != status) {
            // Status actually changed → show notification
            _knownStatuses[id] = status;
            final shortId = id.substring(0, 6).toUpperCase();
            _showBanner('Order #$shortId is now ${_statusLabel(status)}');
          } else {
            _knownStatuses[id] = status;
          }
        }
      }
    });
  }

  /// Call this on sign-out to stop the listener
  void stopOrderStatusListener() {
    _orderStatusSub?.cancel();
    _orderStatusSub = null;
    _knownStatuses.clear();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':       return 'Confirmed ✅';
      case 'preparing':       return 'Being Prepared ⏳';
      case 'shipped':         return 'Out for Delivery 🚚';
      case 'delivered':       return 'Delivered 📦';
      case 'cancelled':       return 'Cancelled ❌';
      case 'returnRequested': return 'Return Requested 🔄';
      case 'refunded':        return 'Refunded 💸';
      default:                return status;
    }
  }

  void _showBanner(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFF3A5C38),
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
    );
  }
}