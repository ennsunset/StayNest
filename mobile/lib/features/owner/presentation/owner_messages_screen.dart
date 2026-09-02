import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/features/messaging/data/messaging_repository.dart';

final ownerConversationsProvider = FutureProvider.autoDispose<List<ConversationSummary>>((ref) {
  return ref.read(messagingRepositoryProvider).getConversations(role: 'OWNER');
});

class OwnerMessagesScreen extends ConsumerStatefulWidget {
  const OwnerMessagesScreen({super.key});

  @override
  ConsumerState<OwnerMessagesScreen> createState() => _OwnerMessagesScreenState();
}

class _OwnerMessagesScreenState extends ConsumerState<OwnerMessagesScreen> {
  late final _timer = Stream.periodic(const Duration(seconds: 10));

  @override
  void initState() {
    super.initState();
    _timer.listen((_) {
      if (mounted) ref.invalidate(ownerConversationsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final c = context.sn;
    final convAsync = ref.watch(ownerConversationsProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Messages',
          style: SNText.headingMd.copyWith(color: c.foreground),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
      ),
      body: convAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: SNEmptyState(
            icon: Icons.error_outline_rounded,
            headline: 'Could not load messages',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(ownerConversationsProvider),
          ),
        ),
        data: (convs) {
          if (convs.isEmpty) {
            return Align(
              alignment: const Alignment(0, -0.3),
              child: SNEmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                headline: 'No messages yet',
                actionLabel: 'Go to Dashboard',
                onAction: () => {},
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ownerConversationsProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: SNSpace.x4),
              itemCount: convs.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: SNSpace.screenX + 56 + SNSpace.x4,
                color: c.border,
              ),
              itemBuilder: (_, i) {
                final conv = convs[i];
                return Dismissible(
                  key: ValueKey(conv.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: SNSpace.x5),
                    color: Colors.red,
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete conversation?'),
                        content: const Text('This will permanently delete all messages.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ) ?? false;
                    if (confirmed) {
                      try {
                        await ref.read(messagingRepositoryProvider).deleteConversation(conv.id);
                      } catch (_) {}
                      ref.invalidate(ownerConversationsProvider);
                    }
                    return false;
                  },
                  child: _OwnerConversationTile(conv: conv),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _OwnerConversationTile extends StatelessWidget {
  const _OwnerConversationTile({required this.conv});
  final ConversationSummary conv;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/messages/${conv.id}', extra: {'hostelName': conv.studentName ?? 'Student', 'userId': conv.ownerId}),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX, vertical: SNSpace.x4),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.person_outline_rounded, size: 28),
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
                          conv.studentName ?? 'Student',
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
                  const SizedBox(height: 2),
                  Text(
                    conv.hostelName,
                    style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: SNSpace.x1),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage ?? 'No messages yet',
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
