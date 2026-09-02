// features/discovery/data/featured_hostels_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'hostels_repository.dart';
import '../../auth/data/auth_provider.dart';

part 'featured_hostels_provider.g.dart';

@riverpod
Future<List<Hostel>> featuredHostels(Ref ref) async {
  final repo = ref.read(hostelsRepositoryProvider);
  final user = ref.watch(authNotifierProvider);
  return repo.fetchFeatured(university: user?.university);
}
