import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/order_service.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return Colors.blue;
      case 'packed': return Colors.orange;
      case 'out_for_delivery': return Colors.purple;
      case 'to_receive': return Colors.green;
      default: return Colors.grey; // pending
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: OrderService().listenToMyOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No orders yet.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              return ListTile(
                title: Text('Order #${docs[i].id.substring(0, 6).toUpperCase()}'),
                subtitle: Text('Items: ${(data['items'] as List).length}'),
                trailing: Chip(
                  label: Text(status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                  backgroundColor: _statusColor(status),
                ),
              );
            },
          );
        },
      ),
    );
  }
}