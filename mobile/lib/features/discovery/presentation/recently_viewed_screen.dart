import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/core/utils/recently_viewed_manager.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/domain/sn_domain_cards.dart';

class RecentlyViewedScreen extends ConsumerStatefulWidget {
  const RecentlyViewedScreen({super.key});

  @override
  ConsumerState<RecentlyViewedScreen> createState() =>
      _RecentlyViewedScreenState();
}

class _RecentlyViewedScreenState extends ConsumerState<RecentlyViewedScreen> {
  List<RecentlyViewedItem>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await RecentlyViewedManager.getAll();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content:
            const Text('Remove all recently viewed hostels?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await RecentlyViewedManager.clearAll();
      _load();
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return 'Viewed ${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return 'Viewed ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Viewed ${diff.inDays}d ago';
    return 'Viewed ${diff.inDays ~/ 7}w ago';
  }

  int get _todayCount {
    if (_items == null) return 0;
    final now = DateTime.now();
    return _items!
        .where((i) =>
            i.viewedAt.year == now.year &&
            i.viewedAt.month == now.month &&
            i.viewedAt.day == now.day)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: c.card,
                border: Border(
                  bottom: BorderSide(color: c.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  SNCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/'),
                  ),
                  const SizedBox(width: 16),
                  Text('RECENTLY VIEWED', style: SNText.headingMd),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_items == null || _items!.isEmpty)
                      ? Center(
                          child: SNEmptyState(
                            icon: Icons.access_time_rounded,
                            headline: 'No hostels viewed yet',
                            body:
                                'Hostels you browse will appear here for quick access.',
                            actionLabel: 'Explore Hostels',
                            onAction: () => context.go('/home'),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            // ── Header row ──
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${_items!.length} Hostels Browsed${_todayCount > 0 ? " Today" : ""}',
                                      style: SNText.sectionLabel,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _clearAll,
                                    child: Text(
                                      'CLEAR ALL',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: c.destructive,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── List ──
                            ..._items!.asMap().entries.map((entry) {
                              final i = entry.key;
                              final item = entry.value;
                              final isOlder = i > 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Opacity(
                                  opacity: isOlder ? 0.85 : 1.0,
                                  child: _HostelRow(
                                    item: item,
                                    timeAgo: _timeAgo(item.viewedAt),
                                    onTap: () => context.push(
                                      '/hostel/${item.hostelId}',
                                    ),
                                    onDismiss: () async {
                                      await RecentlyViewedManager.remove(
                                          item.hostelId);
                                      _load();
                                    },
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostelRow extends StatelessWidget {
  final RecentlyViewedItem item;
  final String timeAgo;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _HostelRow({
    required this.item,
    required this.timeAgo,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Dismissible(
      key: ValueKey(item.hostelId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: c.destructive.withOpacity(0.1),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Icon(Icons.delete_outline_rounded, color: c.destructive),
      ),
      confirmDismiss: (_) async {
        onDismiss();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Image ──
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: item.imageUrl != null
                      ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: c.muted,
                          child: Icon(
                            Icons.home_outlined,
                            color: c.mutedForeground,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: c.foreground,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: c.mutedForeground,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              Money.format(item.pricePesewas),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: c.primary,
                              ),
                            ),
                            Text(
                              '',
                              style: TextStyle(
                                fontSize: 8,
                                fontStyle: FontStyle.italic,
                                color: c.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star_outline_rounded,
                              size: 12,
                              color: const Color(0xFFEAB308),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: c.foreground,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
