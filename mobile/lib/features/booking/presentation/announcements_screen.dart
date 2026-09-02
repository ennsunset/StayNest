import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/network/api_client.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key, required this.hostelId, required this.hostelName});
  final String hostelId;
  final String hostelName;

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/announcements/${widget.hostelId}');
      if (mounted) setState(() { _announcements = List<Map<String, dynamic>>.from(res.data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Announcements', onBack: () => context.pop()),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: [SizedBox(height: MediaQuery.of(context).size.height * 0.25), _emptyState(c)],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(SNSpace.screenX),
                    itemCount: _announcements.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _announcementCard(c, _announcements[i]),
                  ),
                ),
    );
  }

  Widget _emptyState(SNColorTokens c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SNSpace.screenX),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle),
              child: Icon(Icons.campaign_outlined, size: 36, color: c.mutedForeground),
            ),
            const SizedBox(height: 20),
            Text('No announcements', style: SNText.headingMd.copyWith(color: c.foreground)),
            const SizedBox(height: 8),
            Text('Your hostel management hasn\'t posted any announcements yet.',
              style: SNText.body.copyWith(color: c.mutedForeground), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _announcementCard(SNColorTokens c, Map<String, dynamic> ann) {
    final priority = ann['priority'] as String? ?? 'NORMAL';
    final isUrgent = priority == 'URGENT';
    final isImportant = priority == 'IMPORTANT';
    final timeAgo = _timeAgo(ann['created_at']);

    Color accentColor;
    IconData icon;
    if (isUrgent) {
      accentColor = const Color(0xFFDC3545);
      icon = Icons.warning_amber_rounded;
    } else if (isImportant) {
      accentColor = const Color(0xFFE8A33D);
      icon = Icons.priority_high_rounded;
    } else {
      accentColor = c.primary;
      icon = Icons.campaign_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(SNRadius.md),
        border: Border.all(color: isUrgent ? accentColor.withOpacity(0.3) : c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority bar
          if (isUrgent || isImportant)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    priority,
                    style: SNText.sectionLabel.copyWith(color: accentColor, fontSize: 10),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(SNSpace.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUrgent && !isImportant)
                      Padding(
                        padding: const EdgeInsets.only(right: 10, top: 2),
                        child: Icon(icon, size: 20, color: accentColor),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ann['title'] ?? '', style: SNText.bodyBold.copyWith(color: c.foreground)),
                          const SizedBox(height: 8),
                          Text(ann['body'] ?? '', style: SNText.body.copyWith(color: c.mutedForeground, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: c.mutedForeground),
                    const SizedBox(width: 4),
                    Text(ann['author_name'] ?? 'Management', style: SNText.caption.copyWith(color: c.mutedForeground)),
                    const Spacer(),
                    Text(timeAgo, style: SNText.caption.copyWith(color: c.mutedForeground)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}';
  }
}
