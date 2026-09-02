// features/payment/presentation/payment_webview_screen.dart
//
// Opens Paystack checkout in a WebView. On success callback URL,
// verifies server-side then navigates to confirmation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/payment/data/payments_repository.dart';
import 'package:staynest_mobile/features/booking/data/bookings_provider.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/features/payment/presentation/payment_failed_screen.dart';

class PaymentWebViewScreen extends ConsumerStatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
    required this.bookingId,
    required this.hostelName,
    required this.roomLabel,
    required this.bedLabel,
  });

  final String authorizationUrl;
  final String reference;
  final String bookingId;
  final String hostelName;
  final String roomLabel;
  final String bedLabel;

  @override
  ConsumerState<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends ConsumerState<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _verifying = false;

  // Paystack redirects here on success
  static const _callbackHost = 'staynest.app';
  static const _callbackUrl = 'https://staynest.app/payment/callback';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (request) {
          // Intercept callback URL
          if (request.url.contains(_callbackHost)) {
            _onPaymentComplete();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  Future<void> _onPaymentComplete() async {
    if (_verifying) return;
    setState(() => _verifying = true);

    try {
      final repo = ref.read(paymentsRepositoryProvider);
      final result = await repo.verify(widget.reference);

      if (!mounted) return;

      if (result.isSuccess) {
        ref.invalidate(myBookingsProvider);
        // Use booking reference (without payment suffix)
        final bookingRef = widget.reference.contains('-') && widget.reference.split('-').length > 3
            ? widget.reference.split('-').sublist(0, 3).join('-')
            : widget.reference;
        context.go(Routes.bookingConfirmation, extra: {
          'reference': bookingRef,
          'hostelName': widget.hostelName,
          'roomLabel': widget.roomLabel,
          'bedLabel': widget.bedLabel,
        });
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PaymentFailedScreen(
            bookingId: widget.bookingId,
            hostelName: widget.hostelName,
            roomLabel: widget.roomLabel,
            bedLabel: widget.bedLabel,
          )),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not verify payment. Please check My Stays.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Payment',
        onBack: () {
          // Warn before leaving
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Cancel Payment?'),
              content: const Text('Your bed is still held. You can pay later from My Stays.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continue Paying'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.invalidate(myBookingsProvider);
                    context.pop();
                  },
                  child: const Text('Leave'),
                ),
              ],
            ),
          );
        },
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading || _verifying)
            Container(
              color: c.background.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _verifying ? 'Verifying payment...' : 'Loading checkout...',
                      style: SNText.body.copyWith(color: c.mutedForeground),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
