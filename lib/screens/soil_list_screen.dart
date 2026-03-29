import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'soil_detail_screen.dart';

class SoilListScreen extends StatefulWidget {
  const SoilListScreen({super.key});
  @override
  State<SoilListScreen> createState() => _SoilListScreenState();
}

class _SoilListScreenState extends State<SoilListScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  static final _soils = [
    {'name': 'Clay Soil',   'desc': 'Nutrient-rich, poor drainage',   'color': 0xFF8D6E63,
      'fullDesc': 'Clay soil has very fine particles that pack tightly. It retains moisture and nutrients well but can waterlog and is hard to work when wet or dry.',
      'crops': 'Wheat, cabbage, lettuce, broccoli, Brussels sprouts',
      'ph': '5.5 – 7.0', 'drainage': 'Poor – prone to waterlogging',
      'tips': 'Add compost to improve aeration. Avoid working when wet. Consider raised beds.'},
    {'name': 'Sandy Soil',  'desc': 'Fast drainage, low nutrients',   'color': 0xFFD7CCC8,
      'fullDesc': 'Sandy soil has large particles with lots of air space. Water and nutrients drain quickly, making it easy to work but hard to keep fertile.',
      'crops': 'Carrots, radishes, strawberries, potatoes',
      'ph': '5.5 – 7.0', 'drainage': 'Excellent – drains very fast',
      'tips': 'Add organic matter frequently. Mulch heavily. Use slow-release fertilizers.'},
    {'name': 'Silty Soil',  'desc': 'Fertile, retains moisture well', 'color': 0xFFA1887F,
      'fullDesc': 'Silty soil has medium-sized particles that feel smooth and soapy. It is fertile and retains moisture well but can compact easily.',
      'crops': 'Most vegetables and fruits',
      'ph': '6.0 – 7.0', 'drainage': 'Moderate – can compact',
      'tips': 'Avoid heavy machinery. Add compost regularly to maintain structure.'},
    {'name': 'Loamy Soil',  'desc': 'Ideal mix of sand, silt & clay','color': 0xFF795548,
      'fullDesc': 'Loamy soil is the ideal type — balanced mix of sand, silt, and clay providing good drainage while retaining moisture and nutrients.',
      'crops': 'Almost all crops — vegetables, fruits, grains, flowers',
      'ph': '6.0 – 7.0', 'drainage': 'Good – well-balanced',
      'tips': 'Maintain with regular compost. Minimal amendment needed for most crops.'},
    {'name': 'Peaty Soil',  'desc': 'High organic matter, acidic',    'color': 0xFF4E342E,
      'fullDesc': 'Peaty soil is dark, rich in organic matter with a spongy texture. It retains large amounts of water and is naturally acidic.',
      'crops': 'Blueberries, cranberries, heathers, root crops',
      'ph': '3.5 – 6.0', 'drainage': 'Poor – holds a lot of water',
      'tips': 'Lime to raise pH. Install drainage. Excellent for acid-loving plants.'},
    {'name': 'Chalky Soil', 'desc': 'Alkaline, free-draining',        'color': 0xFFECEFF1,
      'fullDesc': 'Chalky soil is stony, free-draining with high pH from calcium carbonate. Can cause iron and manganese deficiencies.',
      'crops': 'Spinach, beets, sweet corn, cabbage, asparagus',
      'ph': '7.5 – 8.5', 'drainage': 'Very good – may dry out',
      'tips': 'Add organic matter. Use acidifying fertilizers. Mulch to retain moisture.'},
  ];

  List<Map<String, dynamic>> get _filtered => _soils
      .where((s) => s['name'].toString().toLowerCase().contains(_q.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Soil Types')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: TextField(
            controller: _ctrl,
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Search soil types…',
              prefixIcon: Icon(Icons.search_rounded,
                  color: cs.onSurface.withOpacity(0.35), size: 20),
              suffixIcon: _q.isNotEmpty ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: cs.onSurface.withOpacity(0.35), size: 18),
                  onPressed: () => setState(() { _q=''; _ctrl.clear(); })) : null,
            ),
          ),
        ),
        Expanded(child: _filtered.isEmpty
            ? Center(child: Text('No results for "$_q"',
            style: TextStyle(color: cs.onSurface.withOpacity(0.4))))
            : ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final soil = _filtered[i];
              final soilHex = soil['color'] as int;
              final isLight = soilHex == 0xFFECEFF1 || soilHex == 0xFFD7CCC8;
              return GestureDetector(
                onTap: () => Navigator.push(ctx,
                    MaterialPageRoute(builder: (_) => SoilDetailScreen(soil: soil))),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.outline.withOpacity(0.3))),
                  child: Row(children: [
                    Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                          color: Color(soilHex),
                          borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.landscape_rounded,
                          color: isLight
                              ? Colors.brown.withOpacity(0.5)
                              : Colors.white.withOpacity(0.5),
                          size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(soil['name'] as String,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      const SizedBox(height: 3),
                      Text(soil['desc'] as String,
                          style: TextStyle(fontSize: 12,
                              color: cs.onSurface.withOpacity(0.45))),
                    ])),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: cs.onSurface.withOpacity(0.25)),
                  ]),
                ),
              );
            })),
      ]),
      bottomNavigationBar: AppBottomNav(selectedIndex: 0, onTap: (_) => Navigator.pop(context)),
    );
  }
}