import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:staynest_mobile/core/network/api_client.dart';

part 'notifications_repository.g.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      title: json['title'],
      body: json['body'],
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

@riverpod
NotificationsRepository notificationsRepository(Ref ref) {
  return NotificationsRepository(dio: ref.read(dioProvider));
}

final notificationsProvider = FutureProvider.autoDispose<({List<AppNotification> data, int unread})>((ref) async {
  final repo = ref.read(notificationsRepositoryProvider);
  return repo.getNotifications();
});

final unreadNotificationsProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.read(notificationsRepositoryProvider);
  return repo.getUnreadCount();
});

class NotificationsRepository {
  NotificationsRepository({required this.dio});
  final Dio dio;

  Future<({List<AppNotification> data, int unread})> getNotifications({int page = 1}) async {
    final res = await dio.get('/notifications', queryParameters: {'page': page});
    final list = (res.data['data'] as List).map((j) => AppNotification.fromJson(j)).toList();
    final unread = res.data['unread'] as int? ?? 0;
    return (data: list, unread: unread);
  }

  Future<int> getUnreadCount() async {
    final res = await dio.get('/notifications/unread-count');
    return res.data['count'] as int? ?? 0;
  }

  Future<void> markAsRead(String id) async {
    await dio.patch('/notifications/$id/read');
  }

  Future<void> deleteNotification(String id) async {
    await dio.delete('/notifications/$id');
  }

  Future<void> markAllAsRead() async {
    await dio.patch('/notifications/read-all');
  }
}
