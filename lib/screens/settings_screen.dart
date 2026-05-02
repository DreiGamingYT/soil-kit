import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/soil_data_service.dart';
import '../main.dart';
import 'calibration_screen.dart';
import 'device_check_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _s = SettingsService.instance;

  void _requestNotif(bool on) async {
    if (!on) {
      setState(() => _s.notificationsEnabled.value = false);
      return;
    }
    if (_s.notificationPermissionGranted.value) {
      setState(() => _s.notificationsEnabled.value = true);
      return;
    }
    final ok = await showDialog<bool>(context: context, builder: (_) => _PermDialog());
    if (ok == true) {
      setState(() {
        _s.notificationPermissionGranted.value = true;
        _s.notificationsEnabled.value = true;
      });
    } else {
      setState(() => _s.notificationsEnabled.value = false);
    }
  }

  void _clearHistory() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sr.rXl)),
      title: Text(_s.tr('clear_history'),
          style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text(
        'All saved soil test results will be permanently deleted.',
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_s.tr('cancel')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: SoilColors.low),
          onPressed: () {
            Navigator.pop(context);
            SoilDataService.instance.results.clear();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('History cleared'),
              backgroundColor: SoilColors.primary,
            ));
          },
          child: Text(_s.tr('delete')),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<String>(
          valueListenable: _s.language,
          builder: (_, __, ___) => Text(_s.tr('settings')),
        ),
      ),
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
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 44),
                  children: [

                    // ── Appearance ─────────────────────────────────
                    _SHeader('Appearance', cs),
                    _Group(cs: cs, items: [
                      _ToggleRow(
                        icon: Icons.dark_mode_outlined,
                        label: _s.tr('dark_mode'),
                        sub: _s.tr('dark_mode_sub'),
                        value: mode == ThemeMode.dark,
                        onChanged: (v) {
                          _s.toggleDarkMode(v);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(v ? 'Dark mode on' : 'Light mode on'),
                            backgroundColor: SoilColors.primary,
                            duration: const Duration(seconds: 1),
                          ));
                        },
                      ),
                      _DropRow(
                        icon: Icons.straighten_outlined,
                        label: _s.tr('measurement_unit'),
                        value: unit,
                        options: SettingsService.availableUnits,
                        onChanged: (v) {
                          if (v != null) setState(() => _s.measurementUnit.value = v);
                        },
                      ),
                      _DropRow(
                        icon: Icons.language_outlined,
                        label: _s.tr('language'),
                        value: _s.language.value,
                        options: const ['English', 'Filipino', 'Spanish', 'Mandarin'],
                        onChanged: (v) {
                          if (v != null) setState(() => _s.language.value = v);
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── Camera ─────────────────────────────────────
                    _SHeader('Camera', cs),
                    _Group(cs: cs, items: [
                      _ToggleRow(
                        icon: Icons.auto_fix_high_outlined,
                        label: _s.tr('auto_analyze'),
                        sub: _s.tr('auto_analyze_sub'),
                        value: auto,
                        onChanged: (v) => setState(() => _s.autoAnalyze.value = v),
                      ),
                      _ActionRow(
                        icon: Icons.phone_android_outlined,
                        label: 'Device Compatibility Check',
                        sub: 'Check if your phone camera is ready for scanning',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const DeviceCheckScreen())),
                      ),
                      _ActionRow(
                        icon: Icons.tune_outlined,
                        label: 'White Reference & Calibration',
                        sub: 'Re-calibrate for current lighting conditions',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => CalibrationScreen())),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── Notifications ──────────────────────────────
                    _SHeader('Notifications', cs),
                    _Group(cs: cs, items: [
                      _ToggleRow(
                        icon: Icons.notifications_outlined,
                        label: _s.tr('enable_notifications'),
                        sub: notif ? 'Active' : 'Off',
                        value: notif,
                        onChanged: _requestNotif,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── Data & Privacy ─────────────────────────────
                    _SHeader('Data & Privacy', cs),
                    _Group(cs: cs, items: [
                      _ActionRow(
                        icon: Icons.delete_outline_rounded,
                        label: _s.tr('clear_history'),
                        sub: _s.tr('clear_history_sub'),
                        color: SoilColors.low,
                        onTap: _clearHistory,
                      ),
                      _ActionRow(
                        icon: Icons.download_outlined,
                        label: _s.tr('export_data'),
                        sub: _s.tr('export_data_sub'),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Exported to Downloads/')),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── About ──────────────────────────────────────
                    _SHeader('About', cs),
                    _Group(cs: cs, items: [
                      _InfoRow(
                        icon: Icons.apps_rounded,
                        label: 'App Version',
                        value: '1.0.0',
                      ),
                      _InfoRow(
                        icon: Icons.build_outlined,
                        label: 'Build',
                        value: '2026.03',
                      ),
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

// ── Section header ────────────────────────────────────────────────────────────
Widget _SHeader(String title, ColorScheme cs) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Row(children: [
    Container(
      width: 3, height: 14,
      decoration: BoxDecoration(
        color: SoilColors.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
    const SizedBox(width: 8),
    Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: cs.onSurface.withOpacity(0.4),
      ),
    ),
  ]),
);

// ── Group container ───────────────────────────────────────────────────────────
class _Group extends StatelessWidget {
  final ColorScheme cs;
  final List<Widget> items;
  const _Group({required this.cs, required this.items});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(Sr.rLg),
      border: Border.all(color: cs.outline),
    ),
    child: Column(
      children: items.asMap().entries.map((e) {
        final last = e.key == items.length - 1;
        return Column(children: [
          e.value,
          if (!last) Divider(
            height: 1,
            color: cs.outline.withOpacity(0.7),
            indent: 52,
            endIndent: 16,
          ),
        ]);
      }).toList(),
    ),
  );
}

// ── Icon container ────────────────────────────────────────────────────────────
Widget _iconBox(IconData icon, ColorScheme cs, {Color? color}) => Container(
  width: 36, height: 36,
  decoration: BoxDecoration(
    color: color != null
        ? color.withOpacity(0.10)
        : SoilColors.primaryLight.withOpacity(0.6),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Icon(icon, size: 17,
      color: color ?? SoilColors.primary.withOpacity(0.75)),
);

// ── Toggle row ────────────────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,
    required this.label,
    this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(icon, cs),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: sub != null
          ? Text(sub!,
          style: TextStyle(
              fontSize: 12, color: cs.onSurface.withOpacity(0.4)))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: SoilColors.primary,
      ),
    );
  }
}

// ── Dropdown row ──────────────────────────────────────────────────────────────
class _DropRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  const _DropRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(icon, cs),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        style: const TextStyle(
          color: SoilColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        items: options.map((o) => DropdownMenuItem(
          value: o,
          child: Text(o, overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final Color? color;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.label,
    this.sub,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurface;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(icon, cs, color: color),
      title: Text(label,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: c)),
      subtitle: sub != null
          ? Text(sub!,
          style: TextStyle(
              fontSize: 12, color: cs.onSurface.withOpacity(0.4)))
          : null,
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 13, color: cs.onSurface.withOpacity(0.22)),
      onTap: onTap,
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(icon, cs),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Text(
        value,
        style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.4)),
      ),
    );
  }
}

// ── Permission dialog ─────────────────────────────────────────────────────────
class _PermDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sr.rXl)),
      backgroundColor: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: SoilColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_outlined,
                size: 28, color: SoilColors.primary),
          ),
          const SizedBox(height: 18),
          Text(
            '"SoilMate" Would Like to\nSend Notifications',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Receive soil test reminders and weekly field alerts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withOpacity(0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Don't Allow"),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Allow'),
            )),
          ]),
        ]),
      ),
    );
  }
}