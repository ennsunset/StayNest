// features/booking/data/bookings_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:staynest_mobile/core/network/api_client.dart';

part 'bookings_repository.g.dart';

/// Safe int parser — handles both num and BIGINT string from Postgres.
int _safeInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

// ── Models ──────────────────────────────────────────

class BedInfo {
  BedInfo({
    required this.id,
    required this.label,
    required this.status,
    required this.roomId,
    this.heldUntil,
    this.roomType,
    this.pricePesewas = 0,
    this.roomNumber,
  });

  final String id;
  final String label;
  final String status; // AVAILABLE, HELD, BOOKED, OCCUPIED, MAINTENANCE, DISABLED
  final String roomId;
  final DateTime? heldUntil;
  final String? roomType;
  final int pricePesewas;
  final String? roomNumber;

  bool get isAvailable => status == 'AVAILABLE';
  bool get isOccupied => status == 'OCCUPIED' || status == 'BOOKED';

  factory BedInfo.fromJson(Map<String, dynamic> json) {
    return BedInfo(
      id: json['id'] as String,
      label: json['label'] as String,
      status: json['status'] as String,
      roomId: (json['room_id'] ?? json['roomId'] ?? '') as String,
      heldUntil: json['held_until'] != null
          ? DateTime.parse(json['held_until'] as String)
          : null,
      roomType: json['room_type'] as String?,
      pricePesewas: _safeInt(json['price_pesewas']),
      roomNumber: json['room_number'] as String?,
    );
  }
}

class Booking {
  Booking({
    required this.id,
    required this.studentId,
    required this.bedId,
    required this.status,
    required this.reference,
    required this.pricePesewas,
    required this.platformFeePesewas,
    required this.totalPesewas,
    this.heldUntil,
    required this.periodLabel,
    this.duration = 'FULL_YEAR',
    this.checkInDate,
    this.cancelReason,
    required this.createdAt,
    this.updatedAt,
    this.agreementSignedAt,
    this.bed,
    this.paymentType = 'FULL',
  });

  final String id;
  final String studentId;
  final String bedId;
  final String status;
  final String reference;
  final int pricePesewas;
  final int platformFeePesewas;
  final int totalPesewas;
  final DateTime? heldUntil;
  final String periodLabel;
  final String duration;
  final String? checkInDate;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? agreementSignedAt;
  final BookingBedDetail? bed;
  final String paymentType;

  bool get isHeld => status == 'HELD';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isInstallment => paymentType == 'INSTALLMENT';

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      studentId: json['studentId'] as String? ?? json['student_id'] as String,
      bedId: json['bedId'] as String? ?? json['bed_id'] as String,
      status: json['status'] as String,
      reference: json['reference'] as String,
      pricePesewas: _safeInt(json['pricePesewas'] ?? json['price_pesewas']),
      platformFeePesewas: _safeInt(json['platformFeePesewas'] ?? json['platform_fee_pesewas']),
      totalPesewas: _safeInt(json['totalPesewas'] ?? json['total_pesewas']),
      heldUntil: _parseDate(json['heldUntil'] ?? json['held_until']),
      periodLabel: json['periodLabel'] as String? ?? json['period_label'] as String? ?? 'Full Academic Year',
      duration: json['duration'] as String? ?? 'FULL_YEAR',
      checkInDate: json['checkInDate'] as String? ?? json['check_in_date'] as String?,
      cancelReason: json['cancelReason'] as String? ?? json['cancel_reason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      agreementSignedAt: _parseDate(json['agreementSignedAt'] ?? json['agreement_signed_at']),
      bed: json['bed'] != null ? BookingBedDetail.fromJson(json['bed'] as Map<String, dynamic>) : null,
      paymentType: json['paymentType'] as String? ?? json['payment_type'] as String? ?? 'FULL',
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.parse(v as String);
  }
}

class BookingBedDetail {
  BookingBedDetail({
    required this.id,
    required this.label,
    this.room,
  });

  final String id;
  final String label;
  final BookingRoomDetail? room;

  factory BookingBedDetail.fromJson(Map<String, dynamic> json) {
    return BookingBedDetail(
      id: json['id'] as String,
      label: json['label'] as String,
      room: json['room'] != null
          ? BookingRoomDetail.fromJson(json['room'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BookingRoomDetail {
  BookingRoomDetail({
    required this.id,
    required this.number,
    required this.type,
    required this.pricePesewas,
    this.securityDepositPesewas = 0,
    this.hostelName,
    this.hostelId,
    this.imageUrl,
  });

  final String id;
  final String number;
  final String type;
  final int pricePesewas;
  final int securityDepositPesewas;
  final String? hostelName;
  final String? hostelId;
  final String? imageUrl;

  factory BookingRoomDetail.fromJson(Map<String, dynamic> json) {
    String? hostelName;
    String? hostelId;
    String? hostelImageUrl;
    if (json['floor'] != null) {
      final floor = json['floor'] as Map<String, dynamic>;
      if (floor['building'] != null) {
        final building = floor['building'] as Map<String, dynamic>;
        if (building['hostel'] != null) {
          final hostel = building['hostel'] as Map<String, dynamic>;
          hostelName = hostel['name'] as String?;
          hostelId = hostel['id'] as String?;
          final imgs = hostel['imageUrls'] ?? hostel['image_urls'];
          if (imgs is List && imgs.isNotEmpty) hostelImageUrl = imgs.first as String?;
        }
      }
    }
    return BookingRoomDetail(
      id: json['id'] as String,
      number: json['number'] as String,
      type: json['type'] as String,
      pricePesewas: _safeInt(json['price_pesewas'] ?? json['pricePesewas']),
      securityDepositPesewas: _safeInt(json['securityDepositPesewas'] ?? json['security_deposit_pesewas'] ?? 0),
      hostelName: hostelName,
      hostelId: hostelId,
      imageUrl: hostelImageUrl,
    );
  }
}

class RoomWithBeds {
  RoomWithBeds({
    required this.id,
    required this.number,
    required this.type,
    required this.pricePesewas,
    required this.beds,
    this.hostelName,
    this.hostelId,
    this.hasAC = false,
    this.hasFan = false,
    this.hasTV = false,
    this.socketCount = 1,
    this.hasPrivateBath = false,
    this.imageUrl,
    this.bookingMode = 'FLEXIBLE',
    this.semesterPricePesewas,
    this.securityDepositPesewas = 0,
  });

  final String id;
  final String number;
  final String type;
  final int pricePesewas;
  final List<BedInfo> beds;
  final String? hostelName;
  final String? hostelId;
  final bool hasAC;
  final bool hasFan;
  final bool hasTV;
  final int socketCount;
  final bool hasPrivateBath;
  final String? imageUrl;
  final String bookingMode;
  final int? semesterPricePesewas;
  final int securityDepositPesewas;

  factory RoomWithBeds.fromJson(Map<String, dynamic> json) {
    String? hostelName;
    String? hostelId;
    String? hostelImageUrl;
    String _bookingMode = 'FLEXIBLE';
    if (json['floor'] != null) {
      final floor = json['floor'] as Map<String, dynamic>;
      if (floor['building'] != null) {
        final building = floor['building'] as Map<String, dynamic>;
        if (building['hostel'] != null) {
          final hostel = building['hostel'] as Map<String, dynamic>;
          hostelName = hostel['name'] as String?;
          hostelId = hostel['id'] as String?;
          _bookingMode = hostel['bookingMode'] as String? ?? hostel['booking_mode'] as String? ?? 'FLEXIBLE';
          final imgs = hostel['imageUrls'] ?? hostel['image_urls'];
          if (imgs is List && imgs.isNotEmpty) hostelImageUrl = imgs.first as String?;
        }
      }
    }

    final beds = (json['beds'] as List<dynamic>? ?? []).map((b) {
      final m = b as Map<String, dynamic>;
      m['room_id'] = json['id'];
      m['room_type'] = json['type'];
      m['price_pesewas'] = json['pricePesewas'] ?? json['price_pesewas'];
      m['room_number'] = json['number'];
      return BedInfo.fromJson(m);
    }).toList();

    return RoomWithBeds(
      id: json['id'] as String,
      number: json['number'] as String,
      type: json['type'] as String,
      pricePesewas: _safeInt(json['pricePesewas'] ?? json['price_pesewas']),
      beds: beds,
      hostelName: hostelName,
      hostelId: hostelId,
      hasAC: json['hasAC'] as bool? ?? json['has_ac'] as bool? ?? false,
      hasFan: json['hasFan'] as bool? ?? json['has_fan'] as bool? ?? false,
      hasTV: json['hasTV'] as bool? ?? json['has_tv'] as bool? ?? false,
      socketCount: (json['socketCount'] ?? json['socket_count'] ?? 1) is int ? (json['socketCount'] ?? json['socket_count'] ?? 1) : int.tryParse((json['socketCount'] ?? json['socket_count'] ?? '1').toString()) ?? 1,
      imageUrl: hostelImageUrl,
      hasPrivateBath: json['hasPrivateBath'] as bool? ?? json['has_private_bath'] as bool? ?? false,
      securityDepositPesewas: int.tryParse((json['securityDepositPesewas'] ?? json['security_deposit_pesewas'] ?? '0').toString()) ?? 0,
    );
  }
}

// ── Repository ──────────────────────────────────────

@riverpod
BookingsRepository bookingsRepository(Ref ref) {
  return BookingsRepository(dio: ref.read(dioProvider));
}


class RefundStatus {
  RefundStatus({
    required this.id,
    required this.bookingId,
    required this.reference,
    required this.hostelName,
    required this.amountPesewas,
    required this.status,
    this.reason,
    this.rejectReason,
    this.approvedAt,
    this.refundedAt,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookingId;
  final String reference;
  final String hostelName;
  final int amountPesewas;
  final String status;
  final String? reason;
  final String? rejectReason;
  final DateTime? approvedAt;
  final DateTime? refundedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory RefundStatus.fromJson(Map<String, dynamic> json) {
    return RefundStatus(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      reference: json['reference'] as String? ?? '',
      hostelName: json['hostelName'] as String? ?? '',
      amountPesewas: _safeInt(json['amountPesewas']),
      status: json['status'] as String,
      reason: json['reason'] as String?,
      rejectReason: json['rejectReason'] as String?,
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      refundedAt: json['refundedAt'] != null ? DateTime.parse(json['refundedAt']) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  static int _safeInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class BookingsRepository {
  BookingsRepository({required this.dio});
  final Dio dio;

  /// Get room details with beds.
  Future<RoomWithBeds> fetchRoomWithBeds(String roomId) async {
    final res = await dio.get('/hostels/rooms/$roomId');
    return RoomWithBeds.fromJson(res.data as Map<String, dynamic>);
  }

  /// Hold a bed — creates a HELD booking with 15-min countdown.
  /// Returns the booking with price breakdown and held_until.
  Future<Booking> holdBed(String bedId, {String? checkInDate, String duration = 'FULL_YEAR', String paymentType = 'FULL'}) async {
    final res = await dio.post('/bookings', data: {
      'bedId': bedId,
      'duration': duration,
      'paymentType': paymentType,
      if (checkInDate != null) 'checkInDate': checkInDate,
    });
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  /// Get a booking by reference.
  Future<Booking> fetchByReference(String reference) async {
    final res = await dio.get('/bookings/ref/$reference');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  /// Get a booking by ID (with full bed → room → hostel relations).
  /// Check if student is eligible for installments at this hostel
  Future<Map<String, dynamic>> checkInstallmentEligibility(String hostelId) async {
    final res = await dio.get('/bookings/installment-eligibility/$hostelId');
    return res.data as Map<String, dynamic>;
  }

  /// Get installment plan for a booking
  Future<Map<String, dynamic>> getInstallmentPlan(String bookingId) async {
    final res = await dio.get('/bookings/$bookingId/installments');
    return res.data as Map<String, dynamic>;
  }

  /// Pay an installment
  Future<Map<String, dynamic>> payInstallment(String bookingId, String installmentId, String paymentReference) async {
    final res = await dio.patch('/bookings/$bookingId/installments/$installmentId/pay', data: {
      'paymentReference': paymentReference,
    });
    return res.data as Map<String, dynamic>;
  }

  // ── Visitors ──

  Future<Map<String, dynamic>> createVisitorPass(String bookingId, {required String visitorName, String? visitorPhone, String? purpose}) async {
    final res = await dio.post('/bookings/$bookingId/visitors', data: {
      'visitorName': visitorName,
      if (visitorPhone != null) 'visitorPhone': visitorPhone,
      if (purpose != null) 'purpose': purpose,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getVisitorPasses(String bookingId) async {
    final res = await dio.get('/bookings/$bookingId/visitors');
    return res.data as List<dynamic>;
  }

  Future<void> deleteVisitorPass(String passId) async {
    await dio.patch('/bookings/visitors/$passId/delete');
  }

  Future<void> revokeVisitorPass(String passId) async {
    await dio.patch('/bookings/visitors/$passId/revoke');
  }

  Future<Map<String, dynamic>> signAgreement(String bookingId) async {
    final resp = await dio.patch('/bookings/$bookingId/agreement/sign');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAgreement(String bookingId) async {
    final resp = await dio.get('/bookings/$bookingId/agreement');
    return resp.data as Map<String, dynamic>;
  }

  Future<Booking> fetchById(String id) async {
    final res = await dio.get('/bookings/$id');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  /// Get all bookings for the logged-in student.
  Future<List<Booking>> fetchMine() async {
    final res = await dio.get('/bookings/mine');
    final list = res.data as List<dynamic>;
    return list.map((j) => Booking.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Cancel a booking.
  Future<void> cancel(String bookingId, {String? reason}) async {
    await dio.patch('/bookings/$bookingId/cancel', data: {
      if (reason != null) 'reason': reason,
    });
  }

  /// Confirm a booking (temporary — will be called by payment flow in Stage 3).
  Future<Booking> confirm(String bookingId) async {
    final res = await dio.patch('/bookings/$bookingId/confirm');
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }


  /// Get refund status for a booking


  Future<MoveInTask> addCustomTask(String bookingId, String title, {String? description}) async {
    final resp = await dio.post('/bookings/$bookingId/move-in-tasks', data: {
      'title': title,
      if (description != null) 'description': description,
    });
    return MoveInTask.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteCustomTask(String taskId) async {
    await dio.delete('/bookings/move-in-tasks/$taskId');
  }

  Future<void> updateCheckInDate(String bookingId, String date) async {
    await dio.patch('/bookings/$bookingId/check-in-date', data: {'checkInDate': date});
  }

  Future<List<MoveInTask>> getMoveInTasks(String bookingId) async {
    final resp = await dio.get('/bookings/$bookingId/move-in-tasks');
    return (resp.data as List).map((e) => MoveInTask.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MoveInTask> updateMoveInTask(String taskId, String status) async {
    final resp = await dio.patch('/bookings/move-in-tasks/$taskId', data: {'status': status});
    return MoveInTask.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<UtilityData> getUtilities(String bookingId) async {
    final resp = await dio.get('/bookings/$bookingId/utilities');
    return UtilityData.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<RefundStatus?> getRefund(String bookingId) async {
    try {
      final res = await dio.get('/bookings/$bookingId/refund');
      if (res.data == null || (res.data is String && res.data.isEmpty)) return null;
      return RefundStatus.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

}

// ── Move-in Task ──

class MoveInTask {
  final String id;
  final String bookingId;
  final String title;
  final String? description;
  final int sortOrder;
  final String status;
  final String assignee;
  final bool custom;
  final DateTime? completedAt;

  MoveInTask({
    required this.id,
    required this.bookingId,
    required this.title,
    this.description,
    required this.sortOrder,
    required this.status,
    this.assignee = 'OWNER',
    this.custom = false,
    this.completedAt,
  });

  factory MoveInTask.fromJson(Map<String, dynamic> json) => MoveInTask(
        id: json['id'] as String,
        bookingId: json['booking_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
        status: json['status'] as String? ?? 'PENDING',
        assignee: json['assignee'] as String? ?? 'OWNER',
        custom: json['custom'] as bool? ?? false,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'] as String)
            : null,
      );
}

// ── Utility Models ──

class UtilityAccount {
  final String id;
  final String utilityType;
  final int creditPesewas;
  final int estimatedDaysLeft;

  UtilityAccount({
    required this.id,
    required this.utilityType,
    required this.creditPesewas,
    required this.estimatedDaysLeft,
  });

  factory UtilityAccount.fromJson(Map<String, dynamic> json) => UtilityAccount(
        id: json['id'] as String,
        utilityType: json['utility_type'] as String,
        creditPesewas: _safeInt(json['credit_pesewas']),
        estimatedDaysLeft: json['estimated_days_left'] as int? ?? 0,
      );

  static int _safeInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class UtilityBill {
  final String id;
  final String label;
  final String utilityType;
  final int amountPesewas;
  final String status;
  final String? billingPeriod;
  final DateTime? dueDate;

  UtilityBill({
    required this.id,
    required this.label,
    required this.utilityType,
    required this.amountPesewas,
    required this.status,
    this.billingPeriod,
    this.dueDate,
  });

  factory UtilityBill.fromJson(Map<String, dynamic> json) => UtilityBill(
        id: json['id'] as String,
        label: json['label'] as String,
        utilityType: json['utility_type'] as String,
        amountPesewas: UtilityAccount._safeInt(json['amount_pesewas']),
        status: json['status'] as String? ?? 'PENDING',
        billingPeriod: json['billing_period'] as String?,
        dueDate: json['due_date'] != null
            ? DateTime.tryParse(json['due_date'] as String)
            : null,
      );
}

class UtilityData {
  final List<UtilityAccount> accounts;
  final List<UtilityBill> bills;

  UtilityData({required this.accounts, required this.bills});

  factory UtilityData.fromJson(Map<String, dynamic> json) => UtilityData(
        accounts: (json['accounts'] as List<dynamic>)
            .map((e) => UtilityAccount.fromJson(e as Map<String, dynamic>))
            .toList(),
        bills: (json['bills'] as List<dynamic>)
            .map((e) => UtilityBill.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
