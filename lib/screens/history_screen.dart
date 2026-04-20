import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/soil_result.dart';
import '../services/soil_data_service.dart';
import '../main.dart';
import '../widgets/bottom_nav.dart';
import 'camera_result_screen.dart';

// ── Period definition ─────────────────────────────────────────────────────────
enum _Period { day, week, month, year }

extension _PeriodX on _Period {
  String get label {
    switch (this) {
      case _Period.day:   return 'Day';
      case _Period.week:  return 'Week';
      case _Period.month: return 'Month';
      case _Period.year:  return 'Year';
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
const _monthsShort = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const _monthsFull  = ['January','February','March','April','May','June','July','August','September','October','November','December'];

// ── Screen ────────────────────────────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  final bool showBottomNav;
  const HistoryScreen({super.key, this.showBottomNav = true});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Each tab has its own PageController; page 500 = current period
  static const int _midPage = 500;
  final _pageCtrl = List.generate(_Period.values.length, (_) => PageController(initialPage: _midPage));

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    for (final c in _pageCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Data helpers ────────────────────────────────────────────────────────────
  List<SoilResult> _getResults(_Period period, int pageIndex) {
    final offset = _midPage - pageIndex; // 0 = current, 1 = one back, etc.
    if (offset < 0) return _getResults(period, _midPage); // future → current
    final all = SoilDataService.instance.results;
    final now = DateTime.now();

    switch (period) {
      case _Period.day:
        final day = DateTime(now.year, now.month, now.day - offset);
        return all
            .where((r) =>
        r.date.year == day.year &&
            r.date.month == day.month &&
            r.date.day == day.day)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

      case _Period.week:
        final weekStart = _weekStart(now).subtract(Duration(days: offset * 7));
        final weekEnd   = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
        return all
            .where((r) =>
        !r.date.isBefore(weekStart) && !r.date.isAfter(weekEnd))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

      case _Period.month:
        final m = DateTime(now.year, now.month - offset);
        return all
            .where((r) => r.date.year == m.year && r.date.month == m.month)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

      case _Period.year:
        final y = now.year - offset;
        return all
            .where((r) => r.date.year == y)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  DateTime _weekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  String _periodTitle(_Period period, int pageIndex) {
    final offset = _midPage - pageIndex;
    if (offset < 0) return _periodTitle(period, _midPage);
    final now = DateTime.now();

    switch (period) {
      case _Period.day:
        if (offset == 0) return 'Today';
        if (offset == 1) return 'Yesterday';
        final d = DateTime(now.year, now.month, now.day - offset);
        return '${_monthsShort[d.month - 1]} ${d.day}, ${d.year}';

      case _Period.week:
        if (offset == 0) return 'This Week';
        if (offset == 1) return 'Last Week';
        final ws = _weekStart(now).subtract(Duration(days: offset * 7));
        final we = ws.add(const Duration(days: 6));
        return '${_monthsShort[ws.month-1]} ${ws.day} – ${_monthsShort[we.month-1]} ${we.day}';

      case _Period.month:
        if (offset == 0) return 'This Month';
        if (offset == 1) return 'Last Month';
        final m = DateTime(now.year, now.month - offset);
        return '${_monthsFull[m.month - 1]} ${m.year}';

      case _Period.year:
        if (offset == 0) return 'This Year';
        return '${now.year - offset}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            height: 44,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: isDark
                  ? SoilColors.surfaceElevDark
                  : SoilColors.surfaceElevLight,
              borderRadius: BorderRadius.circular(Sr.rPill),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: SoilColors.primary,
                borderRadius: BorderRadius.circular(Sr.rPill),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: cs.onSurface.withOpacity(0.45),
              labelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                ..._Period.values.map((p) => Tab(text: p.label)),
                const Tab(text: 'Trends'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ..._Period.values.asMap().entries.map((e) {
            final tabIdx = e.key;
            final period = e.value;
            return PageView.builder(
              controller: _pageCtrl[tabIdx],
              itemBuilder: (_, page) {
                final offset = _midPage - page;
                if (offset < 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_pageCtrl[tabIdx].hasClients) {
                      _pageCtrl[tabIdx].jumpToPage(_midPage);
                    }
                  });
                }
                final results = _getResults(period, page);
                final title   = _periodTitle(period, page);
                return _PeriodPage(
                  period: period,
                  title: title,
                  results: results,
                  offset: offset < 0 ? 0 : offset,
                );
              },
            );
          }).toList(),

          // ✅ ADD THIS AS LAST ITEM (6th tab)
          _TrendsTab(),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav
          ? AppBottomNav(
        selectedIndex: 3,
        onTap: (_) => Navigator.pop(context),
      )
          : null,
    );
  }
}

// ── Period Page ───────────────────────────────────────────────────────────────
class _PeriodPage extends StatelessWidget {
  final _Period period;
  final String title;
  final List<SoilResult> results;
  final int offset;

  const _PeriodPage({
    required this.period,
    required this.title,
    required this.results,
    required this.offset,
  });

  Color _scoreColor(double s) {
    if (s >= 70) return SoilColors.high;
    if (s >= 45) return SoilColors.medium;
    return SoilColors.low;
  }

  double get _avgScore => results.isEmpty
      ? 0
      : results.map((r) => r.overallScore).reduce((a, b) => a + b) /
      results.length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return results.isEmpty
        ? _EmptyPeriod(title: title, offset: offset, period: period)
        : CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Period header ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${results.length} test${results.length != 1 ? 's' : ''} recorded',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.42),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (offset > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: SoilColors.primaryLight.withOpacity(0.7),
                          borderRadius:
                          BorderRadius.circular(Sr.rPill),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded,
                                size: 12,
                                color: SoilColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '$offset ${period.label.toLowerCase()}${offset > 1 ? 's' : ''} ago',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: SoilColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Summary cards ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Tests',
                        value: '${results.length}',
                        icon: Icons.science_outlined,
                        color: SoilColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Avg Score',
                        value: _avgScore.toStringAsFixed(0),
                        icon: Icons.star_outline_rounded,
                        color: _scoreColor(_avgScore),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Best',
                        value: results
                            .map((r) => r.overallScore)
                            .reduce((a, b) => a > b ? a : b)
                            .toStringAsFixed(0),
                        icon: Icons.trending_up_rounded,
                        color: SoilColors.high,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Score bar chart ───────────────────────────────────
                if (results.length > 1) ...[
                  _ScoreChart(results: results),
                  const SizedBox(height: 16),
                ],

                // ── Soil type breakdown ───────────────────────────────
                _SoilTypeBreakdown(results: results),
                const SizedBox(height: 16),

                Text(
                  'Tests',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // ── Test list ─────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ResultTile(result: results[i]),
              ),
              childCount: results.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Sr.rMd),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurface.withOpacity(0.42),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score Bar Chart ───────────────────────────────────────────────────────────
class _ScoreChart extends StatelessWidget {
  final List<SoilResult> results;
  const _ScoreChart({required this.results});

  Color _scoreColor(double s) {
    if (s >= 70) return SoilColors.high;
    if (s >= 45) return SoilColors.medium;
    return SoilColors.low;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shown = results.length > 8 ? results.sublist(0, 8) : results;
    final reversed = shown.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Sr.rMd),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  size: 14, color: SoilColors.primary),
              const SizedBox(width: 6),
              Text(
                'Score Trend',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: reversed.map((r) {
                final frac = r.overallScore / 100;
                final col = _scoreColor(r.overallScore);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: frac.clamp(0.05, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: col,
                                  borderRadius:
                                  const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.overallScore.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 8,
                            color: cs.onSurface.withOpacity(0.4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Soil Type Breakdown ───────────────────────────────────────────────────────
class _SoilTypeBreakdown extends StatelessWidget {
  final List<SoilResult> results;
  const _SoilTypeBreakdown({required this.results});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final counts = <String, int>{};
    for (final r in results) {
      counts[r.soilType] = (counts[r.soilType] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();

    if (top.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Sr.rMd),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terrain_rounded,
                  size: 14, color: SoilColors.primary),
              const SizedBox(width: 6),
              Text(
                'Soil Types',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...top.map((e) {
            final pct = e.value / results.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${e.value}×  ${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Sr.rPill),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: SoilColors.primaryLight.withOpacity(0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          SoilColors.primaryMid),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Result Tile ───────────────────────────────────────────────────────────────
class _ResultTile extends StatelessWidget {
  final SoilResult result;
  const _ResultTile({required this.result});

  Color _scoreColor(double s) {
    if (s >= 70) return SoilColors.high;
    if (s >= 45) return SoilColors.medium;
    return SoilColors.low;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final col = _scoreColor(result.overallScore);
    final d   = result.date;
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final date = '${_monthsShort[d.month - 1]} ${d.day}, ${d.year}  $time';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraResultScreen(result: result),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(Sr.rLg),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            // Score ring
            Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: result.overallScore / 100,
                  strokeWidth: 3,
                  backgroundColor: col.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(col),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${result.overallScore.toInt()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: col,
                ),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.soilType,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.38),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(spacing: 4, runSpacing: 3, children: [
                    _Chip('N', result.nitrogenLevel),
                    _Chip('P', result.phosphorusLevel),
                    _Chip('K', result.potassiumLevel),
                    _PhChip(result.ph.toString()),
                  ]),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: cs.onSurface.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}

// ── Chips ─────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label, level;
  const _Chip(this.label, this.level);

  Color get _c {
    switch (level.toLowerCase()) {
      case 'high':   return SoilColors.high;
      case 'medium': return SoilColors.medium;
      default:       return SoilColors.low;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: _c.withOpacity(0.10),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: _c.withOpacity(0.28)),
    ),
    child: Text(
      '$label · $level',
      style: TextStyle(color: _c, fontSize: 8.5, fontWeight: FontWeight.w700),
    ),
  );
}

class _PhChip extends StatelessWidget {
  final String ph;
  const _PhChip(this.ph);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        'pH $ph',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}

// ── Empty Period ──────────────────────────────────────────────────────────────
class _EmptyPeriod extends StatelessWidget {
  final String title;
  final int offset;
  final _Period period;
  const _EmptyPeriod({
    required this.title,
    required this.offset,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSwipeable = offset > 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: SoilColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 32,
                color: SoilColors.primary.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withOpacity(0.55),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSwipeable
                  ? 'No tests recorded for this ${period.label.toLowerCase()}.'
                  : 'No tests yet. Take your first soil photo!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.32),
                height: 1.5,
              ),
            ),
            if (!isSwipeable) ...[
              const SizedBox(height: 6),
              Text(
                '← Swipe to see older records →',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withOpacity(0.22),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final results = SoilDataService.instance.results;
    if (results.length < 2) {
      return const Center(child: Text('Scan at least 2 times to see trends.'));
    }
    // Sort oldest → newest
    final sorted = [...results]..sort((a, b) => a.date.compareTo(b.date));

    int _npkScore(SoilResult r, String nutrient) {
      final val = nutrient == 'N' ? r.nitrogenLevel
          : nutrient == 'P' ? r.phosphorusLevel : r.potassiumLevel;
      return val == 'High' ? 3 : val == 'Medium' ? 2 : 1;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(LineChartData(
        titlesData: FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: sorted.asMap().entries.map((e) =>
                FlSpot(e.key.toDouble(), e.value.overallScore)).toList(),
            isCurved: true,
            color: SoilColors.primary,
            barWidth: 2,
            dotData: FlDotData(show: true),
          ),
        ],
      )),
    );
  }
}