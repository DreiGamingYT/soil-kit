import 'dart:convert';
import 'package:http/http.dart' as http;

/// Sends a new-order notification email to the admin via EmailJS.
///
/// FREE setup (one time) at https://www.emailjs.com
/// ─────────────────────────────────────────────────
/// 1. Create a free EmailJS account (200 emails/month free).
/// 2. Email Services → Add Service → Gmail → connect gtechsolution.qcu@gmail.com
/// 3. Email Templates → Create Template  (template name: "New Order Notification")
///    Subject : New Order #{{order_id}} from {{customer_name}} — {{date}}
///    Body    : use the variables listed below
/// 4. Paste your Public Key, Service ID, and Template ID into the constants below.
///
/// ── Template variables ────────────────────────────────────────────────────────
///   {{order_id}}       — short 8-char ID,  e.g. "A1B2C3D4"
///   {{customer_name}}  — full name or email prefix
///   {{customer_email}} — customer's email address
///   {{contact}}        — phone / contact number entered at checkout
///   {{address}}        — delivery address entered at checkout
///   {{items_table}}    — full item breakdown, one item per block:
///                          • Nitrogen (N) Reagent
///                            Qty: 2   Unit Price: ₱99   Subtotal: ₱198
///   {{total}}          — grand total,  e.g. "₱495"
///   {{date}}           — human-readable date, e.g. "April 19, 2026 at 2:35 PM"
///
/// ── Suggested template body ───────────────────────────────────────────────────
///   You have a new order!
///
///   Order ID  : {{order_id}}
///   Date      : {{date}}
///
///   Customer  : {{customer_name}}
///   Email     : {{customer_email}}
///   Contact   : {{contact}}
///   Address   : {{address}}
///
///   ── Items ──
///   {{items_table}}
///
///   ── Grand Total: {{total}} ──
class EmailService {
  EmailService._();

  // ── Fill these in after EmailJS setup ─────────────────────────────────────
  static const _publicKey  = 'YOUR_EMAILJS_PUBLIC_KEY';  // Account → API Keys
  static const _serviceId  = 'YOUR_EMAILJS_SERVICE_ID';  // Email Services tab
  static const _templateId = 'YOUR_TEMPLATE_ID';         // Email Templates tab
  // ──────────────────────────────────────────────────────────────────────────

  static const _adminEmail = 'gtechsolution.qcu@gmail.com';
  static const _endpoint   = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Called right after a customer successfully places an order.
  /// Fire-and-forget — the caller should use `.ignore()` so it never blocks UI.
  static Future<void> notifyAdminNewOrder({
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String contact,
    required String address,
    required List<Map<String, dynamic>> items,
    required int total,
  }) async {
    // Build items table — one block per item showing name, qty, unit price, subtotal
    final itemLines = items.map((i) {
      final name     = i['label'] as String;
      final qty      = i['qty']   as int;
      final price    = i['price'] as int;
      final subtotal = price * qty;
      return '• $name\n'
          '  Qty: $qty   Unit Price: \u20b1$price   Subtotal: \u20b1$subtotal';
    }).join('\n\n');

    // Human-readable date: e.g. "April 19, 2026 at 2:35 PM"
    final now    = DateTime.now();
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    final hour   = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm   = now.hour < 12 ? 'AM' : 'PM';
    final date   = '${months[now.month - 1]} ${now.day}, ${now.year} at $hour:$minute $ampm';

    try {
      await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id':  _serviceId,
          'template_id': _templateId,
          'user_id':     _publicKey,
          'template_params': {
            'to_email':       _adminEmail,
            'order_id':       orderId.substring(0, 8).toUpperCase(),
            'customer_name':  customerName,
            'customer_email': customerEmail,
            'contact':        contact,
            'address':        address,
            'items_table':    itemLines,
            'total':          '\u20b1$total',
            'date':           date,
          },
        }),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      // Email failure is non-critical — order is already saved in Firestore.
    }
  }
}
