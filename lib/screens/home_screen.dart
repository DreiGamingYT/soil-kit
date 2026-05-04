import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../main.dart';
import '../widgets/bottom_nav.dart';
import 'camera_screen.dart';
import '../models/soil_result.dart';
import 'color_chart_screen.dart';
import 'soil_list_screen.dart';
import 'shop_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'crop_guide_screen.dart';

class HomeScreen extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavTap;

  const HomeScreen({
    super.key,
    required this.selectedIndex,
    required this.onNavTap,
  });

  Widget _pageForIndex(int index) {
    switch (index) {
      case 1:
        return const ColorChartScreen(showBottomNav: false);
      case 2:
        return const SoilListScreen(showBottomNav: false);
      case 3:
        return const ShopScreen(showBottomNav: false);
      case 4:
        return const NotesScreen(showBottomNav: false);
      case 5:
        return const HistoryScreen(showBottomNav: false);
      case 6:
        return const CropGuideScreen();
      default:
        return const _HomeBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SettingsService.instance.language,
      builder: (_, __, ___) => Scaffold(
        body: _pageForIndex(selectedIndex),
        bottomNavigationBar: AppBottomNav(
          selectedIndex: selectedIndex,
          isDashboardSelected: selectedIndex == 5,
          onTap: (i) => onNavTap(i),
          onDashboardTap: () => onNavTap(5),
        ),

        floatingActionButton: selectedIndex == 3
            ? null
            : _DashboardFab(
          isSelected: selectedIndex == 5,
          onTap: () => onNavTap(5),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

// ── Home Body ─────────────────────────────────────────────────────────────────
class _HomeBody extends StatelessWidget {
  const _HomeBody();

  void _goToCamera(BuildContext context) {
    _showTestTypeSelection(context, onSelected: (testType) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraScreen(testType: testType),
        ),
      );
    });
  }

  void _showTestTypeSelection(
    BuildContext context, {
    required void Function(SoilTestType) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TestTypeSheet(onSelected: onSelected),
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    _showTestTypeSelection(context, onSelected: (testType) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CameraScreen(
              initialImagePath: pickedFile.path,
              testType: testType,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s  = SettingsService.instance;
    final cs = Theme.of(context).colorScheme;
    final firebaseUser = AuthService.instance.currentUser;
    final displayName  = firebaseUser?.displayName
        ?? firebaseUser?.email?.split('@').first
        ?? 'Farmer';
    final top = MediaQuery.of(context).padding.top;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, top > 0 ? 8 : 18, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ─────────────────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.outline),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: cs.onSurface.withOpacity(0.55),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.tr('hello'),
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.45),
                        ),
                      ),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.outline),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: cs.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Hero banner ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SoilColors.primary, SoilColors.primaryMid],
                ),
                borderRadius: BorderRadius.circular(Sr.rXl),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tap the scan button below to analyze your soil.',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ),
                  const Icon(Icons.eco, color: Colors.white),
                ],
              ),
            ),

            // ── CENTER: Scan button ──────────────────────────────
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => _goToCamera(context),
                  child: Container(
                    width: 164,
                    height: 164,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [SoilColors.primary, SoilColors.primaryMid],
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 70),
                        SizedBox(height: 8),
                        Text('SCAN',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom: Gallery button ───────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Upload from Gallery'),
                onPressed: () => _pickFromGallery(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardFab extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  const _DashboardFab({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected
              ? const LinearGradient(
            colors: [SoilColors.primary, SoilColors.primaryMid],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isSelected ? null : Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: SoilColors.primary.withOpacity(isSelected ? 0.4 : 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isSelected ? Icons.bar_chart_rounded : Icons.bar_chart_rounded,
          color: isSelected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
          size: 24,
        ),
      ),
    );
  }
}

// ── Test Type Selection Sheet ─────────────────────────────────────────────────
class _TestTypeSheet extends StatelessWidget {
  final void Function(SoilTestType) onSelected;
  const _TestTypeSheet({required this.onSelected});

  static const _tests = [
    SoilTestType.nitrogen,
    SoilTestType.phosphorus,
    SoilTestType.potassium,
    SoilTestType.ph,
  ];

  static const _descriptions = {
    SoilTestType.nitrogen:   'Green color spectrum',
    SoilTestType.phosphorus: 'Orange color spectrum',
    SoilTestType.potassium:  'Purple color spectrum',
    SoilTestType.ph:         'Blue color spectrum',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Anong test gagawin mo?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Piliin muna bago mag-open ng camera',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ..._tests.map((t) => _TestTile(
            testType: t,
            description: _descriptions[t]!,
            onTap: () {
              Navigator.pop(context);
              onSelected(t);
            },
          )),
        ],
      ),
    );
  }
}

class _TestTile extends StatelessWidget {
  final SoilTestType testType;
  final String description;
  final VoidCallback onTap;
  const _TestTile({
    required this.testType,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = testType.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            borderRadius: BorderRadius.circular(16),
            color: color.withOpacity(0.06),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                testType.shortLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    testType.label,
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ]),
        ),
      ),
    );
  }
}