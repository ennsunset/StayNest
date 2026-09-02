// features/booking/data/bookings_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'bookings_repository.dart';

part 'bookings_provider.g.dart';

/// Fetch room with beds — used by SelectBedScreen.
@riverpod
Future<RoomWithBeds> roomWithBeds(Ref ref, String roomId) async {
  final repo = ref.read(bookingsRepositoryProvider);
  return repo.fetchRoomWithBeds(roomId);
}

/// Fetch all bookings for the logged-in student — used by MyStaysScreen.
@riverpod
Future<List<Booking>> myBookings(Ref ref) async {
  final repo = ref.read(bookingsRepositoryProvider);
  return repo.fetchMine();
}

/// Fetch a single booking by ID.
@riverpod
Future<Booking> bookingDetail(Ref ref, String bookingId) async {
  final repo = ref.read(bookingsRepositoryProvider);
  return repo.fetchById(bookingId);
}
