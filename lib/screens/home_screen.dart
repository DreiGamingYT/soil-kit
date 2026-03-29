import 'package:flutter/material.dart';
import '../models/settings_service.dart';
import '../widgets/bottom_nav.dart';
import 'color_chart_screen.dart';
import 'history_screen.dart';
import 'notes_screen.dart';
import 'soil_list_screen.dart';
import 'profile_screen.dart';
import 'faq_screen.dart';
import 'help_guide_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavTap;
  const HomeScreen({super.key, required this.selectedIndex, required this.onNavTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SettingsService.instance.language,
      builder: (_, __, ___) => Scaffold(
        body: selectedIndex == 2 ? const ProfileScreen() : const _HomeBody(),
        bottomNavigationBar: AppBottomNav(selectedIndex: selectedIndex, onTap: onNavTap),
      ),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();
  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  List<Map<String, dynamic>> _items(SettingsService s) => [
    {'label': s.tr('color_chart'), 'icon': Icons.palette_outlined,  'screen': 'color_chart'},
    {'label': s.tr('history'),     'icon': Icons.history_rounded,    'screen': 'history'},
    {'label': s.tr('soil_list'),   'icon': Icons.terrain_outlined,   'screen': 'soil_list'},
    {'label': s.tr('notes'),       'icon': Icons.edit_note_rounded,  'screen': 'notes'},
    {'label': s.tr('faq'),         'icon': Icons.help_outline_rounded,'screen': 'faq'},
    {'label': s.tr('help_guide'),  'icon': Icons.menu_book_outlined, 'screen': 'help'},
    {'label': s.tr('settings'),    'icon': Icons.tune_rounded,       'screen': 'settings'},
  ];

  void _go(BuildContext ctx, String screen) {
    Widget? d;
    switch (screen) {
      case 'color_chart': d = const ColorChartScreen(); break;
      case 'history':     d = const HistoryScreen(); break;
      case 'soil_list':   d = const SoilListScreen(); break;
      case 'notes':       d = const NotesScreen(); break;
      case 'faq':         d = const FaqScreen(); break;
      case 'help':        d = const HelpGuideScreen(); break;
      case 'settings':    d = const SettingsScreen(); break;
    }
    if (d != null) {
      setState(() { _query = ''; _searchCtrl.clear(); });
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => d!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsService.instance;
    final cs = Theme.of(context).colorScheme;
    final top = MediaQuery.of(context).padding.top;

    return ValueListenableBuilder<String>(
      valueListenable: s.language,
      builder: (_, __, ___) {
        final items = _items(s);
        final results = _query.isEmpty ? <Map<String, dynamic>>[] :
        items.where((i) => i['label'].toString().toLowerCase()
            .contains(_query.toLowerCase())).toList();

        return CustomScrollView(slivers: [
          // ── Header ──────────────────────────────────────────────────
          SliverToBoxAdapter(child: Container(
            padding: EdgeInsets.fromLTRB(24, top + 20, 24, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.tr('hello'),
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.45),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(s.tr('username'),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                          letterSpacing: -0.8, color: cs.onSurface)),
                ])),
                // Notification button
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: cs.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.outline.withOpacity(0.4))),
                    child: Icon(Icons.notifications_none_rounded,
                        color: cs.onSurface.withOpacity(0.6), size: 22),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              // Search bar
              Container(
                height: 48,
                decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outline.withOpacity(0.4))),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(fontSize: 14, color: cs.onSurface),
                  decoration: InputDecoration(
                      hintText: s.tr('search'),
                      hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.35), fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: cs.onSurface.withOpacity(0.35), size: 20),
                      suffixIcon: _query.isNotEmpty ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: cs.onSurface.withOpacity(0.35), size: 18),
                          onPressed: () => setState(() { _query=''; _searchCtrl.clear(); }))
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ]),
          )),

          // ── Search results ───────────────────────────────────────────
          if (_query.isNotEmpty) SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: results.isEmpty
                ? Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outline.withOpacity(0.3))),
                child: Text(s.tr('no_results'),
                    style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 14)))
                : Column(children: results.map((item) => _SearchResult(
                item: item, onTap: () => _go(context, item['screen']))).toList()),
          )),

          if (_query.isEmpty) ...[
            // ── Quick action strip ───────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _QuickChip(icon: Icons.help_outline_rounded,
                      label: s.tr('faq'),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const FaqScreen()))),
                  const SizedBox(width: 8),
                  _QuickChip(icon: Icons.menu_book_outlined,
                      label: s.tr('help_guide'),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HelpGuideScreen()))),
                  const SizedBox(width: 8),
                  _QuickChip(icon: Icons.tune_rounded,
                      label: s.tr('settings'),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                ]),
              ),
            )),

            // ── Section label ────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: Text('Features',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      letterSpacing: 0.6, color: cs.onSurface.withOpacity(0.4))),
            )),

            // ── Feature grid ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  _FeatureCard(emoji: '🎨', label: s.tr('color_chart'),
                      sublabel: 'pH & NPK ranges',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ColorChartScreen()))),
                  _FeatureCard(emoji: '📋', label: s.tr('history'),
                      sublabel: 'Past analyses',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HistoryScreen()))),
                  _FeatureCard(emoji: '🌍', label: s.tr('soil_list'),
                      sublabel: '6 soil types',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SoilListScreen()))),
                  _FeatureCard(emoji: '📝', label: s.tr('notes'),
                      sublabel: 'Field notes',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const NotesScreen()))),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12,
                    mainAxisSpacing: 12, childAspectRatio: 1.4),
              ),
            ),
          ],
        ]);
      },
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SearchResult extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _SearchResult({required this.item, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withOpacity(0.3))),
        child: Row(children: [
          Icon(item['icon'] as IconData, size: 20, color: const Color(0xFF2C5F2E)),
          const SizedBox(width: 12),
          Text(item['label'] as String,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: cs.onSurface.withOpacity(0.3)),
        ]),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _QuickChip({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: cs.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: cs.outline.withOpacity(0.4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: const Color(0xFF2C5F2E)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.75))),
        ]),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji, label, sublabel; final VoidCallback onTap;
  const _FeatureCard({required this.emoji, required this.label,
    required this.sublabel, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const Spacer(),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: cs.onSurface, letterSpacing: -0.2)),
          const SizedBox(height: 2),
          Text(sublabel, style: TextStyle(fontSize: 11,
              color: cs.onSurface.withOpacity(0.4))),
        ]),
      ),
    );
  }
}