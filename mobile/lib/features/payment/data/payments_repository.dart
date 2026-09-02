// features/payment/data/payments_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:staynest_mobile/core/network/api_client.dart';

part 'payments_repository.g.dart';

class PaymentInitResult {
  PaymentInitResult({
    required this.paymentId,
    required this.authorizationUrl,
    required this.accessCode,
    required this.reference,
  });

  final String paymentId;
  final String authorizationUrl;
  final String accessCode;
  final String reference;

  factory PaymentInitResult.fromJson(Map<String, dynamic> json) {
    return PaymentInitResult(
      paymentId: json['paymentId'] as String,
      authorizationUrl: json['authorizationUrl'] as String,
      accessCode: json['accessCode'] as String,
      reference: json['reference'] as String,
    );
  }
}

class PaymentVerifyResult {
  PaymentVerifyResult({
    required this.id,
    required this.status,
    required this.reference,
  });

  final String id;
  final String status;
  final String reference;

  bool get isSuccess => status == 'SUCCESS';

  factory PaymentVerifyResult.fromJson(Map<String, dynamic> json) {
    return PaymentVerifyResult(
      id: json['id'] as String,
      status: json['status'] as String,
      reference: json['providerReference'] as String? ?? json['provider_reference'] as String? ?? '',
    );
  }
}

@riverpod
PaymentsRepository paymentsRepository(Ref ref) {
  return PaymentsRepository(dio: ref.read(dioProvider));
}


class PaymentHistoryItem {
  PaymentHistoryItem({
    required this.id,
    required this.amountPesewas,
    required this.status,
    this.channel,
    required this.reference,
    required this.createdAt,
    required this.bookingId,
    required this.paymentType,
    required this.hostelName,
    this.cardBrand,
    this.cardLast4,
  });

  final String id;
  final int amountPesewas;
  final String status;
  final String? channel;
  final String reference;
  final DateTime createdAt;
  final String bookingId;
  final String paymentType;
  final String hostelName;
  final String? cardBrand;
  final String? cardLast4;

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: json['id'] as String,
      amountPesewas: _safeInt(json['amountPesewas']),
      status: json['status'] as String,
      channel: json['channel'] as String?,
      reference: json['reference'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      bookingId: json['bookingId'] as String,
      paymentType: json['paymentType'] as String? ?? 'FULL',
      hostelName: json['hostelName'] as String,
      cardBrand: json['cardBrand'] as String?,
      cardLast4: json['cardLast4'] as String?,
    );
  }

  static int _safeInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class PaymentHistoryResult {
  PaymentHistoryResult({required this.totalPaidYearPesewas, required this.payments});

  final int totalPaidYearPesewas;
  final List<PaymentHistoryItem> payments;

  factory PaymentHistoryResult.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryResult(
      totalPaidYearPesewas: PaymentHistoryItem._safeInt(json['totalPaidYearPesewas']),
      payments: (json['payments'] as List<dynamic>)
          .map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}


class PaymentsRepository {
  PaymentsRepository({required this.dio});
  final Dio dio;

  /// Initialize payment - returns Paystack authorization URL
  Future<PaymentInitResult> initialize({
    required String bookingId,
    String? callbackUrl,
  }) async {
    final res = await dio.post('/payments/initialize', data: {
      'bookingId': bookingId,
      if (callbackUrl != null) 'callbackUrl': callbackUrl,
    });
    return PaymentInitResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// Initialize payment for a specific installment
  Future<PaymentInitResult> initializeInstallment({
    required String bookingId,
    required String installmentId,
    String? callbackUrl,
  }) async {
    final res = await dio.post('/payments/initialize', data: {
      'bookingId': bookingId,
      'installmentId': installmentId,
      if (callbackUrl != null) 'callbackUrl': callbackUrl,
    });
    return PaymentInitResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// Verify payment after redirect
  Future<PaymentVerifyResult> verify(String reference) async {
    final res = await dio.get('/payments/verify/$reference');
    return PaymentVerifyResult.fromJson(res.data as Map<String, dynamic>);
  }


  /// Get student payment history
  Future<PaymentHistoryResult> getMyHistory() async {
    final res = await dio.get('/payments/my-history');
    return PaymentHistoryResult.fromJson(res.data as Map<String, dynamic>);
  }





}
