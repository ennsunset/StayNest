// core/utils/money.dart
//
// Money is an integer number of pesewas, everywhere, always (decision D1).
// 100 pesewas = GH₵1. GH₵3,200.00 = 320000 pesewas.
//
// This file is the ONLY place a pesewa integer becomes a display string. No
// widget formats money inline. No screen does arithmetic on a formatted string.

import 'package:flutter/foundation.dart';

extension type const Pesewas(int value) implements int {
  /// Convenience for tests and seed data only. Never use this to parse a value
  /// that came off the wire — the API already sends pesewas.
  factory Pesewas.fromCedis(int cedis) => Pesewas(cedis * 100);

  Pesewas operator +(Pesewas other) => Pesewas(value + other.value);
  Pesewas operator -(Pesewas other) => Pesewas(value - other.value);

  bool get isZero => value == 0;
}

@immutable
class Money {
  const Money._();

  static const symbol = 'GH₵';

  /// GH₵3,200.00 — receipts, price breakdowns, totals. Anywhere the exact
  /// figure matters.
  static String format(int pesewas, {bool withSymbol = true}) {
    final negative = pesewas < 0;
    final abs = pesewas.abs();
    final cedis = abs ~/ 100;
    final rem = abs % 100;
    final body = '${_group(cedis)}.${rem.toString().padLeft(2, '0')}';
    return '${negative ? '-' : ''}${withSymbol ? symbol : ''}$body';
  }

  /// GH₵3,200 — drops the decimals when they're zero. Use on cards, listings
  /// and headers where the round number reads better.
  ///
  /// Never use this on a receipt, a total, or anything a user might reconcile
  /// against their bank statement.
  static String formatCompact(int pesewas, {bool withSymbol = true}) {
    if (pesewas % 100 == 0) {
      final negative = pesewas < 0;
      final cedis = (pesewas.abs()) ~/ 100;
      return '${negative ? '-' : ''}${withSymbol ? symbol : ''}${_group(cedis)}';
    }
    return format(pesewas, withSymbol: withSymbol);
  }

  /// Parses user input ("3200", "3,200.50") into pesewas. Returns null on
  /// anything it can't read — the caller shows a field error, never guesses.
  ///
  /// Used for owner-entered rent. Student-facing amounts always come from the
  /// server and are never typed.
  static int? parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    final parts = cleaned.split('.');
    if (parts.length > 2) return null;

    final cedis = int.tryParse(parts[0].isEmpty ? '0' : parts[0]);
    if (cedis == null) return null;

    var pesewas = 0;
    if (parts.length == 2) {
      final frac = parts[1].padRight(2, '0');
      if (frac.length > 2) return null;
      pesewas = int.tryParse(frac) ?? -1;
      if (pesewas < 0) return null;
    }
    return cedis * 100 + pesewas;
  }

  static String _group(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
