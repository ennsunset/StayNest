// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$roomWithBedsHash() => r'f13ef76fbf2e87c26712050c3709d59ff536d917';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Fetch room with beds — used by SelectBedScreen.
///
/// Copied from [roomWithBeds].
@ProviderFor(roomWithBeds)
const roomWithBedsProvider = RoomWithBedsFamily();

/// Fetch room with beds — used by SelectBedScreen.
///
/// Copied from [roomWithBeds].
class RoomWithBedsFamily extends Family<AsyncValue<RoomWithBeds>> {
  /// Fetch room with beds — used by SelectBedScreen.
  ///
  /// Copied from [roomWithBeds].
  const RoomWithBedsFamily();

  /// Fetch room with beds — used by SelectBedScreen.
  ///
  /// Copied from [roomWithBeds].
  RoomWithBedsProvider call(
    String roomId,
  ) {
    return RoomWithBedsProvider(
      roomId,
    );
  }

  @override
  RoomWithBedsProvider getProviderOverride(
    covariant RoomWithBedsProvider provider,
  ) {
    return call(
      provider.roomId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'roomWithBedsProvider';
}

/// Fetch room with beds — used by SelectBedScreen.
///
/// Copied from [roomWithBeds].
class RoomWithBedsProvider extends AutoDisposeFutureProvider<RoomWithBeds> {
  /// Fetch room with beds — used by SelectBedScreen.
  ///
  /// Copied from [roomWithBeds].
  RoomWithBedsProvider(
    String roomId,
  ) : this._internal(
          (ref) => roomWithBeds(
            ref as RoomWithBedsRef,
            roomId,
          ),
          from: roomWithBedsProvider,
          name: r'roomWithBedsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$roomWithBedsHash,
          dependencies: RoomWithBedsFamily._dependencies,
          allTransitiveDependencies:
              RoomWithBedsFamily._allTransitiveDependencies,
          roomId: roomId,
        );

  RoomWithBedsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.roomId,
  }) : super.internal();

  final String roomId;

  @override
  Override overrideWith(
    FutureOr<RoomWithBeds> Function(RoomWithBedsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RoomWithBedsProvider._internal(
        (ref) => create(ref as RoomWithBedsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        roomId: roomId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RoomWithBeds> createElement() {
    return _RoomWithBedsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomWithBedsProvider && other.roomId == roomId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, roomId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RoomWithBedsRef on AutoDisposeFutureProviderRef<RoomWithBeds> {
  /// The parameter `roomId` of this provider.
  String get roomId;
}

class _RoomWithBedsProviderElement
    extends AutoDisposeFutureProviderElement<RoomWithBeds>
    with RoomWithBedsRef {
  _RoomWithBedsProviderElement(super.provider);

  @override
  String get roomId => (origin as RoomWithBedsProvider).roomId;
}

String _$myBookingsHash() => r'181d2c3b8da81caa747dcf68b5098d45be38d282';

/// Fetch all bookings for the logged-in student — used by MyStaysScreen.
///
/// Copied from [myBookings].
@ProviderFor(myBookings)
final myBookingsProvider = AutoDisposeFutureProvider<List<Booking>>.internal(
  myBookings,
  name: r'myBookingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myBookingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MyBookingsRef = AutoDisposeFutureProviderRef<List<Booking>>;
String _$bookingDetailHash() => r'6871977ced77683a5ef45e6e95cbc03a4aedea60';

/// Fetch a single booking by ID.
///
/// Copied from [bookingDetail].
@ProviderFor(bookingDetail)
const bookingDetailProvider = BookingDetailFamily();

/// Fetch a single booking by ID.
///
/// Copied from [bookingDetail].
class BookingDetailFamily extends Family<AsyncValue<Booking>> {
  /// Fetch a single booking by ID.
  ///
  /// Copied from [bookingDetail].
  const BookingDetailFamily();

  /// Fetch a single booking by ID.
  ///
  /// Copied from [bookingDetail].
  BookingDetailProvider call(
    String bookingId,
  ) {
    return BookingDetailProvider(
      bookingId,
    );
  }

  @override
  BookingDetailProvider getProviderOverride(
    covariant BookingDetailProvider provider,
  ) {
    return call(
      provider.bookingId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookingDetailProvider';
}

/// Fetch a single booking by ID.
///
/// Copied from [bookingDetail].
class BookingDetailProvider extends AutoDisposeFutureProvider<Booking> {
  /// Fetch a single booking by ID.
  ///
  /// Copied from [bookingDetail].
  BookingDetailProvider(
    String bookingId,
  ) : this._internal(
          (ref) => bookingDetail(
            ref as BookingDetailRef,
            bookingId,
          ),
          from: bookingDetailProvider,
          name: r'bookingDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bookingDetailHash,
          dependencies: BookingDetailFamily._dependencies,
          allTransitiveDependencies:
              BookingDetailFamily._allTransitiveDependencies,
          bookingId: bookingId,
        );

  BookingDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookingId,
  }) : super.internal();

  final String bookingId;

  @override
  Override overrideWith(
    FutureOr<Booking> Function(BookingDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookingDetailProvider._internal(
        (ref) => create(ref as BookingDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookingId: bookingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Booking> createElement() {
    return _BookingDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingDetailProvider && other.bookingId == bookingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BookingDetailRef on AutoDisposeFutureProviderRef<Booking> {
  /// The parameter `bookingId` of this provider.
  String get bookingId;
}

class _BookingDetailProviderElement
    extends AutoDisposeFutureProviderElement<Booking> with BookingDetailRef {
  _BookingDetailProviderElement(super.provider);

  @override
  String get bookingId => (origin as BookingDetailProvider).bookingId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
