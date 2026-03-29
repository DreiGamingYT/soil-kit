import 'package:flutter/material.dart';
import '../models/soil_data_service.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _svc = SoilDataService.instance;
  String _name = 'Username', _email = 'user@email.com', _location = 'Lunita Park';

  void _edit() {
    final nc = TextEditingController(text: _name);
    final ec = TextEditingController(text: _email);
    final lc = TextEditingController(text: _location);
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: cs.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2)))),
          Text('Edit Profile', style: TextStyle(fontSize: 20,
              fontWeight: FontWeight.w800, letterSpacing: -0.5, color: cs.onSurface)),
          const SizedBox(height: 20),
          TextField(controller: nc, decoration: const InputDecoration(
              hintText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded))),
          const SizedBox(height: 12),
          TextField(controller: ec, decoration: const InputDecoration(
              hintText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 12),
          TextField(controller: lc, decoration: const InputDecoration(
              hintText: 'Location', prefixIcon: Icon(Icons.location_on_outlined))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (nc.text.trim().isNotEmpty) _name = nc.text.trim();
                    if (ec.text.trim().isNotEmpty) _email = ec.text.trim();
                    if (lc.text.trim().isNotEmpty) _location = lc.text.trim();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Profile updated'),
                      backgroundColor: Color(0xFF2C5F2E)));
                }, child: const Text('Save'))),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(children: [
          // Avatar row
          Row(children: [
            Stack(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2C5F2E).withOpacity(0.1),
                    border: Border.all(
                        color: const Color(0xFF2C5F2E).withOpacity(0.25), width: 2)),
                child: const Icon(Icons.person_rounded, size: 38, color: Color(0xFF2C5F2E)),
              ),
              Positioned(bottom: 0, right: 0,
                  child: GestureDetector(onTap: _edit,
                      child: Container(width: 26, height: 26,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0xFF2C5F2E)),
                          child: const Icon(Icons.edit_rounded, size: 13, color: Colors.white)))),
            ]),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  letterSpacing: -0.5, color: cs.onSurface)),
              const SizedBox(height: 3),
              Text(_email, style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.45))),
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 12, color: cs.onSurface.withOpacity(0.35)),
                const SizedBox(width: 3),
                Text(_location, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.35))),
              ]),
            ])),
          ]),
          const SizedBox(height: 24),

          // Stats row
          Row(children: [
            _Stat(value: '${_svc.resultsCount}', label: 'Analyses', cs: cs),
            const SizedBox(width: 10),
            _Stat(value: '${_svc.notesCount}', label: 'Notes', cs: cs),
            const SizedBox(width: 10),
            _Stat(value: '1', label: 'Fields', cs: cs),
          ]),
          const SizedBox(height: 24),

          // Menu items
          _MenuGroup(cs: cs, items: [
            _MenuItem(icon: Icons.edit_outlined, label: 'Edit Profile', onTap: _edit),
            _MenuItem(icon: Icons.tune_rounded, label: 'Settings',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications',
                subtitle: 'Manage in Settings',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          ]),
          const SizedBox(height: 10),
          _MenuGroup(cs: cs, items: [
            _MenuItem(icon: Icons.info_outline_rounded, label: 'About SoilMate',
                subtitle: 'Version 1.0.0',
                onTap: () => _showAbout(context)),
          ]),
        ]),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(context: context, builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      backgroundColor: cs.surface,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 0), child: Column(children: [
          Container(width: 60, height: 60,
              decoration: BoxDecoration(
                  color: const Color(0xFF2C5F2E).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.eco_rounded, size: 32, color: Color(0xFF2C5F2E))),
          const SizedBox(height: 12),
          Text('SoilMate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
              color: cs.onSurface)),
          Text('Version 1.0.0', style: TextStyle(fontSize: 12,
              color: cs.onSurface.withOpacity(0.4))),
          const SizedBox(height: 16),
          Divider(color: cs.outline.withOpacity(0.3)),
        ])),
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 12),
            Text('GTECH SOLUTION COMPANY', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.5, color: cs.onSurface.withOpacity(0.4))),
            const SizedBox(height: 12),
            ...[['CEO','Bolatin, Jane Alexa'],['Technical Lead','Velasco, Jonathan'],
              ['UI/UX Designer','Suagen, Allysa Jasmin'],['Developer','De Guzman, Maenalyn'],
              ['QA','Delos Reyes']].map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                SizedBox(width: 120, child: Text(r[0], style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withOpacity(0.4)))),
                Expanded(child: Text(r[1], style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface))),
              ]),
            )),
            const SizedBox(height: 16),
          ]),
        )),
        Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: SizedBox(width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => Navigator.pop(context), child: const Text('Close')))),
      ]),
    ));
  }
}

class _Stat extends StatelessWidget {
  final String value, label; final ColorScheme cs;
  const _Stat({required this.value, required this.label, required this.cs});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.3))),
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
          color: Color(0xFF2C5F2E))),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.4))),
    ]),
  ));
}

class _MenuGroup extends StatelessWidget {
  final ColorScheme cs; final List<_MenuItem> items;
  const _MenuGroup({required this.cs, required this.items});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.3))),
    child: Column(children: items.asMap().entries.map((e) {
      final last = e.key == items.length - 1;
      return Column(children: [
        e.value,
        if (!last) Divider(height: 1, color: cs.outline.withOpacity(0.2),
            indent: 52, endIndent: 16),
      ]);
    }).toList()),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon; final String label; final String? subtitle;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label,
    this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: cs.onSurface.withOpacity(0.6))),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
          color: cs.onSurface)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(
          fontSize: 12, color: cs.onSurface.withOpacity(0.4))) : null,
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 13,
          color: cs.onSurface.withOpacity(0.25)),
      onTap: onTap,
    );
  }
}