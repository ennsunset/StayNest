// features/discovery/presentation/saved_screen.dart
//
// Saved tab - 2-column grid of saved hostels (local state for now).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/domain/sn_image.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/discovery/data/hostels_repository.dart';

/// Saved hostel IDs - persisted to SharedPreferences.
final savedHostelIdsProvider = StateNotifierProvider<SavedHostelIdsNotifier, Set<String>>((ref) {
  return SavedHostelIdsNotifier();
});

class SavedHostelIdsNotifier extends StateNotifier<Set<String>> {
  SavedHostelIdsNotifier() : super({}) {
    _load();
  }

  static const _key = 'saved_hostel_ids';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    state = ids.toSet();
  }

  Future<void> toggle(String id) async {
    final updated = Set<String>.from(state);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated.toList());
  }

  Future<void> remove(String id) async {
    final updated = Set<String>.from(state)..remove(id);
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated.toList());
  }
}

final _savedHostelsProvider = FutureProvider<List<Hostel>>((ref) async {
  final ids = ref.watch(savedHostelIdsProvider);
  if (ids.isEmpty) return [];
  final repo = ref.read(hostelsRepositoryProvider);
  final all = await repo.search(page: 1, limit: 50);
  return all.where((h) => ids.contains(h.id)).toList();
});

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final savedIds = ref.watch(savedHostelIdsProvider);
    final savedAsync = ref.watch(_savedHostelsProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.x4,
              ),
              child: Text('Saved Hostels',
                style: SNText.headingLg.copyWith(color: c.foreground)),
            ),

            // Filter pills
            SizedBox(
              height: SNSpace.minTapTarget,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
                children: [
                  SNChip(
                    label: 'All (${savedIds.length})',
                    selected: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: SNSpace.x2),
                  SNChip(label: 'Under GH₵3k', selected: false, onTap: () {}),
                  const SizedBox(width: SNSpace.x2),
                  SNChip(label: 'Near Campus', selected: false, onTap: () {}),
                ],
              ),
            ),

            const SizedBox(height: SNSpace.x5),

            // Grid
            Expanded(
              child: savedIds.isEmpty
                  ? Center(
                      child: SNEmptyState(
                        icon: Icons.favorite_border_rounded,
                        headline: 'No saved hostels yet',
                        actionLabel: 'Find a hostel',
                        onAction: () => context.go('/home'),
                      ),
                    )
                  : savedAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: SNErrorState(
                          headline: 'Could not load saved hostels',
                          onRetry: () => ref.invalidate(_savedHostelsProvider),
                        ),
                      ),
                      data: (hostels) => _buildGrid(context, c, hostels, ref),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, SNColorTokens c, List<Hostel> hostels, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        SNSpace.screenX, 0, SNSpace.screenX, SNSpace.navClear,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: SNSpace.x3,
        mainAxisSpacing: SNSpace.x3,
        childAspectRatio: 0.85,
      ),
      itemCount: hostels.length + 1, // +1 for "Find More" card
      itemBuilder: (_, i) {
        if (i == hostels.length) return _FindMoreCard(c: c);
        return _SavedHostelCard(
          hostel: hostels[i],
          c: c,
          onTap: () => context.push('/home/hostel/${hostels[i].id}'),
          onUnsave: () {
            ref.read(savedHostelIdsProvider.notifier).remove(hostels[i].id);
          },
        );
      },
    );
  }
}

class _SavedHostelCard extends StatelessWidget {
  const _SavedHostelCard({
    required this.hostel,
    required this.c,
    required this.onTap,
    required this.onUnsave,
  });

  final Hostel hostel;
  final SNColorTokens c;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with heart
            Stack(
              children: [
                SNImage(
                  url: hostel.imageUrls.isNotEmpty ? hostel.imageUrls.first : null,
                  height: 110,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: onUnsave,
                    child: Container(
                      height: 32, width: 32,
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: c.foreground.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(Icons.favorite_rounded, size: 18, color: c.destructive),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(SNSpace.x3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hostel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SNText.bodyBold.copyWith(color: c.foreground),
                  ),
                  const SizedBox(height: 2),
                  if (hostel.address.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 12, color: c.mutedForeground),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            hostel.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SNText.caption.copyWith(color: c.mutedForeground, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: Money.formatCompact(hostel.fromPricePesewas),
                        style: SNText.bodyBold.copyWith(color: c.primary, fontSize: 13),
                      ),
                      TextSpan(
                        text: ' / sem',
                        style: SNText.caption.copyWith(
                          color: c.mutedForeground,
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FindMoreCard extends StatelessWidget {
  const _FindMoreCard({required this.c});
  final SNColorTokens c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/home'),
      child: Container(
        decoration: BoxDecoration(
          color: c.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.border, width: 2, strokeAlign: BorderSide.strokeAlignInside),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 40, width: 40,
              decoration: BoxDecoration(
                color: c.card,
                shape: BoxShape.circle,
                border: Border.all(color: c.border),
              ),
              child: Icon(Icons.add_rounded, size: 24, color: c.primary),
            ),
            const SizedBox(height: SNSpace.x3),
            Text('FIND MORE',
              style: SNText.microAction.copyWith(
                color: c.mutedForeground,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
