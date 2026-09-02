import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:staynest_mobile/core/network/api_client.dart';

part 'messaging_repository.g.dart';

class ConversationSummary {
  final String id;
  final String? hostelId;
  final String hostelName;
  final String? studentId;
  final String? ownerId;
  final String? studentName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unread;

  ConversationSummary({
    required this.id,
    this.hostelId,
    required this.hostelName,
    this.studentId,
    this.ownerId,
    this.studentName,
    this.lastMessage,
    this.lastMessageAt,
    this.unread = 0,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'],
      hostelId: json['hostelId'],
      hostelName: json['hostelName'] ?? 'Unknown Hostel',
      studentId: json['studentId'],
      ownerId: json['ownerId'],
      studentName: json['studentName'],
      lastMessage: json['lastMessage'],
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.parse(json['lastMessageAt']) : null,
      unread: json['unread'] ?? 0,
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversationId'],
      senderId: json['senderId'],
      body: json['body'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

@riverpod
MessagingRepository messagingRepository(Ref ref) {
  return MessagingRepository(dio: ref.read(dioProvider));
}

class MessagingRepository {
  MessagingRepository({required this.dio});
  final Dio dio;

  Future<List<ConversationSummary>> getConversations({String role = 'STUDENT'}) async {
    print("CONV CALL role=$role");
    final res = await dio.get('/messaging/conversations', queryParameters: {'role': role});
    return (res.data as List).map((j) => ConversationSummary.fromJson(j)).toList();
  }

  Future<ConversationSummary> getOrCreateConversation({
    required String hostelId,
    required String ownerId,
  }) async {
    final res = await dio.post('/messaging/conversations', data: {
      'hostelId': hostelId,
      'ownerId': ownerId,
    });
    return ConversationSummary.fromJson(res.data);
  }

  Future<ConversationSummary> getOrCreateDM(String peerId) async {
    final res = await dio.post('/messaging/conversations/direct', data: {
      'peerId': peerId,
    });
    return ConversationSummary.fromJson(res.data);
  }

  Future<List<ChatMessage>> getMessages(String conversationId, {int page = 1}) async {
    final res = await dio.get('/messaging/conversations/$conversationId/messages', queryParameters: {'page': page});
    final data = res.data;
    final list = data is Map ? data['data'] as List : data as List;
    return list.map((j) => ChatMessage.fromJson(j)).toList();
  }

  Future<void> deleteConversation(String conversationId) async {
    await dio.delete('/messaging/conversations/$conversationId');
  }

  Future<ChatMessage> sendMessage(String conversationId, String body) async {
    final res = await dio.post('/messaging/conversations/$conversationId/messages', data: {'body': body});
    return ChatMessage.fromJson(res.data);
  }
}
