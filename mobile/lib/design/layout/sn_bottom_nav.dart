// design/layout/sn_bottom_nav.dart
//
// Student: Home · Explore · My Stays · Saved · Profile
// Owner:   Dashboard · Hostels · Tenants · Reports · Settings
//
// Five tabs is the ceiling. Messages goes in the app bar, not the nav.

import 'package:flutter/material.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';

class SNNavItem {
  const SNNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const studentNavItems = [
  SNNavItem(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  SNNavItem(
    label: 'Explore',
    icon: Icons.explore_outlined,
    activeIcon: Icons.explore_rounded,
  ),
  SNNavItem(
    label: 'My Stays',
    icon: Icons.luggage_outlined,
    activeIcon: Icons.luggage_rounded,
  ),
  SNNavItem(
    label: 'Saved',
    icon: Icons.favorite_border_rounded,
    activeIcon: Icons.favorite_rounded,
  ),
  SNNavItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
  ),
];

const ownerNavItems = [
  SNNavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
  ),
  SNNavItem(
    label: 'Hostels',
    icon: Icons.apartment_outlined,
    activeIcon: Icons.apartment_rounded,
  ),
  SNNavItem(
    label: 'Tenants',
    icon: Icons.people_outline_rounded,
    activeIcon: Icons.people_rounded,
  ),
  SNNavItem(
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
  ),
  SNNavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
  ),
];

class SNBottomNav extends StatelessWidget {
  const SNBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  const SNBottomNav.student({
    super.key,
    required this.currentIndex,
    required this.onTap,
  }) : items = studentNavItems;

  const SNBottomNav.owner({
    super.key,
    required this.currentIndex,
    required this.onTap,
  }) : items = ownerNavItems;

  final List<SNNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: [
          BoxShadow(
            color: c.shadowTint.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SNSpace.x4,
            vertical: SNSpace.x2,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _NavTab(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final SNNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final color = active ? c.primary : c.mutedForeground;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: SNSpace.minTapTarget + 8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? item.activeIcon : item.icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: SNSpace.x1),
            Text(
              item.label,
              style: SNText.caption.copyWith(
                color: color,
                fontWeight: active ? SNWeight.bold : SNWeight.medium,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
