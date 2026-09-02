// features/discovery/presentation/student_shell.dart
//
// The student's tabbed shell. Wraps five branches in a StatefulShellRoute
// so each tab retains its own navigation stack.
//
// Tabs: Home · Explore · My Stays · Saved · Profile

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staynest_mobile/features/booking/data/bookings_provider.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/typography.dart';

class StudentShell extends ConsumerWidget {
  const StudentShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final bookingsAsync = ref.watch(myBookingsProvider);
    final hasCheckedIn = bookingsAsync.whenOrNull(
      data: (list) => list.any((b) => b.status == 'CHECKED_IN'),
    ) ?? false;

    return Scaffold(
      backgroundColor: c.background,
      body: navigationShell,
      bottomNavigationBar: _StudentBottomNav(
        currentIndex: navigationShell.currentIndex,
        hasCheckedIn: hasCheckedIn,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

// ── Bottom nav ──────────────────────────────────────
// If your existing SNBottomNav.student widget already handles this,
// swap this out for it. This is self-contained so it compiles standalone.

class _StudentBottomNav extends StatelessWidget {
  const _StudentBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.hasCheckedIn = false,
  });

  final int currentIndex;
  final void Function(int) onTap;
  final bool hasCheckedIn;

  List<_NavItem> get _items => [
    const _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    const _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Explore'),
    _NavItem(
      icon: hasCheckedIn ? Icons.bed_outlined : Icons.luggage_outlined,
      activeIcon: hasCheckedIn ? Icons.bed_rounded : Icons.luggage_rounded,
      label: hasCheckedIn ? 'My Room' : 'My Stays',
    ),
    const _NavItem(icon: Icons.favorite_border_rounded, activeIcon: Icons.favorite_rounded, label: 'Saved'),
    const _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == currentIndex;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: SizedBox(
                  width: 64,
                  height: 48,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? item.activeIcon : item.icon,
                        size: 24,
                        color: active ? c.primary : c.mutedForeground,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: SNFont.sans,
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? c.primary : c.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
