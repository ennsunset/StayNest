import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/network/api_client.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_input.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key, required this.hostelId, required this.hostelName, this.bookingId});
  final String hostelId;
  final String hostelName;
  final String? bookingId;

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  bool _canReview = false;
  String? _bookingIdFromApi;
  Map<String, dynamic>? _myReview;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/reviews/hostel/${widget.hostelId}');
      final data = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
          _stats = data['stats'] as Map<String, dynamic>?;
          _loading = false;
        });
      }
      // Check if user can review (has a completed booking + hasn't reviewed)
      if (widget.bookingId != null) {
        final existing = await dio.get('/reviews/booking/${widget.bookingId}');
        final resp = existing.data as Map<String, dynamic>;
        if (mounted) setState(() {
          _myReview = resp['review'] as Map<String, dynamic>?;
          _canReview = resp['hasReviewed'] != true;
        });
      } else {
        try {
          final canRes = await dio.get('/reviews/can-review/${widget.hostelId}');
          final canData = canRes.data as Map<String, dynamic>;
          if (mounted && canData['canReview'] == true) {
            setState(() {
              _canReview = true;
              _bookingIdFromApi = canData['bookingId'] as String?;
            });
          }
        } catch (_) {}
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final avg = _stats?['average'] ?? 0.0;
    final count = _stats?['count'] ?? 0;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Reviews', onBack: () => context.pop()),
      floatingActionButton: _canReview
          ? FloatingActionButton.extended(
              onPressed: () => _showWriteReview(c),
              backgroundColor: c.primary,
              foregroundColor: c.primaryForeground,
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Write Review'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(SNSpace.screenX),
                children: [
                  // Stats card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(SNSpace.x5),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(SNRadius.lg),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          avg is double ? avg.toStringAsFixed(1) : avg.toString(),
                          style: SNText.headingMd.copyWith(fontSize: 48, color: c.foreground, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) => Icon(
                            i < ((avg is num ? avg.toDouble() : 0.0).round()) ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: const Color(0xFFE8A33D), size: 24,
                          )),
                        ),
                        const SizedBox(height: 8),
                        Text('$count ${count == 1 ? 'review' : 'reviews'}',
                          style: SNText.caption.copyWith(color: c.mutedForeground)),
                      ],
                    ),
                  ),
                  const SizedBox(height: SNSpace.section),

                  if (_reviews.isEmpty)
                    _emptyState(c)
                  else ...[
                    SNSectionLabel('All Reviews'),
                    const SizedBox(height: SNSpace.x4),
                    ..._reviews.map((r) => _reviewCard(c, r)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _emptyState(SNColorTokens c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle),
              child: Icon(Icons.rate_review_outlined, size: 36, color: c.mutedForeground),
            ),
            const SizedBox(height: 20),
            Text('No reviews yet', style: SNText.headingMd.copyWith(color: c.foreground)),
            const SizedBox(height: 8),
            Text('Be the first to share your experience!',
              style: SNText.body.copyWith(color: c.mutedForeground), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard(SNColorTokens c, Map<String, dynamic> review) {
    final rating = review['rating'] as int? ?? 0;
    final timeAgo = _timeAgo(review['created_at']);
    final isOwn = review['student_id'] == ref.read(authNotifierProvider)?.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: isOwn ? () => _confirmDelete(review['id'] as String) : null,
        child: SNCard(
        padding: const EdgeInsets.all(SNSpace.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: c.muted,
                  backgroundImage: review['author_avatar'] != null ? NetworkImage(review['author_avatar']) : null,
                  child: review['author_avatar'] == null ? Icon(Icons.person, size: 18, color: c.mutedForeground) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review['author_name'] ?? 'Student', style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 13)),
                      Text(timeAgo, style: SNText.caption.copyWith(color: c.mutedForeground, fontSize: 11)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) => Icon(
                    i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFE8A33D), size: 16,
                  )),
                ),
              ],
            ),
            if (review['body'] != null && (review['body'] as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(review['body'], style: SNText.body.copyWith(color: c.mutedForeground, height: 1.5)),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _confirmDelete(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('DELETE', style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final dio = ref.read(dioProvider);
        await dio.delete('/reviews/$reviewId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review deleted')));
          _load();
        }
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete review')));
      }
    }
  }

  void _showWriteReview(SNColorTokens c) {
    int selectedRating = 0;
    final bodyCtrl = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SNSheetHandle(),
              const SizedBox(height: SNSpace.x2),
              Text('Rate Your Stay', style: SNText.headingMd),
              const SizedBox(height: 4),
              Text(widget.hostelName, style: SNText.body.copyWith(color: c.mutedForeground)),
              const SizedBox(height: 24),

              // Star rating
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) => GestureDetector(
                    onTap: () => setSheetState(() => selectedRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xFFE8A33D),
                        size: 44,
                      ),
                    ),
                  )),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  selectedRating == 0 ? 'Tap to rate'
                    : selectedRating == 1 ? 'Poor'
                    : selectedRating == 2 ? 'Fair'
                    : selectedRating == 3 ? 'Good'
                    : selectedRating == 4 ? 'Very Good'
                    : 'Excellent',
                  style: SNText.caption.copyWith(color: c.mutedForeground),
                ),
              ),
              const SizedBox(height: 20),

              SNInput(label: 'Your Review (optional)', controller: bodyCtrl, hint: 'Share your experience...', maxLines: 4),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: SNButton(
                  label: 'Submit Review',
                  isLoading: submitting,
                  onPressed: selectedRating == 0 ? null : () async {
                    setSheetState(() => submitting = true);
                    try {
                      final dio = ref.read(dioProvider);
                      await dio.post('/reviews/${widget.bookingId ?? _bookingIdFromApi}', data: {
                        'rating': selectedRating,
                        if (bodyCtrl.text.trim().isNotEmpty) 'body': bodyCtrl.text.trim(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!')));
                        _load();
                      }
                    } catch (e) {
                      setSheetState(() => submitting = false);
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Failed to submit review')));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}';
  }
}
