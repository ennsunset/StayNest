// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refund_timeline_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$refundStatusHash() => r'468e467449f90947870daf89ecc62175ca827f1a';

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

/// See also [refundStatus].
@ProviderFor(refundStatus)
const refundStatusProvider = RefundStatusFamily();

/// See also [refundStatus].
class RefundStatusFamily extends Family<AsyncValue<RefundStatus?>> {
  /// See also [refundStatus].
  const RefundStatusFamily();

  /// See also [refundStatus].
  RefundStatusProvider call(
    String bookingId,
  ) {
    return RefundStatusProvider(
      bookingId,
    );
  }

  @override
  RefundStatusProvider getProviderOverride(
    covariant RefundStatusProvider provider,
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
  String? get name => r'refundStatusProvider';
}

/// See also [refundStatus].
class RefundStatusProvider extends AutoDisposeFutureProvider<RefundStatus?> {
  /// See also [refundStatus].
  RefundStatusProvider(
    String bookingId,
  ) : this._internal(
          (ref) => refundStatus(
            ref as RefundStatusRef,
            bookingId,
          ),
          from: refundStatusProvider,
          name: r'refundStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$refundStatusHash,
          dependencies: RefundStatusFamily._dependencies,
          allTransitiveDependencies:
              RefundStatusFamily._allTransitiveDependencies,
          bookingId: bookingId,
        );

  RefundStatusProvider._internal(
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
    FutureOr<RefundStatus?> Function(RefundStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RefundStatusProvider._internal(
        (ref) => create(ref as RefundStatusRef),
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
  AutoDisposeFutureProviderElement<RefundStatus?> createElement() {
    return _RefundStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RefundStatusProvider && other.bookingId == bookingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RefundStatusRef on AutoDisposeFutureProviderRef<RefundStatus?> {
  /// The parameter `bookingId` of this provider.
  String get bookingId;
}

class _RefundStatusProviderElement
    extends AutoDisposeFutureProviderElement<RefundStatus?>
    with RefundStatusRef {
  _RefundStatusProviderElement(super.provider);

  @override
  String get bookingId => (origin as RefundStatusProvider).bookingId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
