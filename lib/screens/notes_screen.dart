import 'package:flutter/material.dart';
import '../services/soil_data_service.dart';
import '../main.dart';
import '../widgets/bottom_nav.dart';

class NotesScreen extends StatefulWidget {
  /// Set to false when embedded inside HomeScreen so the parent nav is used.
  final bool showBottomNav;
  const NotesScreen({super.key, this.showBottomNav = true});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _svc = SoilDataService.instance;

  void _openSheet({int? idx}) {
    final tc = TextEditingController(
        text: idx != null ? _svc.notes[idx]['title'] : '');
    final bc = TextEditingController(
        text: idx != null ? _svc.notes[idx]['body'] : '');
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  color: cs.outline.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              Text(
                idx != null ? 'Edit Note' : 'New Note',
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  letterSpacing: -0.5, color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: tc,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                decoration: const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bc,
                maxLines: 4,
                style: TextStyle(fontSize: 14, color: cs.onSurface),
                decoration: const InputDecoration(
                  hintText: 'Write your note…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    if (tc.text.trim().isNotEmpty) {
                      final now = DateTime.now();
                      const ms = ['Jan','Feb','Mar','Apr','May','Jun',
                        'Jul','Aug','Sep','Oct','Nov','Dec'];
                      final note = {
                        'title': tc.text.trim(),
                        'body': bc.text.trim(),
                        'date': '${ms[now.month - 1]} ${now.day}, ${now.year}',
                      };
                      setState(() => idx != null
                          ? _svc.updateNote(idx, note)
                          : _svc.addNote(note));
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                )),
              ]),
            ]),
      ),
    );
  }

  void _delete(int i) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sr.rXl)),
      title: const Text('Delete Note',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: const Text('This note will be permanently deleted.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: SoilColors.low),
          onPressed: () {
            setState(() => _svc.removeNote(i));
            Navigator.pop(context);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );

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
                  color: SoilColors.primary,
                  borderRadius: BorderRadius.circular(Sr.rPill),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Add', style: TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
                  )),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: notes.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            color: SoilColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.edit_note_rounded,
              size: 34, color: SoilColors.primary.withOpacity(0.6)),
        ),
        const SizedBox(height: 18),
        Text('No notes yet', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: cs.onSurface.withOpacity(0.5),
        )),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _openSheet(),
          child: const Text('Write your first note'),
        ),
      ]))
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        itemCount: notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final n = notes[i];
          return Dismissible(
            key: Key('n$i'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              _delete(i);
              return false;
            },
            background: Container(
              decoration: BoxDecoration(
                color: SoilColors.low,
                borderRadius: BorderRadius.circular(Sr.rLg),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 22),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(Sr.rLg),
                border: Border.all(color: cs.outline),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(right: 10, top: 1),
                    decoration: const BoxDecoration(
                      color: SoilColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(child: Text(n['title']!, style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ))),
                  GestureDetector(
                    onTap: () => _openSheet(idx: i),
                    child: const Icon(Icons.edit_outlined, size: 17,
                        color: SoilColors.primary),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _delete(i),
                    child: Icon(Icons.delete_outline_rounded, size: 17,
                        color: cs.onSurface.withOpacity(0.28)),
                  ),
                ]),
                if (n['body']!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(n['body']!,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, height: 1.55,
                        color: cs.onSurface.withOpacity(0.5)),
                  ),
                ],
                const SizedBox(height: 10),
                Text(n['date']!, style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withOpacity(0.32),
                )),
              ]),
            ),
          );
        },
      ),
      // Only show when not embedded in HomeScreen
      bottomNavigationBar: widget.showBottomNav
          ? AppBottomNav(
        selectedIndex: 4,
        onTap: (_) => Navigator.pop(context),
      )
          : null,
    );
  }
}