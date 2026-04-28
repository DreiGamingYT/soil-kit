import 'package:flutter/material.dart';
import '../main.dart';

/// Use [onDashboardTap] or pass index 5 through [onTap].
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  /// Whether the Dashboard screen is currently active.
  final bool isDashboardSelected;

  /// Called when the floating Dashboard circle is tapped.
  final VoidCallback? onDashboardTap;

  /// Shows a badge count on the Cart icon when > 0.
  final int cartCount;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.isDashboardSelected = false,
    this.onDashboardTap,
    this.cartCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bot    = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 10, bottom: bot + 12),
      decoration: BoxDecoration(
        color: isDark ? SoilColors.surfaceDark : SoilColors.surfaceLight,
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.5), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', isSelected: selectedIndex == 0, onTap: () => onTap(0))),
          Expanded(child: _NavItem(icon: Icons.palette_outlined, activeIcon: Icons.palette_rounded, label: 'Color', isSelected: selectedIndex == 1, onTap: () => onTap(1))),
          Expanded(child: _NavItem(icon: Icons.terrain_outlined, activeIcon: Icons.terrain_rounded, label: 'Soil', isSelected: selectedIndex == 2, onTap: () => onTap(2))),
          Expanded(child: _NavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded, label: 'Shop', isSelected: selectedIndex == 3, onTap: () => onTap(3), badge: cartCount > 0 ? cartCount : null)),
          Expanded(child: _NavItem(icon: Icons.edit_note_outlined, activeIcon: Icons.edit_note_rounded, label: 'Notes', isSelected: selectedIndex == 4, onTap: () => onTap(4))),
          Expanded(child: _NavItem(
            icon: Icons.calculate_outlined,
            activeIcon: Icons.calculate_rounded,
            label: 'Calc',
            isSelected: selectedIndex == 6,
            onTap: () => onTap(6),
          )),
        ],
      ),
    );
  }
}

// ── Nav Item ──────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final color = isSelected
        ? SoilColors.primary
        : cs.onSurface.withValues(alpha: 0.38);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? SoilColors.primaryLight.withValues(alpha: 0.7)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(Sr.rPill),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      key: ValueKey(isSelected),
                      color: color,
                      size: 22,
                    ),
                  ),
                  // ── Cart badge ────────────────────────────────────────
                  if (badge != null)
                    Positioned(
                      top: -6,
                      right: -8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: SoilColors.clay,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
                letterSpacing: 0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}