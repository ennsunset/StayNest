// core/theme/status_palette.dart
//
// Booking, bed and payment states map to colours in exactly one place. No screen
// and no widget decides what colour a status is. Defined here because the same
// state appears on the student side, the owner side and the admin console, and
// they must never disagree.

import 'package:flutter/widgets.dart';

import 'tokens.dart';

enum SNStatusTone { neutral, info, success, warning, danger }

@immutable
class SNStatusStyle {
  const SNStatusStyle(this.foreground, this.background);

  /// Text and icon colour.
  final Color foreground;

  /// Badge fill — the token at 10% opacity, matching the `bg-x/10` pattern.
  final Color background;
}

extension SNStatusPalette on SNColorTokens {
  SNStatusStyle styleFor(SNStatusTone tone) {
    final fg = switch (tone) {
      SNStatusTone.neutral => mutedForeground,
      SNStatusTone.info => primary,
      SNStatusTone.success => success,
      SNStatusTone.warning => warning,
      SNStatusTone.danger => destructive,
    };
    return SNStatusStyle(fg, fg.withValues(alpha: 0.1));
  }
}

/// Bed state — the atomic bookable unit. Mirrors the server enum exactly.
enum BedState { available, held, booked, occupied, maintenance, disabled }

/// Booking lifecycle. Mirrors the server enum exactly.
enum BookingState {
  draft,
  held,
  pendingPayment,
  confirmed,
  checkedIn,
  completed,
  expired,
  cancelled,
  refunded,
}

enum PaymentState { pending, successful, failed, refunded }

extension BedStateTone on BedState {
  SNStatusTone get tone => switch (this) {
        BedState.available => SNStatusTone.success,
        BedState.held => SNStatusTone.warning,
        BedState.booked => SNStatusTone.info,
        BedState.occupied => SNStatusTone.neutral,
        BedState.maintenance => SNStatusTone.neutral,
        BedState.disabled => SNStatusTone.neutral,
      };

  String get label => switch (this) {
        BedState.available => 'Available',
        BedState.held => 'Held',
        BedState.booked => 'Booked',
        BedState.occupied => 'Occupied',
        BedState.maintenance => 'Maintenance',
        BedState.disabled => 'Disabled',
      };

  /// Only these two are owner-settable. Everything else is computed from
  /// booking state — an owner can never hand-set a bed back to available.
  bool get ownerSettable =>
      this == BedState.maintenance || this == BedState.disabled;
}

extension BookingStateTone on BookingState {
  SNStatusTone get tone => switch (this) {
        BookingState.draft => SNStatusTone.neutral,
        BookingState.held => SNStatusTone.warning,
        BookingState.pendingPayment => SNStatusTone.warning,
        BookingState.confirmed => SNStatusTone.info,
        BookingState.checkedIn => SNStatusTone.success,
        BookingState.completed => SNStatusTone.neutral,
        BookingState.expired => SNStatusTone.neutral,
        BookingState.cancelled => SNStatusTone.danger,
        BookingState.refunded => SNStatusTone.danger,
      };

  String get label => switch (this) {
        BookingState.draft => 'Draft',
        BookingState.held => 'Held',
        BookingState.pendingPayment => 'Awaiting payment',
        BookingState.confirmed => 'Confirmed',
        BookingState.checkedIn => 'Checked in',
        BookingState.completed => 'Completed',
        BookingState.expired => 'Expired',
        BookingState.cancelled => 'Cancelled',
        BookingState.refunded => 'Refunded',
      };
}

extension PaymentStateTone on PaymentState {
  SNStatusTone get tone => switch (this) {
        PaymentState.pending => SNStatusTone.warning,
        PaymentState.successful => SNStatusTone.success,
        PaymentState.failed => SNStatusTone.danger,
        PaymentState.refunded => SNStatusTone.neutral,
      };

  String get label => switch (this) {
        PaymentState.pending => 'Pending',
        PaymentState.successful => 'Paid',
        PaymentState.failed => 'Failed',
        PaymentState.refunded => 'Refunded',
      };
}
