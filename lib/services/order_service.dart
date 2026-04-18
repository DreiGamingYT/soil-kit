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
    if (uid == null) return;

    await _db.collection('orders').add({
      'uid':       uid,
      'items':     items,
      'total':     total,
      'status':    'pending',
      'contact':   contact,
      'address':   address,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Used by shop_screen.dart
  Stream<QuerySnapshot<Map<String, dynamic>>> myOrders() {
    final uid = _auth.currentUser?.uid;
    return _db
        .collection('orders')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}