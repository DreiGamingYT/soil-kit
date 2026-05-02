import 'package:flutter/material.dart';
import '../services/device_check_service.dart';
import 'calibration_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DeviceCheckScreen
//
//  Entry point: push this screen from Settings or show it on first launch.
//
//  Shows:
//    • Overall verdict banner (Pass / Needs Attention / Issues Found)
//    • Per-check rows with icon, title, detail, and optional suggestion
//    • "Run Again" button to re-run all checks
//    • "Go to Calibration" shortcut if white ref or calibration is missing
// ─────────────────────────────────────────────────────────────────────────────

class DeviceCheckScreen extends StatefulWidget {
  const DeviceCheckScreen({super.key});

  @override
  State<DeviceCheckScreen> createState() => _DeviceCheckScreenState();
}

class _DeviceCheckScreenState extends State<DeviceCheckScreen>
    with SingleTickerProviderStateMixin {

  final _service = DeviceCheckService();
  DeviceCheckResult? _result;
  bool _loading = true;
  String _loadingMsg = 'Initialising camera…';

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _runChecks();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _runChecks() async {
    setState(() { _loading = true; _result = null; });

    final msgs = [
      'Initialising camera…',
      'Checking resolution…',
      'Measuring sharpness…',
      'Verifying calibration…',
    ];

    for (final msg in msgs) {
      if (!mounted) return;
      setState(() => _loadingMsg = msg);
      await Future.delayed(const Duration(milliseconds: 400));
    }

    try {
      final result = await _service.runChecks();
      if (!mounted) return;
      setState(() { _result = result; _loading = false; });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check failed: $e')),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EFE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A5C38),
        foregroundColor: Colors.white,
        title: const Text(
          'Device Compatibility',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        actions: [
          if (!_loading)
            TextButton.icon(
              onPressed: _runChecks,
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              label: const Text('Re-run',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: _loading ? _buildLoading() : _buildResults(),
    );
  }

  // ── Loading state ─────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF3A5C38)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _loadingMsg,
            style: const TextStyle(
              color: Color(0xFF3A5C38),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Checking your device…',
            style: TextStyle(color: Colors.black38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Results ───────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final r = _result!;
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildVerdict(r),
          const SizedBox(height: 16),
          _buildSection('Camera Hardware', [r.resolution, r.sharpness]),
          const SizedBox(height: 12),
          _buildSection('Calibration Status', [r.whiteRef, r.calibration]),
          const SizedBox(height: 20),
          _buildActions(r),
          const SizedBox(height: 32),
          _buildInfoCard(),
        ],
      ),
    );
  }

  // ── Verdict banner ────────────────────────────────────────────────────────

  Widget _buildVerdict(DeviceCheckResult r) {
    final overall = r.overall;

    final (Color bg, Color fg, IconData icon, String title, String sub) =
    switch (overall) {
      CheckStatus.pass => (
      const Color(0xFF3A5C38),
      Colors.white,
      Icons.check_circle_rounded,
      'Ready to Scan',
      'Your device meets all requirements for accurate soil analysis.',
      ),
      CheckStatus.warn => (
      const Color(0xFFBF903E),
      Colors.white,
      Icons.info_rounded,
      'Needs Attention',
      'Results will work but calibration steps are recommended.',
      ),
      CheckStatus.fail => (
      const Color(0xFFB84B38),
      Colors.white,
      Icons.warning_rounded,
      'Issues Found',
      'Some issues may affect scan accuracy. See suggestions below.',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Icon(icon, color: fg, size: 40),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: fg, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(
                    color: fg.withOpacity(0.85), fontSize: 12.5,
                    height: 1.4)),
          ],
        )),
      ]),
    );
  }

  // ── Section ───────────────────────────────────────────────────────────────

  Widget _buildSection(String title, List<CheckItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Color(0xFF3A5C38),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD9D0C3)),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return _CheckRow(item: e.value, showDivider: !isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActions(DeviceCheckResult r) {
    final needsCalibration =
        r.whiteRef.status != CheckStatus.pass ||
            r.calibration.status != CheckStatus.pass;

    if (!needsCalibration) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CalibrationScreen()),
        ).then((_) => _runChecks()),
        icon: const Icon(Icons.tune, size: 18),
        label: const Text('Open Calibration'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3A5C38),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ── Info card ─────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEBD9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: Color(0xFF3A5C38), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Research shows that budget smartphones achieve ≥91% accuracy '
                  'when white reference calibration is used — regardless of camera '
                  'hardware. Calibrate first for the most reliable results.',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF3A5C38), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _CheckRow
// ─────────────────────────────────────────────────────────────────────────────

class _CheckRow extends StatefulWidget {
  final CheckItem item;
  final bool showDivider;

  const _CheckRow({required this.item, required this.showDivider});

  @override
  State<_CheckRow> createState() => _CheckRowState();
}

class _CheckRowState extends State<_CheckRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasSuggestion = item.suggestion != null;

    final (Color iconBg, Color iconFg, IconData statusIcon) =
    switch (item.status) {
      CheckStatus.pass => (
      const Color(0xFFDCEBD9),
      const Color(0xFF3A5C38),
      Icons.check_circle_rounded,
      ),
      CheckStatus.warn => (
      const Color(0xFFFFF3CD),
      const Color(0xFFBF903E),
      Icons.info_rounded,
      ),
      CheckStatus.fail => (
      const Color(0xFFFFE5E0),
      const Color(0xFFB84B38),
      Icons.cancel_rounded,
      ),
    };

    return Column(
      children: [
        InkWell(
          onTap: hasSuggestion
              ? () => setState(() => _expanded = !_expanded)
              : null,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(16),
            bottom: Radius.circular(widget.showDivider ? 0 : 16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: iconFg, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(item.detail,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              )),
              if (hasSuggestion)
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.black38, size: 20),
                ),
            ]),
          ),
        ),

        // Expandable suggestion
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(64, 0, 16, 14),
            child: Text(
              '💡 ${item.suggestion}',
              style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF3A5C38),
                  height: 1.5),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),

        if (widget.showDivider)
          const Divider(height: 1, indent: 64, color: Color(0xFFEEE8DF)),
      ],
    );
  }
}