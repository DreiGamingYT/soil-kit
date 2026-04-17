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
      default:
        return const _HomeBody();
    }
  }

  void _showCameraSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CameraOptionsSheet(),
    );
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
          onTap: (i) {
            if (i == 2 && selectedIndex != 2) {
              onNavTap(i);
            } else {
              onNavTap(i);
            }
          },
          onDashboardTap: () => onNavTap(5),
        ),
      ),
    );
  }
}

// ── Camera Options Sheet ──────────────────────────────────────────────────────
class _CameraOptionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bot   = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? SoilColors.surfaceDark : SoilColors.surfaceLight,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(Sr.rXl)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bot + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(Sr.rPill),
              ),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SoilColors.primary, SoilColors.primaryMid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Analyze Soil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload an existing image\nto get instant soil analysis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onSurface.withOpacity(0.48),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          _OptionTile(
            icon: Icons.photo_library_outlined,
            title: 'Upload from Gallery',
            subtitle: 'Choose a photo from your gallery',
            color: SoilColors.harvest,
            onTap: () async {
              Navigator.pop(context);

              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);

              if (pickedFile != null) {
                // Send the image to your analysis screen or process it here
                // Example:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CameraScreen(), // replace with your image preview/analyze screen
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(Sr.rMd),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cs.onSurface.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: color.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Home Body ─────────────────────────────────────────────────────────────────
class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final s   = SettingsService.instance;
    final cs  = Theme.of(context).colorScheme;
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
                        s.tr('username'),
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

            // ── CENTER AREA ─────────────────────────────────────
            Expanded(
              child: Center(
                child: Builder(
                  builder: (ctx) => GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: ctx,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _CameraOptionsSheet(),
                    ),
                    child: Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [SoilColors.primary, SoilColors.primaryMid],
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 48),
                          SizedBox(height: 8),
                          Text('SCAN',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Upload from Gallery'),
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile =
                  await picker.pickImage(source: ImageSource.gallery);

                  if (pickedFile != null) {
                    // handle image
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}