import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:staynest_mobile/core/network/api_client.dart';

part 'ai_repository.g.dart';

class AiChatResponse {
  final String message;
  final List<dynamic>? hostels;
  AiChatResponse({required this.message, this.hostels});
}

@riverpod
AiRepository aiRepository(Ref ref) {
  return AiRepository(dio: ref.read(dioProvider));
}

class AiRepository {
  AiRepository({required this.dio});
  final Dio dio;

  Future<AiChatResponse> chat({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final res = await dio.post('/ai/chat', data: {
      'message': message,
      'history': history,
    });

    final data = res.data;
    return AiChatResponse(
      message: data['message'] as String,
      hostels: data['hostels'] as List<dynamic>?,
    );
  }
}
