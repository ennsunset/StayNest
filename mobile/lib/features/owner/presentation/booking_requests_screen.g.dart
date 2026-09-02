// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_requests_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _pendingBookingsHash() => r'pending_bookings_hash';

/// See also [pendingBookings].
@ProviderFor(pendingBookings)
final pendingBookingsProvider = AutoDisposeFutureProvider<List<OwnerBooking>>.internal(
  pendingBookings,
  name: r'pendingBookingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _pendingBookingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef PendingBookingsRef = AutoDisposeFutureProviderRef<List<OwnerBooking>>;
