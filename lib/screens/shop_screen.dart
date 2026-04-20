import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/order_service.dart';
import '../services/email_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'my_orders_screen.dart';

// ── Reagent data ──────────────────────────────────────────────────────────────
class _Reagent {
  final String name, subtitle, emoji, key;
  final Color color;
  const _Reagent(this.name, this.subtitle, this.emoji, this.key, this.color);
}

/*const _reagents = [
  _Reagent('Nitrogen (N)',     'Measures available nitrogen',      '🟦', 'reagent_n',  Color(0xFF1976D2)),
  _Reagent('Phosphorus (P)',   'Detects phosphate concentration',  '🟧', 'reagent_p',  Color(0xFFF57C00)),
  _Reagent('Potassium (K)',    'Tests potassium (potash) levels',  '🟪', 'reagent_k',  Color(0xFF7B1FA2)),
  _Reagent('pH Indicator',    'Measures soil acidity/alkalinity', '🟩', 'reagent_ph', Color(0xFF388E3C)),
  _Reagent('Ammonium Nitrate','Nitrogen fertilizer supplement',   '🟫', 'reagent_an', Color(0xFF5D4037)),
];*/

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

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _reagentProducts = [];

  int _stockOf(String id) => _products
      .firstWhere((p) => p['id'] == id, orElse: () => {})['stock'] as int? ?? 0;

  @override
  void initState() {
    super.initState();
    _listenStock();
  }

  void _listenStock() {
    FirebaseFirestore.instance
        .collection('products')
        .where('active', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final all = snap.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();
      setState(() {
        // BUG FIX 6: split products into two separate lists by type
        _products        = all.where((p) => p['type'] != 'reagent').toList();
        _reagentProducts = all.where((p) => p['type'] == 'reagent').toList();
      });
    });
  }

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

  void _removeCartItem(String key) {
    setState(() {
      final existing = _cart.where((c) => c.key == key).toList();
      if (existing.isEmpty) return;
      if (existing.first.qty > 1) {
        existing.first.qty--;
      } else {
        _cart.remove(existing.first);
      }
    });
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

  // BUG FIX 4 & 5: renamed 'imagePath' → 'imageUrl', use Image.network inside modal
  void _showProductDetail({
    required String key,
    required String name,
    required String subtitle,
    required String imageUrl,   // FIX 4: was 'imagePath'
    required String emoji,
    required int price,
    required Color accentColor,
    required int stock,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final qty = _cart.where((c) => c.key == key).fold(0, (a, b) => a + b.qty);
          final outOfStock = stock == 0;
          final atMax      = qty >= stock && !outOfStock;
          final cs  = Theme.of(ctx).colorScheme;
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Sr.rXl)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 38, height: 4,
                decoration: BoxDecoration(
                    color: cs.outline, borderRadius: BorderRadius.circular(Sr.rPill)),
              )),
              Container(
                height: 220, width: double.infinity,
                color: accentColor.withOpacity(0.1),
                // FIX 5: use Image.network instead of Image.asset
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Center(child: Text(emoji, style: const TextStyle(fontSize: 72))),
                )
                    : Center(child: Text(emoji, style: const TextStyle(fontSize: 72))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: cs.onSurface, letterSpacing: -0.4)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(
                      fontSize: 13, color: cs.onSurface.withOpacity(0.5), height: 1.4)),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('₱$price', style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800,
                        color: accentColor, letterSpacing: -0.5)),
                    Row(children: [
                      _QtyButton(
                        icon: Icons.remove_rounded,
                        color: accentColor,
                        onTap: qty > 0 ? () { _removeCartItem(key); setS(() {}); } : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text('$qty', style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                      ),
                      _QtyButton(
                        icon: Icons.add_rounded,
                        color: accentColor,
                        filled: true,
                        onTap: outOfStock || atMax ? null : () { _addCartItem(key, name, price); setS(() {}); },
                      ),
                    ]),
                  ]),
                ]),
              ),
            ]),
          );
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
          onOrderPlaced: () => setState(() => _cart.clear()),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.72,
      children: products.map((p) {
        final id       = p['id'] as String;
        final name     = p['name'] as String? ?? '';
        final price    = (p['price'] as num?)?.toInt() ?? 0;
        final stock    = (p['stock'] as num?)?.toInt() ?? 0;
        final imageUrl = p['imageUrl'] as String? ?? '';
        final cartQty  = _cart.where((c) => c.key == id).fold(0, (a, b) => a + b.qty);

        return _ShopItemCard(
          imageUrl: imageUrl,   // FIX 1: was 'imagePath:'
          emoji: '🧪',
          name: name,
          subtitle: p['subtitle'] as String? ?? '',
          price: price,
          accentColor: SoilColors.primary,
          stock: stock,
          cartQty: cartQty,
          onAdd: () => _addCartItem(id, name, price),
          onRemove: () => _removeCartItem(id),
          onTap: () => _showProductDetail(
            key: id, name: name,
            subtitle: p['subtitle'] as String? ?? '',
            imageUrl: imageUrl,  // FIX 4: matches renamed param
            emoji: '🧪', price: price,
            accentColor: SoilColors.primary,
            stock: stock,
          ),
        );
      }).toList(),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Orders',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
                  child: Text(
                    'See All →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SoilColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 150,
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
                    return const Center(child: CircularProgressIndicator());
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
                          style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final data   = docs[index].data();
                      final status = data['status'] ?? 'pending';

                      Color statusColor;
                      IconData icon;
                      switch (status) {
                        case 'confirmed':
                          statusColor = Colors.blue;
                          icon = Icons.verified_rounded;
                          break;
                        case 'preparing':
                          statusColor = Colors.purple;
                          icon = Icons.hourglass_bottom_rounded;
                          break;
                        case 'shipped':
                          statusColor = Colors.orange;
                          icon = Icons.local_shipping_rounded;
                          break;
                        case 'delivered':
                          statusColor = Colors.green;
                          icon = Icons.check_circle_rounded;
                          break;
                        case 'cancelled':
                          statusColor = Colors.red;
                          icon = Icons.cancel_rounded;
                          break;
                        default:
                          statusColor = SoilColors.clay;
                          icon = Icons.schedule_rounded;
                      }

                      return Container(
                        width: 200,
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
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(Sr.rPill),
                                  ),
                                  child: Text(
                                    status.toUpperCase().replaceAll('_', ' '),
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
                                    .map((e) => '${e['qty']}x ${e['label'] ?? e['name'] ?? ''}')
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

            // ── Products ─────────────────────────────────────────────────────
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
            // FIX 6: pass _products (non-reagent items only)
            _buildProductGrid(_products),

            const SizedBox(height: 20),

            // ── Reagents ─────────────────────────────────────────────────────
            Text(
              'Reagents',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₱99 each',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.45)),
            ),
            const SizedBox(height: 12),
            // FIX 6: pass _reagentProducts (reagent items only)
            _buildProductGrid(_reagentProducts),

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

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final Color? color;
  const _QtyButton({required this.icon, this.onTap, this.filled = false, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? SoilColors.primary;
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: filled ? c : Colors.transparent,
          border: Border.all(
              color: disabled ? Colors.grey.shade300 : c, width: 1.5),
          borderRadius: BorderRadius.circular(Sr.rSm),
        ),
        child: Icon(icon, size: 18,
            color: filled ? Colors.white : (disabled ? Colors.grey.shade400 : c)),
      ),
    );
  }
}

// ── Shop Item Card (2-column grid) ────────────────────────────────────────────
class _ShopItemCard extends StatelessWidget {
  final String imageUrl, emoji, name, subtitle;   // FIX 1: imageUrl (not imagePath)
  final int price, cartQty, stock;
  final Color accentColor;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _ShopItemCard({
    required this.imageUrl,        // FIX 1: was 'this.imagePath'
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.accentColor,
    required this.cartQty,
    required this.stock,
    required this.onAdd,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs         = Theme.of(context).colorScheme;
    final outOfStock = stock == 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(Sr.rLg),
          border: Border.all(color: cs.outline),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ───────────────────────────────
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                color: accentColor.withOpacity(outOfStock ? 0.05 : 0.1),
                // FIX 2: use Image.network instead of Image.asset
                child: imageUrl.isNotEmpty
                    ? Opacity(
                  opacity: outOfStock ? 0.4 : 1.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Opacity(
                        opacity: outOfStock ? 0.4 : 1.0,
                        child: Text(emoji, style: const TextStyle(fontSize: 40)),
                      ),
                    ),
                  ),
                )
                    : Center(
                  child: Opacity(
                    opacity: outOfStock ? 0.4 : 1.0,
                    child: Text(emoji, style: const TextStyle(fontSize: 40)),
                  ),
                ),
              ),
            ),
            // ── Info area ────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurface.withOpacity(0.45),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      outOfStock ? 'Out of stock' : 'In stock: $stock',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: outOfStock ? Colors.red : SoilColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₱$price',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: outOfStock
                                    ? cs.onSurface.withOpacity(0.3)
                                    : accentColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (cartQty > 0)
                              Text('×$cartQty in cart',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: cs.onSurface.withOpacity(0.38))),
                          ],
                        ),
                        cartQty == 0
                            ? GestureDetector(
                          onTap: outOfStock ? null : onAdd,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: outOfStock
                                  ? cs.onSurface.withOpacity(0.12)
                                  : accentColor,
                              borderRadius: BorderRadius.circular(Sr.rMd),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: outOfStock
                                  ? cs.onSurface.withOpacity(0.3)
                                  : Colors.white,
                              size: 18,
                            ),
                          ),
                        )
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                          _QtyButton(
                            icon: Icons.remove_rounded,
                            color: accentColor,
                            onTap: onRemove,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Text('$cartQty',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor)),
                          ),
                          _QtyButton(
                            icon: Icons.add_rounded,
                            color: accentColor,
                            filled: true,
                            onTap: cartQty >= stock ? null : onAdd,
                          ),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

// ── TikTok-style Full-Width Product Card ──────────────────────────────────────
class _TikTokProductCard extends StatelessWidget {
  final List<Color> gradientColors;
  final String emoji, title, description;
  final int price, cartQty;
  final String? badge;
  final String? imagePath;    // kept as-is; this is an optional asset path
  final VoidCallback onAdd;

  const _TikTokProductCard({
    required this.gradientColors,
    required this.emoji,
    required this.title,
    required this.description,
    required this.price,
    required this.cartQty,
    required this.onAdd,
    this.badge,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Sr.rLg),
        border: Border.all(color: cs.outline),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image area ──────────────────────────────────────────────
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  // FIX 3: use imagePath (the actual field), not the undefined 'imageUrl'
                  child: imagePath != null && imagePath!.isNotEmpty
                      ? Image.asset(
                    imagePath!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Text(emoji, style: const TextStyle(fontSize: 64)),
                  )
                      : Text(emoji, style: const TextStyle(fontSize: 64)),
                ),
                if (badge != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(Sr.rPill),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (cartQty > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(Sr.rPill),
                      ),
                      child: Text(
                        '×$cartQty in cart',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── Info area ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.5),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱$price',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: SoilColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
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
class _CartSheet extends StatefulWidget {
  final List<_CartItem> cart;
  final int total;
  final void Function(_CartItem) onRemove;
  final VoidCallback onOrderPlaced;

  const _CartSheet({
    required this.cart,
    required this.total,
    required this.onRemove,
    required this.onOrderPlaced,
  });

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  bool _showCheckout = false;
  final _contactCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _contactCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bot    = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? SoilColors.surfaceDark : SoilColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Sr.rXl)),
      ),
      padding: EdgeInsets.only(bottom: bot + 20, left: 0, right: 0),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 38, height: 4,
            decoration: BoxDecoration(
                color: cs.outline, borderRadius: BorderRadius.circular(Sr.rPill)),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _showCheckout ? 'Checkout' : 'Your Cart',
                style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800, letterSpacing: -0.4),
              ),
            ),
          ),

          if (widget.cart.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Cart is empty',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.35),
                      fontSize: 14)),
            )
          else if (!_showCheckout) ...[
            ...widget.cart.map((item) => ListTile(
              title: Text(item.label,
                  style: const TextStyle(fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
              subtitle: Text('₱${item.price} × ${item.qty}',
                  style: TextStyle(fontSize: 12,
                      color: cs.onSurface.withOpacity(0.45))),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('₱${item.price * item.qty}',
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: SoilColors.primary)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => widget.onRemove(item),
                  child: Icon(Icons.remove_circle_outline_rounded,
                      size: 20, color: cs.onSurface.withOpacity(0.35)),
                ),
              ]),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            )),
            Divider(height: 1, indent: 20, endIndent: 20, color: cs.outline),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withOpacity(0.6))),
                  Text('₱${widget.total}',
                      style: const TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: SoilColors.primary, letterSpacing: -0.5)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showCheckout = true),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_forward_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Proceed to Checkout'),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SoilColors.primaryLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(Sr.rMd),
                    ),
                    child: Row(children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 16, color: SoilColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.cart.fold(0, (a, b) => a + b.qty)} item(s)  •  Total: ₱${widget.total}',
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: SoilColors.primary),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Text('Contact Number',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.55))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _contactCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 09171234567',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Delivery Address',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.55))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Street, Barangay, City',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 22),
                        child: Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showCheckout = false),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _placing ? null : () async {
                          if (_contactCtrl.text.trim().isEmpty ||
                              _addressCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please fill in contact and address'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() => _placing = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav       = Navigator.of(context);

                          try {
                            final items = widget.cart.map((c) => {
                              'key':   c.key,
                              'label': c.label,
                              'qty':   c.qty,
                              'price': c.price,
                            }).toList();

                            final orderId =
                            await OrderService.instance.placeOrder(
                              items, widget.total,
                              contact: _contactCtrl.text.trim(),
                              address: _addressCtrl.text.trim(),
                            ).timeout(const Duration(seconds: 15));

                            messenger.showSnackBar(
                              SnackBar(
                                content: const Row(children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text('Order placed successfully!'),
                                ]),
                                backgroundColor: SoilColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(Sr.rSm)),
                              ),
                            );

                            nav.pop();
                            widget.onOrderPlaced();

                            final user = FirebaseAuth.instance.currentUser;
                            final customerEmail = user?.email ?? '';
                            final customerName  = user?.displayName
                                ?? user?.email?.split('@').first
                                ?? 'Customer';

                            await EmailService.notifyAdminNewOrder(
                              orderId:       orderId,
                              customerName:  customerName,
                              customerEmail: customerEmail,
                              contact:       _contactCtrl.text.trim(),
                              address:       _addressCtrl.text.trim(),
                              items:         items,
                              total:         widget.total,
                            );

                            await EmailService.notifyCustomerOrderStatus(
                              orderId:       orderId,
                              customerEmail: customerEmail,
                              customerName:  customerName,
                              status:        'pending',
                              adminNote:     '',
                              items:         items,
                              total:         widget.total,
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text('Order failed: $e'),
                                  backgroundColor: Colors.red),
                            );
                          } finally {
                            if (mounted) setState(() => _placing = false);
                          }
                        },
                        child: _placing
                            ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : const Text('Place Order'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }
}