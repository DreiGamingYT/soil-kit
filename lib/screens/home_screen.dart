import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../main.dart';
import '../widgets/bottom_nav.dart';
import 'camera_screen.dart';
import 'color_chart_screen.dart';
import 'soil_list_screen.dart';
import 'shop_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'fert_right_screen.dart';

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
        return const FertRightScreen();
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

        floatingActionButton: selectedIndex == 3 || selectedIndex == 6
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraScreen(initialImagePath: pickedFile.path),
        ),
      );
    }
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