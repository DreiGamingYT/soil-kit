import 'package:flutter/material.dart';
import '../models/soil_data_service.dart';
import '../widgets/bottom_nav.dart';
import 'camera_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _svc = SoilDataService.instance;
  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  Color _col(double s) {
    if (s >= 70) return const Color(0xFF22C55E);
    if (s >= 45) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  void _delete(int i) => showDialog(context: context, builder: (_) => _ConfirmDialog(
    title: 'Delete result', body: 'This analysis will be permanently removed.',
    onConfirm: () { setState(() => _svc.removeResult(i)); Navigator.pop(context); },
  ));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = _svc.results;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        automaticallyImplyLeading: false,
        actions: [
          if (items.isNotEmpty) Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('${items.length} results',
                style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.4),
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      body: items.isEmpty
          ? _EmptyState(icon: Icons.history_rounded,
          title: 'No analyses yet',
          body: 'Take your first soil photo to start tracking.')
          : ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final r = items[i];
            final col = _col(r.overallScore);
            final date = '${_months[r.date.month-1]} ${r.date.day}, ${r.date.year}';
            return Dismissible(
              key: Key('h$i${r.date}'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async { _delete(i); return false; },
              background: Container(
                decoration: BoxDecoration(color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(20)),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(ctx,
                    MaterialPageRoute(builder: (_) => CameraResultScreen(result: r))),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.outline.withOpacity(0.3))),
                  child: Row(children: [
                    // Score ring
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: col, width: 2.5)),
                      child: Center(child: Text('${r.overallScore.toInt()}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                              color: col))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.soilType, style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w700, color: cs.onSurface)),
                      const SizedBox(height: 4),
                      Text(date, style: TextStyle(fontSize: 12,
                          color: cs.onSurface.withOpacity(0.4))),
                      const SizedBox(height: 8),
                      Row(children: [
                        _NChip('N', r.nitrogenLevel),
                        const SizedBox(width: 5),
                        _NChip('P', r.phosphorusLevel),
                        const SizedBox(width: 5),
                        _NChip('K', r.potassiumLevel),
                      ]),
                    ])),
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: col.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100)),
                        child: Text(r.status.split(' ').first,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: col)),
                      ),
                      const SizedBox(height: 8),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: cs.onSurface.withOpacity(0.25)),
                    ]),
                  ]),
                ),
              ),
            );
          }),
      bottomNavigationBar: AppBottomNav(selectedIndex: 0, onTap: (_) => Navigator.pop(context)),
    );
  }
}

class _NChip extends StatelessWidget {
  final String label, level;
  const _NChip(this.label, this.level);
  Color get _c => level.toLowerCase() == 'high' ? const Color(0xFF22C55E)
      : level.toLowerCase() == 'medium' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: _c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _c.withOpacity(0.3))),
    child: Text('$label · $level',
        style: TextStyle(color: _c, fontSize: 9, fontWeight: FontWeight.w700)),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String title, body;
  const _EmptyState({required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72,
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: cs.onSurface.withOpacity(0.25))),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
            color: cs.onSurface.withOpacity(0.6))),
        const SizedBox(height: 6),
        Text(body, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.35), height: 1.5)),
      ]),
    ));
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title, body; final VoidCallback onConfirm;
  const _ConfirmDialog({required this.title, required this.body, required this.onConfirm});
  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    content: Text(body, style: TextStyle(
        fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
          child: const Text('Delete')),
    ],
  );
}