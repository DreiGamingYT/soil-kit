import 'package:flutter/material.dart';
import '../models/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _s = SettingsService.instance;

  void _requestNotif(bool on) async {
    if (!on) { setState(() => _s.notificationsEnabled.value = false); return; }
    if (_s.notificationPermissionGranted.value) {
      setState(() => _s.notificationsEnabled.value = true); return;
    }
    final ok = await showDialog<bool>(context: context, builder: (_) => _PermDialog());
    if (ok == true) {
      setState(() { _s.notificationPermissionGranted.value = true;
      _s.notificationsEnabled.value = true; });
    } else {
      setState(() => _s.notificationsEnabled.value = false);
    }
  }

  void _clearHistory() => showDialog(context: context, builder: (_) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text(_s.tr('clear_history'), style: const TextStyle(fontWeight: FontWeight.w700)),
    content: const Text('All saved soil test results will be permanently deleted.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(_s.tr('cancel'))),
      ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
          onPressed: () { Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('History cleared'),
              backgroundColor: Color(0xFF2C5F2E))); },
          child: Text(_s.tr('delete'))),
    ],
  ));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: ValueListenableBuilder<String>(
          valueListenable: _s.language,
          builder: (_, __, ___) => Text(_s.tr('settings')))),
      body: ValueListenableBuilder<String>(
        valueListenable: _s.language,
        builder: (_, __, ___) => ValueListenableBuilder<ThemeMode>(
          valueListenable: _s.themeMode,
          builder: (_, mode, __) => ValueListenableBuilder<String>(
            valueListenable: _s.measurementUnit,
            builder: (_, unit, __) => ValueListenableBuilder<bool>(
              valueListenable: _s.notificationsEnabled,
              builder: (_, notif, __) => ValueListenableBuilder<bool>(
                valueListenable: _s.autoAnalyze,
                builder: (_, auto, __) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    _SHeader('Appearance', cs),
                    _SettingsGroup(cs: cs, items: [
                      _ToggleItem(icon: Icons.dark_mode_outlined,
                          label: _s.tr('dark_mode'), sub: _s.tr('dark_mode_sub'),
                          value: mode == ThemeMode.dark,
                          onChanged: (v) { _s.toggleDarkMode(v);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(v ? 'Dark mode on' : 'Light mode on'),
                              backgroundColor: const Color(0xFF2C5F2E),
                              duration: const Duration(seconds: 1))); }),
                      _DropItem(icon: Icons.straighten_outlined,
                          label: _s.tr('measurement_unit'), value: unit,
                          options: SettingsService.availableUnits,
                          onChanged: (v) { if (v != null) setState(() => _s.measurementUnit.value = v); }),
                      _DropItem(icon: Icons.language_outlined,
                          label: _s.tr('language'), value: _s.language.value,
                          options: const ['English','Filipino','Spanish','Mandarin'],
                          onChanged: (v) { if (v != null) setState(() => _s.language.value = v); }),
                    ]),
                    const SizedBox(height: 20),

                    _SHeader('Camera', cs),
                    _SettingsGroup(cs: cs, items: [
                      _ToggleItem(icon: Icons.auto_fix_high_outlined,
                          label: _s.tr('auto_analyze'), sub: _s.tr('auto_analyze_sub'),
                          value: auto,
                          onChanged: (v) => setState(() => _s.autoAnalyze.value = v)),
                    ]),
                    const SizedBox(height: 20),

                    _SHeader('Notifications', cs),
                    _SettingsGroup(cs: cs, items: [
                      _ToggleItem(icon: Icons.notifications_outlined,
                          label: _s.tr('enable_notifications'),
                          sub: notif ? 'Active' : 'Off',
                          value: notif, onChanged: _requestNotif),
                    ]),
                    const SizedBox(height: 20),

                    _SHeader('Data & Privacy', cs),
                    _SettingsGroup(cs: cs, items: [
                      _ActionItem(icon: Icons.delete_outline_rounded,
                          label: _s.tr('clear_history'),
                          sub: _s.tr('clear_history_sub'),
                          color: const Color(0xFFEF4444), onTap: _clearHistory),
                      _ActionItem(icon: Icons.download_outlined,
                          label: _s.tr('export_data'), sub: _s.tr('export_data_sub'),
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exported to Downloads/')))),
                    ]),
                    const SizedBox(height: 20),

                    _SHeader('About', cs),
                    _SettingsGroup(cs: cs, items: [
                      _InfoItem(icon: Icons.apps_rounded, label: 'App Version', value: '1.0.0'),
                      _InfoItem(icon: Icons.build_outlined, label: 'Build', value: '2026.03'),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section helpers ───────────────────────────────────────────────────────────
Widget _SHeader(String title, ColorScheme cs) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            letterSpacing: 1.0, color: cs.onSurface.withOpacity(0.4))));

class _SettingsGroup extends StatelessWidget {
  final ColorScheme cs; final List<Widget> items;
  const _SettingsGroup({required this.cs, required this.items});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.3))),
    child: Column(children: items.asMap().entries.map((e) {
      final last = e.key == items.length - 1;
      return Column(children: [
        e.value,
        if (!last) Divider(height: 1, color: cs.outline.withOpacity(0.2), indent: 52, endIndent: 16),
      ]);
    }).toList()),
  );
}

class _ToggleItem extends StatelessWidget {
  final IconData icon; final String label; final String? sub;
  final bool value; final ValueChanged<bool> onChanged;
  const _ToggleItem({required this.icon, required this.label,
    this.sub, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: cs.onSurface.withOpacity(0.6))),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: sub != null ? Text(sub!, style: TextStyle(
          fontSize: 12, color: cs.onSurface.withOpacity(0.4))) : null,
      trailing: Switch(value: value, onChanged: onChanged,
          activeColor: const Color(0xFF2C5F2E)),
    );
  }
}

class _DropItem extends StatelessWidget {
  final IconData icon; final String label, value; final List<String> options;
  final ValueChanged<String?> onChanged;
  const _DropItem({required this.icon, required this.label, required this.value,
    required this.options, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: cs.onSurface.withOpacity(0.6))),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: DropdownButton<String>(
          value: value, underline: const SizedBox(),
          style: const TextStyle(color: Color(0xFF2C5F2E),
              fontWeight: FontWeight.w600, fontSize: 13),
          items: options.map((o) => DropdownMenuItem(value: o,
              child: Text(o, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon; final String label; final String? sub;
  final Color? color; final VoidCallback onTap;
  const _ActionItem({required this.icon, required this.label,
    this.sub, this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurface;
    return ListTile(
      leading: Container(width: 36, height: 36,
          decoration: BoxDecoration(
              color: color != null ? color!.withOpacity(0.1) : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color ?? cs.onSurface.withOpacity(0.6))),
      title: Text(label, style: TextStyle(fontSize: 14,
          fontWeight: FontWeight.w500, color: c)),
      subtitle: sub != null ? Text(sub!, style: TextStyle(
          fontSize: 12, color: cs.onSurface.withOpacity(0.4))) : null,
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 13,
          color: cs.onSurface.withOpacity(0.25)),
      onTap: onTap,
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoItem({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: cs.onSurface.withOpacity(0.6))),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Text(value, style: TextStyle(
          fontSize: 13, color: cs.onSurface.withOpacity(0.4))),
    );
  }
}

class _PermDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 56, height: 56,
              decoration: BoxDecoration(
                  color: const Color(0xFF2C5F2E).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_outlined,
                  size: 28, color: Color(0xFF2C5F2E))),
          const SizedBox(height: 16),
          Text('"SoilMate" Would Like to\nSend Notifications',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: cs.onSurface, height: 1.3)),
          const SizedBox(height: 8),
          Text('Receive soil test reminders and weekly field alerts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13,
                  color: cs.onSurface.withOpacity(0.5), height: 1.5)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Don't Allow"))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Allow'))),
          ]),
        ]),
      ),
    );
  }
}