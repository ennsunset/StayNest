import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/features/account/data/notifications_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Notifications',
        onBack: () => context.pop(),
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: SNEmptyState(
            icon: Icons.error_outline_rounded,
            headline: 'Could not load notifications',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(notificationsProvider),
          ),
        ),
        data: (result) {
          if (result.data.isEmpty) {
            return Align(
              alignment: const Alignment(0, -0.3),
              child: SNEmptyState(
                icon: Icons.notifications_none_rounded,
                headline: 'No notifications yet',
                actionLabel: 'Back',
                onAction: () => context.pop(),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationsProvider);
            },
            child: Column(
              children: [
                if (result.unread > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX, vertical: SNSpace.x3),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () async {
                          await ref.read(notificationsRepositoryProvider).markAllAsRead();
                          ref.invalidate(notificationsProvider);
                          ref.invalidate(unreadNotificationsProvider);
                        },
                        child: Text('Mark all as read', style: SNText.caption.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                Expanded(child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX, vertical: SNSpace.x4),
              itemCount: result.data.length,
              itemBuilder: (_, i) {
                final notif = result.data[i];
                // Day group header
                Widget? header;
                final label = _dayLabel(notif.createdAt);
                if (i == 0 || _dayLabel(result.data[i - 1].createdAt) != label) {
                  header = Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : SNSpace.x5, bottom: SNSpace.x3),
                    child: Text(label, style: SNText.microAction.copyWith(
                      color: c.mutedForeground, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (header != null) header,
                    Dismissible(
                      key: ValueKey(notif.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        await ref.read(notificationsRepositoryProvider).deleteNotification(notif.id);
                        ref.invalidate(notificationsProvider);
                        ref.invalidate(unreadNotificationsProvider);
                        return false;
                      },
                      child: _NotificationTile(
                        notif: notif,
                        onTap: () async {
                          if (!notif.isRead) {
                            await ref.read(notificationsRepositoryProvider).markAsRead(notif.id);
                            ref.invalidate(notificationsProvider);
                            ref.invalidate(unreadNotificationsProvider);
                          }
                          final data = notif.data;
                          if (data != null && context.mounted) {
                            if (data['bookingId'] != null) {
                              context.push('/booking/${data['bookingId']}');
                            } else if (data['conversationId'] != null) {
                              context.push('/messages/${data['conversationId']}', extra: {'hostelName': data['hostelName'] ?? 'Chat'});
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            )),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'TODAY';
    if (d == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    if (now.difference(dt).inDays < 7) return '${now.difference(dt).inDays} DAYS AGO';
    return 'EARLIER';
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notif, required this.onTap});
  final AppNotification notif;
  final VoidCallback onTap;

  IconData get _icon {
    switch (notif.type) {
      case 'BOOKING_CONFIRMED': return Icons.check_circle_outline_rounded;
      case 'BOOKING_CANCELLED': return Icons.cancel_outlined;
      case 'NEW_MESSAGE': return Icons.chat_bubble_outline_rounded;
      case 'PAYMENT_RECEIVED': return Icons.payments_outlined;
      case 'BOOKING_REQUEST': return Icons.pending_actions_rounded;
      default: return Icons.notifications_outlined;
    }
  }

  Color _iconColor(SNColorTokens c) {
    switch (notif.type) {
      case 'BOOKING_CONFIRMED': return Colors.green;
      case 'BOOKING_CANCELLED': return Colors.red;
      case 'NEW_MESSAGE': return c.primary;
      case 'PAYMENT_RECEIVED': return Colors.green;
      case 'BOOKING_REQUEST': return Colors.orange;
      default: return c.mutedForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? c.card : c.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: notif.isRead ? c.border : c.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _iconColor(c).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Icon(_icon, size: 24, color: _iconColor(c))),
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
                          notif.title,
                          style: SNText.bodyBold.copyWith(
                            color: c.foreground,
                            fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(_timeAgo(notif.createdAt), style: SNText.caption.copyWith(color: c.mutedForeground)),
                    ],
                  ),
                  const SizedBox(height: SNSpace.x1),
                  Text(
                    notif.body,
                    style: SNText.caption.copyWith(
                      color: notif.isRead ? c.mutedForeground : c.foreground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                margin: const EdgeInsets.only(left: SNSpace.x2, top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
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
