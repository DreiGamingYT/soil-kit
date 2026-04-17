import 'package:flutter/material.dart';
import '../main.dart';
import '../services/order_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

// ── Reagent data ──────────────────────────────────────────────────────────────
class _Reagent {
  final String name, subtitle, icon;
  const _Reagent(this.name, this.subtitle, this.icon);
}

const _reagents = [
  _Reagent('Nitrogen (N)', 'Measures available nitrogen in soil', '🟦'),
  _Reagent('Phosphorus (P)', 'Detects phosphate concentration', '🟧'),
  _Reagent('Potassium (K)', 'Tests potassium (potash) levels', '🟪'),
  _Reagent('pH Indicator', 'Measures soil acidity or alkalinity', '🟩'),
  _Reagent('Ammonium Nitrate', 'Provides nitrogen (fertilizer, not a test reagent)', '🟫'),
];

// ── Cart item ─────────────────────────────────────────────────────────────────
class _CartItem {
  final String key, label;
  final int price;
  int qty;
  _CartItem({required this.key, required this.label, required this.price, required this.qty});
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ShopScreen extends StatefulWidget {
  final bool showBottomNav;
  const ShopScreen({super.key, this.showBottomNav = false});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final List<_CartItem> _cart = [];

  int get _cartCount => _cart.fold(0, (a, b) => a + b.qty);
  int get _cartTotal => _cart.fold(0, (a, b) => a + b.price * b.qty);

  void _addCartItem(String key, String label, int price) {
    setState(() {
      final existing = _cart.where((c) => c.key == key);
      if (existing.isNotEmpty) {
        existing.first.qty++;
      } else {
        _cart.add(_CartItem(key: key, label: label, price: price, qty: 1));
      }
    });
    _showAddedSnack(label);
  }

  void _showAddedSnack(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('$label added to cart', style: const TextStyle(fontSize: 13)),
        ]),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sr.rSm)),
        backgroundColor: SoilColors.primary,
      ),
    );
  }

  void _openReagentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReagentModal(
        onSelect: (r) {
          Navigator.pop(context);
          _addCartItem('reagent_${r.name}', '${r.name} Reagent', 99);
        },
      ),
    );
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (_, setS) => _CartSheet(
          cart: _cart,
          total: _cartTotal,
          onRemove: (item) => setS(() {
            setState(() {
              if (item.qty > 1) {
                item.qty--;
              } else {
                _cart.remove(item);
              }
            });
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        automaticallyImplyLeading: false,
        actions: [
          if (_cartCount > 0)
            GestureDetector(
              onTap: _openCart,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        color: cs.onSurface.withOpacity(0.7), size: 24),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: SoilColors.clay,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$_cartCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero banner ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SoilColors.primary, SoilColors.primaryMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(Sr.rXl),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Soil Test Supplies',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Get genuine reagents & tools\nfor accurate soil testing.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🧪', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'My Orders',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 170,
              child: StreamBuilder(
                stream: OrderService.instance.myOrders(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(Sr.rLg),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Center(
                        child: Text(
                          'Unable to load orders',
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.55),
                          ),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(Sr.rLg),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Center(
                        child: Text(
                          'No orders yet',
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final status = data['status'] ?? 'pending';

                      Color statusColor;
                      IconData icon;

                      switch (status) {
                        case 'approved':
                          statusColor = Colors.blue;
                          icon = Icons.verified_rounded;
                          break;
                        case 'packed':
                          statusColor = Colors.orange;
                          icon = Icons.inventory_2_rounded;
                          break;
                        case 'to_receive':
                          statusColor = Colors.green;
                          icon = Icons.local_shipping_rounded;
                          break;
                        default:
                          statusColor = SoilColors.clay;
                          icon = Icons.schedule_rounded;
                      }

                      return Container(
                        width: 240,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(Sr.rLg),
                          border: Border.all(color: cs.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(icon, color: statusColor, size: 18),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(Sr.rPill),
                                  ),
                                  child: Text(
                                    status
                                        .toUpperCase()
                                        .replaceAll('_', ' '),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '₱${data['total']}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: SoilColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Text(
                                (data['items'] as List)
                                    .map((e) => '${e['qty']}x ${e['name']}')
                                    .join('\n'),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: cs.onSurface.withOpacity(0.65),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 26),

            Text(
              'Products',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),

            // ── Row 1: Test Kit + Reagent (2-column grid) ────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _GridProductCard(
                    emoji: '🧺',
                    title: '1 Set Test Kit',
                    price: 349,
                    badge: 'Complete Kit',
                    badgeColor: SoilColors.primary,
                    cartQty: _cart
                        .where((c) => c.key == 'test_kit')
                        .fold(0, (a, b) => a + b.qty),
                    onAdd: () => _addCartItem('test_kit', '1 Set Test Kit', 349),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GridProductCard(
                    emoji: '💧',
                    title: '1 Reagent (Any Type)',
                    price: 99,
                    badge: 'Choose Type',
                    badgeColor: SoilColors.harvest,
                    cartQty: _cart
                        .where((c) => c.key.startsWith('reagent_'))
                        .fold(0, (a, b) => a + b.qty),
                    onAdd: _openReagentModal,
                    isChooser: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Row 2: Test Tubes (full-width horizontal card) ────────────────
            _ProductCard(
              emoji: '🔬',
              title: 'Test Tubes & Droplets (1 pc)',
              description:
              'Borosilicate glass test tube + precision dropper. Replacement or extra for your soil tests.',
              price: 29,
              cartQty: _cart
                  .where((c) => c.key == 'tube_dropper')
                  .fold(0, (a, b) => a + b.qty),
              onAdd: () =>
                  _addCartItem('tube_dropper', 'Test Tubes & Droplets', 29),
            ),

            const SizedBox(height: 32),

            // ── Info note ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SoilColors.harvest.withOpacity(0.08),
                borderRadius: BorderRadius.circular(Sr.rMd),
                border: Border.all(color: SoilColors.harvest.withOpacity(0.22)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Products are for physical pick-up or local delivery only. Contact us after ordering to confirm details.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Floating cart bar ────────────────────────────────────────────────
      bottomSheet: _cartCount > 0
          ? _CartBar(count: _cartCount, total: _cartTotal, onTap: _openCart)
          : null,
    );
  }
}

// ── Grid Product Card (compact, for 2-column layout) ─────────────────────────
class _GridProductCard extends StatelessWidget {
  final String emoji, title;
  final int price, cartQty;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onAdd;
  final bool isChooser;

  const _GridProductCard({
    required this.emoji,
    required this.title,
    required this.price,
    required this.cartQty,
    required this.onAdd,
    this.badge,
    this.badgeColor,
    this.isChooser = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = badgeColor ?? SoilColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Sr.rLg),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: emoji + badge ───────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(Sr.rMd),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(Sr.rPill),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Title ────────────────────────────────────────────────────────
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: -0.2,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          // ── Price ────────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱$price',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: SoilColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              if (cartQty > 0) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '×$cartQty in cart',
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface.withOpacity(0.38),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // ── Add Button ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isChooser
                        ? Icons.tune_rounded
                        : Icons.add_shopping_cart_rounded,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(isChooser ? 'Choose' : 'Add'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final String emoji, title, description;
  final int price, cartQty;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onAdd;
  final bool isChooser;

  const _ProductCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.price,
    required this.cartQty,
    required this.onAdd,
    this.badge,
    this.badgeColor,
    this.isChooser = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Sr.rLg),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: SoilColors.primaryLight.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(Sr.rMd),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor!.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(Sr.rPill),
                          border: Border.all(
                              color: badgeColor!.withOpacity(0.25)),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱$price',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: SoilColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (cartQty > 0)
                    Text(
                      'In cart: $cartQty',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurface.withOpacity(0.38),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onSurface.withOpacity(0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAdd,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isChooser
                        ? Icons.tune_rounded
                        : Icons.add_shopping_cart_rounded,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(isChooser ? 'Choose Reagent' : 'Add to Cart'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reagent Modal ─────────────────────────────────────────────────────────────
class _ReagentModal extends StatelessWidget {
  final void Function(_Reagent) onSelect;
  const _ReagentModal({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? SoilColors.surfaceDark : SoilColors.surfaceLight,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(Sr.rXl)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(Sr.rPill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Reagent',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '₱99 per reagent — tap to add to cart',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: cs.onSurface.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...List.generate(_reagents.length, (i) {
            final r = _reagents[i];
            return Column(
              children: [
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: cs.outline.withOpacity(0.5),
                  ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: SoilColors.primaryLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                    Center(child: Text(r.icon, style: const TextStyle(fontSize: 20))),
                  ),
                  title: Text(
                    r.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  subtitle: Text(
                    r.subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cs.onSurface.withOpacity(0.45),
                    ),
                  ),
                  trailing: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SoilColors.primaryLight,
                      borderRadius: BorderRadius.circular(Sr.rPill),
                    ),
                    child: const Text(
                      '+ Add',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: SoilColors.primary,
                      ),
                    ),
                  ),
                  onTap: () => onSelect(r),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                ),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Cart Bar ──────────────────────────────────────────────────────────────────
class _CartBar extends StatelessWidget {
  final int count, total;
  final VoidCallback onTap;
  const _CartBar({required this.count, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bot),
        decoration: BoxDecoration(
          color: SoilColors.primary,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(Sr.rXl)),
          boxShadow: [
            BoxShadow(
              color: SoilColors.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(Sr.rPill),
              ),
              child: Text(
                '$count item${count > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'View Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Text(
              '₱$total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Cart Sheet ────────────────────────────────────────────────────────────────
class _CartSheet extends StatelessWidget {
  final List<_CartItem> cart;
  final int total;
  final void Function(_CartItem) onRemove;

  const _CartSheet({
    required this.cart,
    required this.total,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bot = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? SoilColors.surfaceDark : SoilColors.surfaceLight,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(Sr.rXl)),
      ),
      padding: EdgeInsets.only(bottom: bot + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(Sr.rPill),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Cart',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
          if (cart.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Cart is empty',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.35),
                  fontSize: 14,
                ),
              ),
            )
          else ...[
            ...cart.map((item) => ListTile(
              title: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '₱${item.price} × ${item.qty}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.45),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₱${item.price * item.qty}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: SoilColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onRemove(item),
                    child: Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 20,
                      color: cs.onSurface.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            )),
            Divider(height: 1, indent: 20, endIndent: 20, color: cs.outline),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    '₱$total',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: SoilColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      Fluttertoast.showToast(
                        msg: 'Processing order...',
                        gravity: ToastGravity.CENTER,
                        toastLength: Toast.LENGTH_SHORT,
                      );

                      await OrderService.instance.placeOrder(
                        items: cart
                            .map((e) => {
                          'name': e.label,
                          'price': e.price,
                          'qty': e.qty,
                        })
                            .toList(),
                        total: total,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);

                        Fluttertoast.showToast(
                          msg: 'Order placed successfully',
                          gravity: ToastGravity.CENTER,
                        );
                      }

                      cart.clear();
                    } catch (e) {
                      Fluttertoast.showToast(
                        msg: e.toString(),
                        gravity: ToastGravity.CENTER,
                      );
                    }
                  },
                  child: const Text('Place Order'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}