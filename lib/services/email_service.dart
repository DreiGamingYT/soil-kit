import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  EmailService._();

  static const _publicKey       = 'qxMSsGfUrfCQkwyK4';
  static const _serviceId       = 'service_t0lycao';
  static const _templateAdmin   = 'template_buqg36t';  // existing — admin notification
  static const _templateCustomer = 'template_dfm1hr4'; // ← create this (see below)

  static const _adminEmail = 'gtechsolution.qcu@gmail.com';
  static const _endpoint   = 'https://api.emailjs.com/api/v1.0/email/send';

  // ── Shared helpers ────────────────────────────────────────────────────────
  static String _buildItemLines(List<Map<String, dynamic>> items) {
    return items.map((i) {
      final name     = i['label'] as String;
      final qty      = i['qty']   as int;
      final price    = i['price'] as int;
      final subtotal = price * qty;
      return '• $name\n  Qty: $qty   Unit Price: ₱$price   Subtotal: ₱$subtotal';
    }).join('\n\n');
  }

  static String _buildDate([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    final hour   = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm   = now.hour < 12 ? 'AM' : 'PM';
    return '${months[now.month - 1]} ${now.day}, ${now.year} at $hour:$minute $ampm';
  }

  static String _shortId(String orderId) =>
      orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();

  static Future<void> _send(String templateId, Map<String, String> params) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id':      _serviceId,
          'template_id':     templateId,
          'user_id':         _publicKey,
          'template_params': params,
        }),
      ).timeout(const Duration(seconds: 15));

      // Print full response so we can see what EmailJS says
      print('EmailJS status: ${response.statusCode}');
      print('EmailJS body: ${response.body}');
      print('EmailJS template used: $templateId');
      print('EmailJS to: ${params['email']}');

    } catch (e, st) {
      print('EmailJS ERROR: $e');
      print('EmailJS STACKTRACE: $st');
    }
  }

  // ── 1. Notify ADMIN of new order ──────────────────────────────────────────
  static Future<void> notifyAdminNewOrder({
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String contact,
    required String address,
    required List<Map<String, dynamic>> items,
    required int total,
  }) async {
    await _send(_templateAdmin, {
      'email':          _adminEmail,
      'to_email':       _adminEmail,
      'order_id':       _shortId(orderId),
      'customer_name':  customerName,
      'customer_email': customerEmail,
      'contact':        contact,
      'address':        address,
      'items_table':    _buildItemLines(items),
      'total':          '₱$total',
      'date':           _buildDate(),
    });
  }

  // ── 2. Notify CUSTOMER of order confirmation + status updates ─────────────
  static Future<void> notifyCustomerOrderStatus({
    required String orderId,
    required String customerEmail,
    required String customerName,
    required String status,           // e.g. "confirmed", "shipped", "delivered"
    required String adminNote,
    required List<Map<String, dynamic>> items,
    required int total,
  }) async {
    final statusMessages = {
      'pending':   'We have received your order and it is being reviewed.',
      'confirmed': 'Great news! Your order has been confirmed and is being prepared.',
      'shipped':   'Your order is on its way!',
      'delivered': 'Your order has been delivered. Thank you for your purchase!',
      'cancelled': 'Your order has been cancelled. Please contact us for more info.',
    };

    await _send(_templateCustomer, {
      'email':          customerEmail,
      'to_email':       customerEmail,
      'customer_name':  customerName,
      'order_id':       _shortId(orderId),
      'status':         status.toUpperCase(),
      'status_message': statusMessages[status] ?? 'Your order status has been updated.',
      'admin_note':     adminNote.isNotEmpty ? adminNote : 'No additional notes.',
      'items_table':    _buildItemLines(items),
      'total':          '₱$total',
      'date':           _buildDate(),
    });
  }
}