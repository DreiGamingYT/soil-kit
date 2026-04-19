import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  OrderService._();
  static final instance = OrderService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> placeOrder(
      List<Map<String, dynamic>> items,
      int total, {
        String contact = '',
        String address = '',
      }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    final ref = await _db.collection('orders').add({
      'uid':           uid,
      'items':         items,
      'total':         total,
      'status':        'pending',
      'contact':       contact,
      'address':       address,
      'customerName':  _auth.currentUser?.displayName
          ?? _auth.currentUser?.email?.split('@').first
          ?? '',
      'customerEmail': _auth.currentUser?.email ?? '',
      'createdAt':     FieldValue.serverTimestamp(),
      'adminNote':     '',
    });

    return ref.id;
  }

  // ── Customer: stream own orders ───────────────────────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> myOrders() {
    final uid = _auth.currentUser?.uid;
    return _db
        .collection('orders')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ── Admin: stream ALL orders ──────────────────────────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> allOrders({String? statusFilter}) {
    Query<Map<String, dynamic>> q = _db
        .collection('orders')
        .orderBy('createdAt', descending: true);

    if (statusFilter != null && statusFilter != 'all') {
      q = q.where('status', isEqualTo: statusFilter);
    }
    return q.snapshots();
  }

  // ── Admin: update order status ────────────────────────────────────────────
  Future<void> updateOrderStatus(
      String orderId,
      String newStatus, {
        String adminNote = '',
      }) async {
    await _db.collection('orders').doc(orderId).update({
      'status':    newStatus,
      'adminNote': adminNote,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Admin: check if current user is admin ─────────────────────────────────
  bool get isAdmin =>
      _auth.currentUser?.email == 'gtechsolution.qcu@gmail.com';
}