// features/owner/data/owner_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:staynest_mobile/core/network/api_client.dart';

part 'owner_repository.g.dart';

// ── Models ──

class OwnerDashboard {
  OwnerDashboard({
    required this.occupancyRate,
    required this.totalRevenue,
    required this.netRevenue,
    required this.thisMonthRevenue,
    required this.pendingRequests,
    required this.maintenanceCount,
    required this.activeHostels,
  });

  final double occupancyRate;
  final int totalRevenue;
  final int netRevenue;
  final int thisMonthRevenue;
  final int pendingRequests;
  final int maintenanceCount;
  final int activeHostels;

  factory OwnerDashboard.fromJson(Map<String, dynamic> json) {
    return OwnerDashboard(
      occupancyRate: ((json['occupancy'] as Map<String, dynamic>?)?['rate'] as num?)?.toDouble() ?? 0,
      totalRevenue: _safeInt(json['totalRevenue']),
      netRevenue: _safeInt((json['revenue'] as Map<String, dynamic>?)?['netPesewas'] ?? 0),
      thisMonthRevenue: _safeInt(json['thisMonthRevenue']),
      pendingRequests: _safeInt(json['pendingRequests']),
      maintenanceCount: _safeInt(json['maintenanceCount']),
      activeHostels: _safeInt(json['activeHostels']),
    );
  }
}

class OwnerBooking {
  OwnerBooking({
    required this.id,
    required this.reference,
    required this.status,
    required this.studentName,
    required this.studentEmail,
    required this.hostelName,
    required this.roomNumber,
    required this.roomType,
    required this.bedLabel,
    required this.pricePesewas,
    required this.createdAt,
    this.reason,
  });

  final String id;
  final String reference;
  final String status;
  final String studentName;
  final String studentEmail;
  final String hostelName;
  final String roomNumber;
  final String roomType;
  final String bedLabel;
  final int pricePesewas;
  final String createdAt;
  final String? reason;

  factory OwnerBooking.fromJson(Map<String, dynamic> json) {
    return OwnerBooking(
      id: json['id'] as String,
      reference: json['reference'] as String? ?? '',
      status: json['status'] as String,
      studentName: (json['student'] is Map ? json['student']['name'] : json['studentName']) as String? ?? 'Unknown',
      studentEmail: (json['student'] is Map ? json['student']['email'] : json['studentEmail']) as String? ?? '',
      hostelName: json['hostelName'] as String? ?? '',
      roomNumber: json['room'] as String? ?? json['roomNumber'] as String? ?? '',
      roomType: json['roomType'] as String? ?? '',
      bedLabel: json['bed'] as String? ?? json['bedLabel'] as String? ?? '',
      pricePesewas: _safeInt(json['pricePesewas']),
      createdAt: json['createdAt'] as String? ?? '',
      reason: json['reason'] as String?,
    );
  }
}

class OwnerTenant {
  OwnerTenant({
    required this.bookingId,
    required this.studentName,
    required this.studentEmail,
    required this.hostelName,
    required this.roomNumber,
    required this.bedLabel,
    required this.status,
    required this.pricePesewas,
    this.paymentStatus,
  });

  final String bookingId;
  final String studentName;
  final String studentEmail;
  final String hostelName;
  final String roomNumber;
  final String bedLabel;
  final String status;
  final int pricePesewas;
  final String? paymentStatus;

  factory OwnerTenant.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] as Map<String, dynamic>?;
    return OwnerTenant(
      bookingId: booking?['id'] as String? ?? json['bookingId'] as String? ?? json['id'] as String? ?? '',
      studentName: json['fullName'] as String? ?? json['studentName'] as String? ?? 'Unknown',
      studentEmail: json['email'] as String? ?? json['studentEmail'] as String? ?? '',
      hostelName: json['hostelName'] as String? ?? '',
      roomNumber: json['room'] as String? ?? json['roomNumber'] as String? ?? '',
      bedLabel: json['bed'] as String? ?? json['bedLabel'] as String? ?? '',
      status: booking?['status'] as String? ?? json['status'] as String? ?? '',
      pricePesewas: _safeInt(booking?['totalPesewas'] ?? json['pricePesewas']),
      paymentStatus: json['paymentStatus'] as String?,
    );
  }
}

class OwnerPaymentSummary {
  OwnerPaymentSummary({
    required this.totalSettled,
    required this.totalPending,
    required this.thisMonth,
    required this.totalCommission,
    required this.payments,
  });

  final int totalSettled;
  final int totalPending;
  final int thisMonth;
  final int totalCommission;
  final List<OwnerPayment> payments;

  factory OwnerPaymentSummary.fromJson(Map<String, dynamic> json) {
    return OwnerPaymentSummary(
      totalSettled: _safeInt(json['totalSettled']),
      totalPending: _safeInt(json['totalPending']),
      thisMonth: _safeInt(json['thisMonth']),
      totalCommission: _safeInt(json['totalCommission']),
      payments: (json['payments'] as List<dynamic>?)
              ?.map((p) => OwnerPayment.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OwnerPayment {
  OwnerPayment({
    required this.id,
    required this.reference,
    required this.amount,
    required this.commission,
    required this.netAmount,
    required this.status,
    required this.studentName,
    required this.hostelName,
    required this.createdAt,
  });

  final String id;
  final String reference;
  final int amount;
  final int commission;
  final int netAmount;
  final String status;
  final String studentName;
  final String hostelName;
  final String createdAt;

  factory OwnerPayment.fromJson(Map<String, dynamic> json) {
    return OwnerPayment(
      id: json['id'] as String,
      reference: json['reference'] as String? ?? '',
      amount: _safeInt(json['amount']),
      commission: _safeInt(json['commission']),
      netAmount: _safeInt(json['netAmount']),
      status: json['status'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      hostelName: json['hostelName'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}


class OwnerRoom {
  OwnerRoom({
    required this.id,
    required this.number,
    required this.type,
    required this.pricePesewas,
    required this.hasAC,
    required this.hasPrivateBath,
    required this.hasFan,
    required this.hasTV,
    required this.socketCount,
    required this.floorLabel,
    required this.totalBeds,
    required this.occupiedBeds,
    required this.dominantStatus,
  });

  final String id;
  final String number;
  final String type;
  final int pricePesewas;
  final bool hasAC;
  final bool hasPrivateBath;
  final bool hasFan;
  final bool hasTV;
  final int socketCount;
  final String floorLabel;
  final int totalBeds;
  final int occupiedBeds;
  final String dominantStatus;

  factory OwnerRoom.fromJson(Map<String, dynamic> json) {
    return OwnerRoom(
      id: json['id'] as String,
      number: json['number'] as String? ?? '',
      type: json['type'] as String? ?? '',
      pricePesewas: _safeInt(json['pricePesewas']),
      hasAC: json['hasAC'] as bool? ?? false,
      hasPrivateBath: json['hasPrivateBath'] as bool? ?? false,
      hasFan: json['hasFan'] as bool? ?? false,
      hasTV: json['hasTV'] as bool? ?? false,
      socketCount: _safeInt(json['socketCount'] ?? 1),
      floorLabel: json['floorLabel'] as String? ?? '',
      totalBeds: _safeInt(json['totalBeds']),
      occupiedBeds: _safeInt(json['occupiedBeds']),
      dominantStatus: json['dominantStatus'] as String? ?? 'AVAILABLE',
    );
  }
}

class OwnerBed {
  OwnerBed({
    required this.id,
    required this.label,
    required this.status,
    this.heldUntil,
    this.tenantName,
  });

  final String id;
  final String label;
  final String status;
  final String? heldUntil;
  final String? tenantName;

  factory OwnerBed.fromJson(Map<String, dynamic> json) {
    return OwnerBed(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      status: json['status'] as String? ?? 'AVAILABLE',
      heldUntil: json['heldUntil'] as String?,
      tenantName: json['tenantName'] as String?,
    );
  }
}

class FloorOption {
  FloorOption({required this.id, required this.label, required this.buildingName});
  final String id;
  final String label;
  final String buildingName;

  factory FloorOption.fromJson(Map<String, dynamic> json) {
    return FloorOption(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      buildingName: json['buildingName'] as String? ?? '',
    );
  }
}

/// Postgres BIGINT returns as String from raw queries.
int _safeInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

// ── Repository ──

@riverpod
OwnerRepository ownerRepository(Ref ref) {
  return OwnerRepository(dio: ref.read(dioProvider));
}

class OwnerRepository {
  OwnerRepository({required this.dio});
  final Dio dio;

  Future<OwnerDashboard> fetchDashboard() async {
    final res = await dio.get('/owner/dashboard');
    return OwnerDashboard.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<OwnerBooking>> fetchBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await dio.get('/owner/bookings', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
    });
    final data = res.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list.map((j) => OwnerBooking.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> acceptBooking(String id) async {
    await dio.patch('/owner/bookings/$id/accept');
  }

  Future<void> declineBooking(String id, String reason) async {
    await dio.patch('/owner/bookings/$id/decline', data: {'reason': reason});
  }

  Future<void> checkInTenant(String bookingId) async {
    await dio.patch('/bookings/$bookingId/check-in');
  }

  Future<List<OwnerTenant>> fetchTenants() async {
    final res = await dio.get('/owner/tenants');
    final list = res.data as List<dynamic>;
    return list.map((j) => OwnerTenant.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchMyHostels() async {
    final res = await dio.get('/owner/hostels');
    final data = res.data;
    final list = data is Map ? (data['data'] as List<dynamic>) : (data as List<dynamic>);
    return list.cast<Map<String, dynamic>>();
  }

  Future<OwnerPaymentSummary> fetchPayments({int page = 1, int limit = 20}) async {
    final res = await dio.get('/owner/payments', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return OwnerPaymentSummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<OwnerRoom>> fetchRooms(String hostelId) async {
    final res = await dio.get('/owner/hostels/$hostelId/rooms');
    final data = res.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list.map((j) => OwnerRoom.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<FloorOption>> fetchFloors(String hostelId) async {
    final res = await dio.get('/owner/hostels/$hostelId/floors');
    final data = res.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list.map((j) => FloorOption.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createRoom(String hostelId, Map<String, dynamic> body) async {
    final res = await dio.post('/owner/hostels/$hostelId/rooms', data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<({String roomNumber, String roomType, int maxBeds, List<OwnerBed> beds})> fetchBeds(String roomId) async {
    final res = await dio.get('/owner/rooms/$roomId/beds');
    final data = res.data as Map<String, dynamic>;
    final list = data['beds'] as List<dynamic>;
    return (
      roomNumber: data['roomNumber'] as String? ?? '',
      roomType: data['roomType'] as String? ?? '',
      maxBeds: (data['maxBeds'] as int?) ?? 99,
      beds: list.map((j) => OwnerBed.fromJson(j as Map<String, dynamic>)).toList(),
    );
  }

  Future<void> addBeds(String roomId, int count) async {
    await dio.post('/owner/rooms/$roomId/beds', data: {'count': count});
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> body) async {
    await dio.patch('/owner/rooms/$roomId', data: body);
  }

  Future<void> deleteRoom(String roomId) async {
    await dio.delete('/owner/rooms/$roomId');
  }

  Future<void> checkoutBed(String bedId) async {
    await dio.patch('/owner/beds/$bedId/checkout');
  }

  Future<void> deleteBed(String bedId) async {
    await dio.delete('/owner/beds/$bedId');
  }

  Future<void> updateBedStatus(String bedId, String status) async {
    await dio.patch('/owner/beds/$bedId/status', data: {'status': status});
  }

  // ── Add Hostel ──

  Future<Map<String, dynamic>> createHostel({
    required String name,
    required String address,
    required String city,
    String? description,
    String genderPolicy = 'MIXED',
    String? university,
    String bookingMode = 'FLEXIBLE',
    List<String> amenityIds = const [],
    List<String> imageUrls = const [],
    int floorCount = 1,
    String? region,
    String? area,
    String? landmark,
    String? digitalAddress,
  }) async {
    final res = await dio.post('/owner/hostels', data: {
      'name': name,
      'address': address,
      'city': city,
      if (region != null) 'region': region,
      if (area != null) 'area': area,
      if (landmark != null) 'landmark': landmark,
      if (digitalAddress != null) 'digitalAddress': digitalAddress,
      if (description != null) 'description': description,
      'genderPolicy': genderPolicy,
      if (university != null) 'university': university,
      'bookingMode': bookingMode,
      'amenityIds': amenityIds,
      'imageUrls': imageUrls,
      'floorCount': floorCount,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchHostel(String hostelId) async {
    final res = await dio.get('/owner/hostels/$hostelId');
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateHostel(String hostelId, Map<String, dynamic> data) async {
    await dio.patch('/owner/hostels/$hostelId', data: data);
  }

  Future<void> submitHostel(String hostelId) async {
    await dio.patch('/owner/hostels/$hostelId/submit');
  }

  Future<String> uploadImage(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      'folder': 'hostels',
    });
    final res = await dio.post('/media/upload', data: formData);
    final data = res.data as Map<String, dynamic>;
    return data['url'] as String;
  }
}
