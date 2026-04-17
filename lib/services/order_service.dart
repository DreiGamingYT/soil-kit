import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> placeOrder({
    required List<Map<String, dynamic>> items,
    required int total,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in to place an order.');
    }

    await _firestore.collection('orders').add({
      'userId': user.uid,
      'userName': user.displayName ?? '',
      'userEmail': user.email ?? '',
      'items': items,
      'total': total,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myOrders() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in.');
    }

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}