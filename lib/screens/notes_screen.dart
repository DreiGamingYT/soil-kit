import 'package:flutter/material.dart';
import '../models/soil_data_service.dart';
import '../widgets/bottom_nav.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _svc = SoilDataService.instance;

  void _openSheet({int? idx}) {
    final tc = TextEditingController(text: idx != null ? _svc.notes[idx]['title'] : '');
    final bc = TextEditingController(text: idx != null ? _svc.notes[idx]['body'] : '');
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: cs.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2)))),
          Text(idx != null ? 'Edit note' : 'New note',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  letterSpacing: -0.5, color: cs.onSurface)),
          const SizedBox(height: 20),
          TextField(controller: tc,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
              decoration: const InputDecoration(hintText: 'Title')),
          const SizedBox(height: 12),
          TextField(controller: bc, maxLines: 4,
              style: TextStyle(fontSize: 14, color: cs.onSurface),
              decoration: const InputDecoration(hintText: 'Write your note...',
                  alignLabelWithHint: true)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
                onPressed: () {
                  if (tc.text.trim().isNotEmpty) {
                    final now = DateTime.now();
                    final ms = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                    final note = {'title': tc.text.trim(), 'body': bc.text.trim(),
                      'date': '${ms[now.month-1]} ${now.day}, ${now.year}'};
                    setState(() { idx != null ? _svc.updateNote(idx, note) : _svc.addNote(note); });
                  }
                  Navigator.pop(context);
                }, child: const Text('Save'))),
          ]),
        ]),
      ),
    );
  }

  void _delete(int i) => showDialog(context: context, builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Delete note', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    content: const Text('This note will be permanently deleted.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
          onPressed: () { setState(() => _svc.removeNote(i)); Navigator.pop(context); },
          child: const Text('Delete')),
    ],
  ));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final notes = _svc.notes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _openSheet(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFF2C5F2E),
                    borderRadius: BorderRadius.circular(100)),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Add', style: TextStyle(color: Colors.white,
                      fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: notes.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72,
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, shape: BoxShape.circle),
            child: Icon(Icons.edit_note_rounded, size: 32, color: cs.onSurface.withOpacity(0.25))),
        const SizedBox(height: 16),
        Text('No notes yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
            color: cs.onSurface.withOpacity(0.5))),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => _openSheet(), child: const Text('Write your first note')),
      ]))
          : ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: notes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final n = notes[i];
            return Dismissible(
              key: Key('n$i'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async { _delete(i); return false; },
              background: Container(
                decoration: BoxDecoration(color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(20)),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF2C5F2E).withOpacity(0.15))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(n['title']!, style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface))),
                    GestureDetector(onTap: () => _openSheet(idx: i),
                        child: Icon(Icons.edit_outlined, size: 18,
                            color: const Color(0xFF2C5F2E).withOpacity(0.7))),
                    const SizedBox(width: 12),
                    GestureDetector(onTap: () => _delete(i),
                        child: Icon(Icons.delete_outline_rounded, size: 18,
                            color: cs.onSurface.withOpacity(0.3))),
                  ]),
                  if (n['body']!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(n['body']!, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, height: 1.5,
                            color: cs.onSurface.withOpacity(0.55))),
                  ],
                  const SizedBox(height: 8),
                  Text(n['date']!, style: TextStyle(fontSize: 11,
                      color: cs.onSurface.withOpacity(0.3))),
                ]),
              ),
            );
          }),
      bottomNavigationBar: AppBottomNav(selectedIndex: 0, onTap: (_) => Navigator.pop(context)),
    );
  }
}