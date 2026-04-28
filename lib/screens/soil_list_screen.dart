import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/bottom_nav.dart';

class SoilListScreen extends StatefulWidget {
  final bool showBottomNav;

  const SoilListScreen({
    super.key,
    this.showBottomNav = false,
  });

  @override
  State<SoilListScreen> createState() => _SoilListScreenState();
}

class _SoilListScreenState extends State<SoilListScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  static final _soils = [
    {
      'name': 'Clay Soil',
      'desc': 'Nutrient-rich, poor drainage',
      'color': 0xFF8D6E63,
      'fullDesc':
      'Clay soil has very fine particles that pack tightly. It retains moisture and nutrients well but can waterlog and is hard to work when wet or dry.',
      'crops': 'Wheat, cabbage, lettuce, broccoli, Brussels sprouts',
      'ph': '5.5 – 7.0',
      'drainage': 'Poor – prone to waterlogging',
      'tips': 'Add compost to improve aeration. Avoid working when wet. Consider raised beds.',
    },
    {
      'name': 'Sandy Soil',
      'desc': 'Fast drainage, low nutrients',
      'color': 0xFFD7CCC8,
      'fullDesc':
      'Sandy soil has large particles with lots of air space. Water and nutrients drain quickly, making it easy to work but hard to keep fertile.',
      'crops': 'Carrots, radishes, strawberries, potatoes',
      'ph': '5.5 – 7.0',
      'drainage': 'Excellent – drains very fast',
      'tips': 'Add organic matter frequently. Mulch heavily. Use slow-release fertilizers.',
    },
    {
      'name': 'Silty Soil',
      'desc': 'Fertile, retains moisture well',
      'color': 0xFFA1887F,
      'fullDesc':
      'Silty soil has medium-sized particles that feel smooth and soapy. It is fertile and retains moisture well but can compact easily.',
      'crops': 'Most vegetables and fruits',
      'ph': '6.0 – 7.0',
      'drainage': 'Moderate – can compact',
      'tips': 'Avoid heavy machinery. Add compost regularly to maintain structure.',
    },
    {
      'name': 'Loamy Soil',
      'desc': 'Ideal mix of sand, silt & clay',
      'color': 0xFF795548,
      'fullDesc':
      'Loamy soil is the ideal type — balanced mix of sand, silt, and clay providing good drainage while retaining moisture and nutrients.',
      'crops': 'Almost all crops — vegetables, fruits, grains, flowers',
      'ph': '6.0 – 7.0',
      'drainage': 'Good – well-balanced',
      'tips': 'Maintain with regular compost. Minimal amendment needed for most crops.',
    },
    {
      'name': 'Peaty Soil',
      'desc': 'High organic matter, acidic',
      'color': 0xFF4E342E,
      'fullDesc':
      'Peaty soil is dark, rich in organic matter with a spongy texture. It retains large amounts of water and is naturally acidic.',
      'crops': 'Blueberries, cranberries, heathers, root crops',
      'ph': '3.5 – 6.0',
      'drainage': 'Poor – holds a lot of water',
      'tips': 'Lime to raise pH. Install drainage. Excellent for acid-loving plants.',
    },
    {
      'name': 'Chalky Soil',
      'desc': 'Alkaline, free-draining',
      'color': 0xFFECEFF1,
      'fullDesc':
      'Chalky soil is stony, free-draining with high pH from calcium carbonate. Can cause iron and manganese deficiencies.',
      'crops': 'Spinach, beets, sweet corn, cabbage, asparagus',
      'ph': '7.5 – 8.5',
      'drainage': 'Very good – may dry out',
      'tips': 'Add organic matter. Use acidifying fertilizers. Mulch to retain moisture.',
    },
  ];

  List<Map<String, dynamic>> get _filtered => _soils
      .where(
        (s) => s['name'].toString().toLowerCase().contains(_q.toLowerCase()),
  )
      .toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Soil Types')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Search soil types…',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: cs.onSurface.withOpacity(0.35),
                  size: 20,
                ),
                suffixIcon: _q.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: cs.onSurface.withOpacity(0.35),
                    size: 18,
                  ),
                  onPressed: () => setState(() {
                    _q = '';
                    _ctrl.clear();
                  }),
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
              child: Text(
                'No results for "$_q"',
                style: TextStyle(color: cs.onSurface.withOpacity(0.4)),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final soil = _filtered[i];
                final soilHex = soil['color'] as int;
                final isLight = soilHex == 0xFFECEFF1 || soilHex == 0xFFD7CCC8;

                return GestureDetector(
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => SoilDetailScreen(soil: soil),
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
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Color(soilHex),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.landscape_rounded,
                            color: isLight
                                ? Colors.brown.withOpacity(0.45)
                                : Colors.white.withOpacity(0.5),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                soil['name'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                soil['desc'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withOpacity(0.42),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: cs.onSurface.withOpacity(0.22),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav
          ? AppBottomNav(
        selectedIndex: 2,
        onTap: (_) => Navigator.pop(context),
      )
          : null,
    );
  }
}

class SoilDetailScreen extends StatelessWidget {
  final Map<String, dynamic> soil;
  const SoilDetailScreen({super.key, required this.soil});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final soilColor = Color(soil['color'] as int);
    final isLight = (soil['color'] as int) == 0xFFECEFF1 || (soil['color'] as int) == 0xFFD7CCC8;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            backgroundColor: soilColor,
            iconTheme: IconThemeData(
              color: isLight ? Colors.black87 : Colors.white,
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                soil['name'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.5,
                  color: isLight ? Colors.black87 : Colors.white,
                ),
              ),
              background: Container(
                color: soilColor,
                child: Center(
                  child: Icon(
                    Icons.landscape_rounded,
                    size: 72,
                    color: (isLight ? Colors.brown : Colors.white).withOpacity(0.15),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _InfoTile(
                    label: 'Description',
                    value: soil['fullDesc'] as String,
                    cs: cs,
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    label: 'Best Crops',
                    value: soil['crops'] as String,
                    cs: cs,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          label: 'pH Range',
                          value: soil['ph'] as String,
                          cs: cs,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoTile(
                          label: 'Drainage',
                          value: soil['drainage'] as String,
                          cs: cs,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E8),
                      borderRadius: BorderRadius.circular(Sr.rMd),
                      border: Border.all(
                        color: SoilColors.harvest.withOpacity(0.28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: SoilColors.harvest,
                              size: 15,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Improvement Tips',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: SoilColors.harvest,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          soil['tips'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.65,
                            color: Color(0xFF7C6000),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Test This Soil'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  final ColorScheme cs;
  const _InfoTile({required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(Sr.rMd),
      border: Border.all(color: cs.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: SoilColors.primary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            height: 1.55,
            color: cs.onSurface.withOpacity(0.75),
          ),
        ),
      ],
    ),
  );
}