// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_tracking_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ownerPaymentsHash() => r'owner_payments_provider_hash';

/// See also [ownerPayments].
@ProviderFor(ownerPayments)
final ownerPaymentsProvider =
    AutoDisposeFutureProvider<OwnerPaymentSummary>.internal(
  ownerPayments,
  name: r'ownerPaymentsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ownerPaymentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef OwnerPaymentsRef = AutoDisposeFutureProviderRef<OwnerPaymentSummary>;
