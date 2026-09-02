// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_management_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _ownerTenantsHash() => r'owner_tenants_hash';

/// See also [ownerTenants].
@ProviderFor(ownerTenants)
final ownerTenantsProvider = AutoDisposeFutureProvider<List<OwnerTenant>>.internal(
  ownerTenants,
  name: r'ownerTenantsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _ownerTenantsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef OwnerTenantsRef = AutoDisposeFutureProviderRef<List<OwnerTenant>>;
