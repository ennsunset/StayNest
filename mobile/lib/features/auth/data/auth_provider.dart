// features/auth/data/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'auth_repository.dart';

part 'auth_provider.g.dart';

/// Holds the current user. null = not logged in.
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthUser? build() => null;

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String role = 'STUDENT',
    String? phone,
    String? university,
  }) async {
    final user = await _repo.register(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
      phone: phone,
      university: university,
    );
    state = user;
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final user = await _repo.login(email: email, password: password);
    state = user;
  }

  Future<void> updateProfile({String? fullName, String? phone, String? level, String? university}) async {
    final user = await _repo.updateProfile(fullName: fullName, phone: phone, level: level, university: university);
    state = user;
  }

  Future<void> logout() async {
    await _repo.logout();
    state = null;
  }
}
