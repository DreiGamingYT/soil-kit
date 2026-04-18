import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Called when user taps "Order" in the shop screen
  Future<void> placeOrder(List<Map<String, dynamic>> items) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('orders').add({
      'uid': uid,
      'items': items,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream used by My Orders screen (step 4 in diagram)
  Stream<QuerySnapshot> listenToMyOrders() {
    final uid = _auth.currentUser?.uid;
    return _db
        .collection('orders')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}