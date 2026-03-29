import 'package:flutter/material.dart';
import '../screens/camera_screen.dart';

class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  const AppBottomNav({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bot = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: bot + 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172017) : Colors.white,
        border: Border(top: BorderSide(color: cs.outline.withOpacity(0.3), width: 0.5)),
      ),
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded,
              label: 'Home', isSelected: selectedIndex == 0, onTap: () => onTap(0)),
          const SizedBox(width: 72),
          _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,
              label: 'Profile', isSelected: selectedIndex == 2, onTap: () => onTap(2)),
        ]),
        // Camera FAB — floating pill
        Positioned(
          top: -22,
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CameraScreen())),
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF2C5F2E),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF2C5F2E).withOpacity(0.35),
                      blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
            ),
          ),
        ),
      ]),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon,
    required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isSelected ? const Color(0xFF2C5F2E) : cs.onSurface.withOpacity(0.4);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(isSelected ? activeIcon : icon,
                key: ValueKey(isSelected), color: color, size: 24),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
                fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color),
            child: Text(label),
          ),
        ]),
      ),
    );
  }
}