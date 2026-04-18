import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/order_service.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: OrderService.instance.myOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: SoilColors.primaryLight.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined,
                        size: 34, color: SoilColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('No orders yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Your orders will appear here\nonce you place one from the Shop.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13,
                          color: Colors.grey.withOpacity(0.7), height: 1.5)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final doc  = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _OrderCard(
                orderId: doc.id,
                data: data,
                onTap: () => _showDetail(context, doc.id, data),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext ctx, String id, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(orderId: id, data: data),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _OrderCard({required this.orderId, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final status = data['status'] ?? 'pending';
    final items  = (data['items'] as List? ?? []);
    final total  = data['total'] ?? 0;
    final ts     = data['createdAt'] as Timestamp?;
    final date   = ts != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(ts.toDate())
        : 'Processing...';
    final (lbl, col, ico) = _statusInfo(status);
    final shortId = orderId.substring(0, 8).toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(Sr.rLg),
          border: Border.all(color: cs.outline),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #$shortId',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(date, style: TextStyle(fontSize: 11.5,
                  color: cs.onSurface.withOpacity(0.42))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: col.withOpacity(0.12),
                borderRadius: BorderRadius.circular(Sr.rPill),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(ico, size: 12, color: col),
                const SizedBox(width: 4),
                Text(lbl, style: TextStyle(color: col,
                    fontWeight: FontWeight.w700, fontSize: 11)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Divider(height: 1, color: cs.outline.withOpacity(0.6)),
          const SizedBox(height: 12),
          ...items.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: SoilColors.primaryLight.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(child: Text('${item['qty']}x',
                    style: const TextStyle(fontSize: 9,
                        fontWeight: FontWeight.w800, color: SoilColors.primary))),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(item['name'] ?? '',
                  style: TextStyle(fontSize: 12.5,
                      color: cs.onSurface.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis)),
              Text('₱${(item['price'] ?? 0) * (item['qty'] ?? 1)}',
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.55))),
            ]),
          )),
          if (items.length > 3)
            Text('+${items.length - 3} more item(s)',
                style: TextStyle(fontSize: 11.5,
                    color: cs.onSurface.withOpacity(0.38),
                    fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Divider(height: 1, color: cs.outline.withOpacity(0.6)),
          const SizedBox(height: 10),
          Row(children: [
            Text('Total', style: TextStyle(fontSize: 13,
                color: cs.onSurface.withOpacity(0.45))),
            const SizedBox(width: 6),
            Text('₱$total', style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w800, color: SoilColors.primary)),
            const Spacer(),
            Text('View details', style: TextStyle(fontSize: 11.5,
                color: SoilColors.primary.withOpacity(0.7),
                fontWeight: FontWeight.w600)),
            Icon(Icons.chevron_right_rounded, size: 16,
                color: SoilColors.primary.withOpacity(0.7)),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _OrderDetailSheet extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  const _OrderDetailSheet({required this.orderId, required this.data});

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bot     = MediaQuery.of(context).padding.bottom;
    final status  = data['status'] ?? 'pending';
    final items   = (data['items'] as List? ?? []);
    final total   = data['total'] ?? 0;
    final ts      = data['createdAt'] as Timestamp?;
    final date    = ts != null
        ? DateFormat('MMMM d, yyyy • h:mm a').format(ts.toDate()) : 'Processing...';
    final address = data['address'] ?? '';
    final contact = data['contact'] ?? '';
    final shortId = orderId.substring(0, 8).toUpperCase();
    final (_, col, _) = _statusInfo(status);

    const steps = [
      (l: 'Pending',    i: Icons.schedule_rounded),
      (l: 'Approved',   i: Icons.verified_rounded),
      (l: 'Packed',     i: Icons.inventory_2_rounded),
      (l: 'To Receive', i: Icons.local_shipping_rounded),
    ];
    const statusKeys = ['pending', 'approved', 'packed', 'to_receive'];
    final curStep = statusKeys.indexOf(status);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? SoilColors.surfaceDark : SoilColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Sr.rXl)),
      ),
      padding: EdgeInsets.only(bottom: bot + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 38, height: 4,
          decoration: BoxDecoration(
              color: cs.outline, borderRadius: BorderRadius.circular(Sr.rPill)),
        )),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Order #$shortId',
                      style: const TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 3),
                  Text(date, style: TextStyle(fontSize: 12,
                      color: cs.onSurface.withOpacity(0.42))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(Sr.rPill),
                  ),
                  child: Text(status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(color: col, fontWeight: FontWeight.w800,
                          fontSize: 11, letterSpacing: 0.5)),
                ),
              ]),

              const SizedBox(height: 22),

              // Timeline
              _label('Order Progress'),
              const SizedBox(height: 12),
              Row(
                children: steps.asMap().entries.map((e) {
                  final i      = e.key;
                  final step   = e.value;
                  final done   = i <= curStep;
                  final active = i == curStep;
                  final c      = done ? col : cs.onSurface.withOpacity(0.22);
                  final isLast = i == steps.length - 1;
                  return Expanded(
                    child: Row(children: [
                      Expanded(child: Column(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: active ? 38 : 32,
                          height: active ? 38 : 32,
                          decoration: BoxDecoration(
                            color: done ? col.withOpacity(0.15) : cs.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: done ? col : cs.outline,
                                width: active ? 2.2 : 1.5),
                          ),
                          child: Icon(step.i, size: active ? 18 : 15, color: c),
                        ),
                        const SizedBox(height: 6),
                        Text(step.l, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 9.5,
                                fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                                color: done ? col : cs.onSurface.withOpacity(0.35),
                                height: 1.3)),
                      ])),
                      if (!isLast)
                        Expanded(child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 26),
                          color: i < curStep
                              ? col.withOpacity(0.5) : cs.outline.withOpacity(0.4),
                        )),
                    ]),
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              // Items
              _label('Items Ordered'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(Sr.rLg),
                  border: Border.all(color: cs.outline),
                ),
                child: Column(children: [
                  ...items.asMap().entries.map((e) {
                    final item  = e.value;
                    final last  = e.key == items.length - 1;
                    final price = (item['price'] ?? 0) * (item['qty'] ?? 1);
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: SoilColors.primaryLight.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text('${item['qty']}×',
                                style: const TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: SoilColors.primary))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'] ?? '',
                                    style: const TextStyle(fontSize: 13.5,
                                        fontWeight: FontWeight.w600)),
                                Text('₱${item['price']} each',
                                    style: TextStyle(fontSize: 11.5,
                                        color: cs.onSurface.withOpacity(0.42))),
                              ])),
                          Text('₱$price', style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: SoilColors.primary)),
                        ]),
                      ),
                      if (!last) Divider(height: 1, indent: 16, endIndent: 16,
                          color: cs.outline.withOpacity(0.5)),
                    ]);
                  }),
                  Divider(height: 1, color: cs.outline),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface.withOpacity(0.55))),
                        Text('₱$total', style: const TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: SoilColors.primary, letterSpacing: -0.4)),
                      ],
                    ),
                  ),
                ]),
              ),

              // Delivery info
              if (address.isNotEmpty || contact.isNotEmpty) ...[
                const SizedBox(height: 18),
                _label('Delivery Info'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(Sr.rLg),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Column(children: [
                    if (contact.isNotEmpty)
                      _InfoRow(icon: Icons.phone_outlined,
                          label: 'Contact', value: contact),
                    if (contact.isNotEmpty && address.isNotEmpty)
                      const SizedBox(height: 10),
                    if (address.isNotEmpty)
                      _InfoRow(icon: Icons.location_on_outlined,
                          label: 'Address', value: address),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ]),
    );
  }

  static Widget _label(String t) => Text(t.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 1.1, color: SoilColors.primary));
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: SoilColors.primary.withOpacity(0.7)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.38), letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13.5,
            fontWeight: FontWeight.w600)),
      ]),
    ]);
  }
}

(String, Color, IconData) _statusInfo(String s) {
  switch (s) {
    case 'approved':   return ('Approved',   Colors.blue,   Icons.verified_rounded);
    case 'packed':     return ('Packed',     Colors.orange, Icons.inventory_2_rounded);
    case 'to_receive': return ('To Receive', Colors.green,  Icons.local_shipping_rounded);
    default:           return ('Pending',    SoilColors.clay, Icons.schedule_rounded);
  }
}