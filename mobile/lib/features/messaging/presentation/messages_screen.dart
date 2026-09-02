import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/features/messaging/data/messaging_repository.dart';

final conversationsProvider = FutureProvider.autoDispose<List<ConversationSummary>>((ref) {
  return ref.read(messagingRepositoryProvider).getConversations();
});

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  late final _timer = Stream.periodic(const Duration(seconds: 10));

  @override
  void initState() {
    super.initState();
    _timer.listen((_) {
      if (mounted) ref.invalidate(conversationsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final c = context.sn;
    final convAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Messages', onBack: () => context.canPop() ? context.pop() : context.go('/')),
      body: convAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: SNEmptyState(
            icon: Icons.error_outline_rounded,
            headline: 'Could not load messages',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(conversationsProvider),
          ),
        ),
        data: (convs) {
          if (convs.isEmpty) {
            return Align(
              alignment: const Alignment(0, -0.5),
              child: SNEmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                headline: 'No messages yet',
                actionLabel: 'Browse Hostels',
                onAction: () => context.go('/home'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(conversationsProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: SNSpace.x4),
              itemCount: convs.length,
              separatorBuilder: (_, __) => Divider(height: 1, indent: SNSpace.screenX + 56 + SNSpace.x4, color: c.border),
              itemBuilder: (_, i) {
                final conv = convs[i];
                return _ConversationTile(conv: conv);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conv});
  final ConversationSummary conv;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/messages/${conv.id}', extra: conv.hostelName),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX, vertical: SNSpace.x4),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  conv.hostelName.substring(0, 2).toUpperCase(),
                  style: SNText.headingMd.copyWith(color: c.mutedForeground),
                ),
              ),
            ),
            const SizedBox(width: SNSpace.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv.hostelName,
                          style: SNText.bodyBold.copyWith(
                            color: c.foreground,
                            fontWeight: conv.unread > 0 ? FontWeight.w700 : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.lastMessageAt != null)
                        Text(
                          _timeAgo(conv.lastMessageAt!),
                          style: SNText.caption.copyWith(color: c.mutedForeground),
                        ),
                    ],
                  ),
                  const SizedBox(height: SNSpace.x1),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage ?? 'Start a conversation',
                          style: SNText.caption.copyWith(
                            color: conv.unread > 0 ? c.foreground : c.mutedForeground,
                            fontWeight: conv.unread > 0 ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: SNSpace.x2),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conv.unread}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}
