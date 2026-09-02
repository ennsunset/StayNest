// features/discovery/data/hostels_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:staynest_mobile/core/network/api_client.dart';

part 'hostels_repository.g.dart';

List<String> _parseHouseRules(dynamic val) {
  if (val is List) return val.cast<String>();
  if (val is String && val.trim().isNotEmpty) {
    try {
      return (val.startsWith('[')) ? List<String>.from(val.split(',')) : val.split('\n').where((r) => r.trim().isNotEmpty).toList();
    } catch (_) {
      return [val];
    }
  }
  return [];
}

class Hostel {
  Hostel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.description,
    this.genderPolicy,
    this.bookingMode = 'FLEXIBLE',
    this.verified = false,
    this.amenities = const [],
    this.location,
    this.imageUrls = const [],
    this.ownerId,
    this.gateOpeningTime,
    this.gateClosingTime,
    this.cancellationPolicy,
    this.houseRules = const [],
    this.latitude,
    this.longitude,
    this.averageRating,
    this.reviewCount,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final String? description;
  final String? genderPolicy;
  final String bookingMode;
  final bool verified;
  final List<HostelAmenity> amenities;
  final HostelLocation? location;
  final List<String> imageUrls;
  final String? ownerId;
  final String? gateOpeningTime;
  final String? gateClosingTime;
  final String? cancellationPolicy;
  final List<String> houseRules;
  final double? latitude;
  final double? longitude;
  final double? averageRating;
  final int? reviewCount;
  late List<RoomSummary> rooms;

  /// Cheapest room price — computed from rooms if available,
  /// otherwise 0 (to be filled by a separate call).
  late int fromPricePesewas;

  factory Hostel.fromJson(Map<String, dynamic> json) {
    final h = Hostel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      description: json['description'] as String?,
      genderPolicy: json['genderPolicy'] as String?,
      bookingMode: json['bookingMode'] as String? ?? json['booking_mode'] as String? ?? 'FLEXIBLE',
      verified: json['verified'] as bool? ?? false,
      ownerId: json['ownerId'] as String?,
      gateOpeningTime: json['gateOpeningTime'] as String?,
      gateClosingTime: json['gateClosingTime'] as String?,
      cancellationPolicy: json['cancellationPolicy'] as String?,
      houseRules: _parseHouseRules(json['houseRules']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? (json['average_rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? (json['review_count'] as num?)?.toInt(),
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((a) => HostelAmenity.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      location: json['location'] != null
          ? HostelLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
    // Compute from nested buildings > floors > rooms if available, otherwise use server-computed value
    int minPrice = (json['fromPricePesewas'] as num?)?.toInt() ?? 0;
    if (minPrice == 0 && json['buildings'] != null) {
      for (final b in json['buildings'] as List<dynamic>) {
        for (final f in (b['floors'] ?? []) as List<dynamic>) {
          for (final r in (f['rooms'] ?? []) as List<dynamic>) {
            final raw = r['pricePesewas'] ?? r['price_pesewas'];
            final p = raw is num ? raw.toInt() : (raw is String ? int.tryParse(raw) ?? 0 : 0);
            if (p > 0 && (minPrice == 0 || p < minPrice)) minPrice = p;
          }
        }
      }
    }
    h.fromPricePesewas = minPrice;

    // Extract room summaries from nested buildings > floors > rooms
    final roomList = <RoomSummary>[];
    if (json['buildings'] != null) {
      for (final b in json['buildings'] as List<dynamic>) {
        for (final f in (b['floors'] ?? []) as List<dynamic>) {
          for (final r in (f['rooms'] ?? []) as List<dynamic>) {
            final rawPrice = r['pricePesewas'] ?? r['price_pesewas'];
            final price = rawPrice is num ? rawPrice.toInt() : (rawPrice is String ? int.tryParse(rawPrice) ?? 0 : 0);
            final beds = (r['beds'] ?? []) as List<dynamic>;
            final available = beds.where((bd) => bd['status'] == 'AVAILABLE').length;
            final roomImages = (r['imageUrls'] as List<dynamic>?)
                    ?.map((e) => e as String).toList()
                ?? (r['image_urls'] as List<dynamic>?)
                    ?.map((e) => e as String).toList()
                ?? [];
            roomList.add(RoomSummary(
              id: r['id'] as String,
              number: r['number'] as String,
              type: r['type'] as String,
              pricePesewas: price,
              availableBeds: available,
              totalBeds: beds.length,
              imageUrls: roomImages,
              securityDepositPesewas: int.tryParse((r['securityDepositPesewas'] ?? r['security_deposit_pesewas'] ?? '0').toString()) ?? 0
                  ?? (r['security_deposit_pesewas'] as num?)?.toInt()
                  ?? 0,
            ));
          }
        }
      }
    }
    h.rooms = roomList;
    return h;
  }
}

class HostelAmenity {
  HostelAmenity({required this.id, required this.name, this.icon});

  final String id;
  final String name;
  final String? icon;

  factory HostelAmenity.fromJson(Map<String, dynamic> json) {
    return HostelAmenity(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
    );
  }
}

class HostelLocation {
  HostelLocation({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;

  factory HostelLocation.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as List<dynamic>;
    return HostelLocation(
      longitude: (coords[0] as num).toDouble(),
      latitude: (coords[1] as num).toDouble(),
    );
  }
}

class RoomSummary {
  RoomSummary({
    required this.id,
    required this.number,
    required this.type,
    required this.pricePesewas,
    required this.availableBeds,
    required this.totalBeds,
    this.imageUrls = const [],
    this.securityDepositPesewas = 0,
  });

  final String id;
  final String number;
  final String type;
  final int pricePesewas;
  final int availableBeds;
  final int totalBeds;
  final List<String> imageUrls;
  final int securityDepositPesewas;

  String get tag => type == '1-in-a-room' ? 'PREMIUM' : null.toString();
  bool get hasPremiumTag => type == '1-in-a-room';
}

@riverpod
HostelsRepository hostelsRepository(Ref ref) {
  return HostelsRepository(dio: ref.read(dioProvider));
}

class HostelsRepository {
  HostelsRepository({required this.dio});
  final Dio dio;

  Future<List<Hostel>> fetchFeatured({String? university}) async {
    final res = await dio.get('/hostels/featured', queryParameters: {
      if (university != null) 'university': university,
    });
    final list = res.data as List<dynamic>;
    return list
        .map((j) => Hostel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<Hostel>> search({
    int page = 1,
    int limit = 50,
    String? query,
  }) async {
    final res = await dio.get('/hostels/search', queryParameters: {
      'page': page,
      if (query != null && query.isNotEmpty) 'q': query,
      'limit': limit,
    });
    final data = res.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((j) => Hostel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<Hostel>> searchFiltered({
    int page = 1,
    int limit = 50,
    String? query,
    String? sort,
    int? minPricePesewas,
    int? maxPricePesewas,
    String? roomType,
    List<String>? amenities,
    String? genderPolicy,
    String? university,
    double? lat,
    double? lng,
    double? radiusKm,
  }) async {
    final res = await dio.get('/hostels/search', queryParameters: {
      'page': page,
      'limit': limit,
      if (query != null && query.isNotEmpty) 'q': query,
      if (sort != null) 'sort': sort,
      if (minPricePesewas != null) 'minPrice': minPricePesewas,
      if (maxPricePesewas != null) 'maxPrice': maxPricePesewas,
      if (roomType != null) 'roomType': roomType,
      if (amenities != null && amenities.isNotEmpty) 'amenities': amenities,
      if (genderPolicy != null) 'genderPolicy': genderPolicy,
      if (university != null) 'university': university,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radiusKm != null) 'radiusKm': radiusKm,
    });
    final data = res.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list.map((j) => Hostel.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Returns the count of hostels matching the given filters (no full data fetch).
  Future<int> searchCount({
    int? minPricePesewas,
    int? maxPricePesewas,
    String? roomType,
    List<String>? amenities,
    String? university,
  }) async {
    final res = await dio.get('/hostels/search/count', queryParameters: {
      if (minPricePesewas != null) 'minPrice': minPricePesewas,
      if (maxPricePesewas != null) 'maxPrice': maxPricePesewas,
      if (roomType != null) 'roomType': roomType,
      if (amenities != null && amenities.isNotEmpty) 'amenities': amenities,
      if (university != null) 'university': university,
    });
    final data = res.data as Map<String, dynamic>;
    return (data['count'] as num).toInt();
  }

  Future<Hostel> fetchById(String id) async {
    final res = await dio.get('/hostels/$id');
    return Hostel.fromJson(res.data as Map<String, dynamic>);
  }
}
