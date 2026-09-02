// features/auth/data/auth_repository.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:staynest_mobile/core/network/api_client.dart';
import 'package:staynest_mobile/core/network/token_storage.dart';

part 'auth_repository.g.dart';

class AuthUser {
  AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.university,
    this.level,
    this.avatarUrl,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.idVerified = false,
    this.profileCompleted = false,
    this.interests = const [],
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? university;
  final String? level;
  final String? avatarUrl;
  final bool emailVerified;
  final bool phoneVerified;
  final bool idVerified;
  final bool profileCompleted;
  final List<String> interests;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      university: json['university'] as String?,
      level: json['level'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      idVerified: json['idVerified'] as bool? ?? false,
      profileCompleted: json['profileCompleted'] as bool? ?? false,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

class VerificationStatus {
  final bool phoneVerified;
  final bool emailVerified;
  final bool profileCompleted;
  final String? phone;
  final String? email;

  VerificationStatus({
    required this.phoneVerified,
    required this.emailVerified,
    required this.profileCompleted,
    this.phone,
    this.email,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      emailVerified: json['emailVerified'] as bool? ?? false,
      profileCompleted: json['profileCompleted'] as bool? ?? false,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    dio: ref.read(dioProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
}

class AuthRepository {
  AuthRepository({required this.dio, required this.tokenStorage});

  final Dio dio;
  final TokenStorage tokenStorage;

  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
    String role = 'STUDENT',
    String? phone,
    String? university,
    String? level,
  }) async {
    final res = await dio.post('/auth/register', data: {
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role,
      if (phone != null) 'phone': phone,
      if (university != null) 'university': university,
      if (level != null) 'level': level,
    });

    final data = res.data as Map<String, dynamic>;
    await _saveTokens(data['tokens']);
    return AuthUser.fromJson(data['user']);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final res = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final data = res.data as Map<String, dynamic>;
    await _saveTokens(data['tokens']);
    return AuthUser.fromJson(data['user']);
  }

  Future<AuthUser> socialLogin({
    required String provider,
    required String idToken,
    String? fullName,
  }) async {
    final res = await dio.post('/auth/social', data: {
      'provider': provider,
      'idToken': idToken,
      if (fullName != null) 'fullName': fullName,
    });

    final data = res.data as Map<String, dynamic>;
    await _saveTokens(data['tokens']);
    return AuthUser.fromJson(data['user']);
  }

  Future<AuthUser> updateProfile({String? fullName, String? phone, String? level, String? university}) async {
    final res = await dio.patch("/auth/profile", data: {
      if (fullName != null) "fullName": fullName,
      if (phone != null) "phone": phone,
      if (level != null) "level": level,
      if (university != null) "university": university,
    });
    return AuthUser.fromJson(res.data as Map<String, dynamic>);
  }

  Future<String> uploadAvatar(File imageFile) async {
    final fileName = imageFile.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
    });
    final res = await dio.post('/media/upload?folder=avatars', data: formData);
    final url = res.data['url'] as String;
    await dio.patch('/auth/profile', data: {'avatarUrl': url});
    return url;
  }

  Future<void> logout() async {
    await tokenStorage.clear();
  }

  Future<bool> isLoggedIn() => tokenStorage.hasTokens();

  // ── OTP ──

  Future<void> sendOtp({required String type, String? phone}) async {
    await dio.post('/auth/otp/send', data: {
      'type': type,
      if (phone != null) 'phone': phone,
    });
  }

  Future<void> verifyOtp({required String type, required String code}) async {
    await dio.post('/auth/otp/verify', data: {
      'type': type,
      'code': code,
    });
  }

  // ── Profile ──

  Future<void> completeProfile({
    String? university,
    String? level,
    List<String>? interests,
  }) async {
    await dio.patch('/auth/complete-profile', data: {
      if (university != null) 'university': university,
      if (level != null) 'level': level,
      if (interests != null) 'interests': interests,
    });
  }

  Future<VerificationStatus> getVerificationStatus() async {
    final res = await dio.get('/auth/verification-status');
    return VerificationStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> _saveTokens(Map<String, dynamic> tokens) async {
    await tokenStorage.saveTokens(
      tokens['accessToken'] as String,
      tokens['refreshToken'] as String,
    );
  }
}
