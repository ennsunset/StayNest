import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/core/network/api_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' show FormData, MultipartFile;
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_input.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';
import 'package:staynest_mobile/features/messaging/data/messaging_repository.dart';

const _categories = ['ALL', 'SELLING', 'LOST_FOUND', 'EVENTS', 'GENERAL'];
const _categoryLabels = {'ALL': 'All', 'SELLING': 'Selling', 'LOST_FOUND': 'Lost & Found', 'EVENTS': 'Events', 'GENERAL': 'General'};
const _categoryIcons = {'SELLING': Icons.sell_outlined, 'LOST_FOUND': Icons.search_outlined, 'EVENTS': Icons.event_outlined, 'GENERAL': Icons.chat_bubble_outline};

class CommunityBoardScreen extends ConsumerStatefulWidget {
  const CommunityBoardScreen({super.key, required this.hostelId, required this.hostelName});
  final String hostelId;
  final String hostelName;

  @override
  ConsumerState<CommunityBoardScreen> createState() => _CommunityBoardScreenState();
}

class _CommunityBoardScreenState extends ConsumerState<CommunityBoardScreen> {
  String _selectedCategory = 'ALL';
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final cat = _selectedCategory == 'ALL' ? '' : '&category=$_selectedCategory';
      final res = await dio.get('/community/${widget.hostelId}/posts?limit=50$cat');
      if (mounted) setState(() { _posts = List<Map<String, dynamic>>.from(res.data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final userId = ref.watch(authNotifierProvider)?.id;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(title: 'Community Board', onBack: () => context.pop()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(c),
        backgroundColor: c.primary,
        foregroundColor: c.primaryForeground,
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Category tabs
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () { setState(() => _selectedCategory = cat); _loadPosts(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? c.primary : c.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? c.primary : c.border),
                    ),
                    child: Center(
                      child: Text(
                        _categoryLabels[cat] ?? cat,
                        style: SNText.caption.copyWith(
                          color: selected ? c.primaryForeground : c.mutedForeground,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Posts
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadPosts,
                        child: ListView(
                          children: [SizedBox(height: MediaQuery.of(context).size.height * 0.25), _emptyState(c)],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPosts,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(SNSpace.screenX, 0, SNSpace.screenX, 100),
                          itemCount: _posts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _postCard(c, _posts[i], userId),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(SNColorTokens c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SNSpace.screenX),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle),
              child: Icon(Icons.forum_outlined, size: 36, color: c.mutedForeground),
            ),
            const SizedBox(height: 20),
            Text('No posts yet', style: SNText.headingMd.copyWith(color: c.foreground)),
            const SizedBox(height: 8),
            Text('Be the first to post in your hostel community!',
              style: SNText.body.copyWith(color: c.mutedForeground), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _postCard(SNColorTokens c, Map<String, dynamic> post, String? userId) {
    final cat = post['category'] as String? ?? 'GENERAL';
    final isMine = post['student_id'] == userId;
    final isSold = post['status'] == 'SOLD';
    final price = post['price_pesewas'];
    final imageUrl = post['image_url'] as String?;
    final timeAgo = _timeAgo(post['created_at']);

    return SNCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          Padding(
            padding: const EdgeInsets.all(SNSpace.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: avatar + name + time + category chip
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: c.muted,
                      backgroundImage: post['author_avatar'] != null ? NetworkImage(post['author_avatar']) : null,
                      child: post['author_avatar'] == null ? Icon(Icons.person, size: 16, color: c.mutedForeground) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post['author_name'] ?? 'Student', style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 13)),
                          Text(timeAgo, style: SNText.caption.copyWith(color: c.mutedForeground, fontSize: 11)),
                        ],
                      ),
                    ),
                    _categoryChip(c, cat),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                if (isSold)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFDC3545).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text('SOLD', style: SNText.sectionLabel.copyWith(color: const Color(0xFFDC3545), fontSize: 9)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(post['title'] ?? '', style: SNText.bodyBold.copyWith(color: c.mutedForeground, decoration: TextDecoration.lineThrough))),
                    ],
                  )
                else
                  Text(post['title'] ?? '', style: SNText.bodyBold.copyWith(color: c.foreground)),

                const SizedBox(height: 4),
                Text(post['body'] ?? '', style: SNText.body.copyWith(color: c.mutedForeground), maxLines: 3, overflow: TextOverflow.ellipsis),

                // Price (for selling posts)
                if (price != null && cat == 'SELLING') ...[
                  const SizedBox(height: 8),
                  Text(Money.format(_safeInt(price)), style: SNText.headingMd.copyWith(color: c.primary, fontSize: 18)),
                ],

                // Contact seller (for other people's posts)
                if (!isMine && !isSold) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SNButton(
                      label: cat == 'SELLING' ? 'Contact Seller' : 'Message',
                      icon: Icons.chat_bubble_outline,
                      variant: SNButtonVariant.secondary,
                      onPressed: () => _contactPoster(post),
                    ),
                  ),
                ],
                // Actions for own posts
                if (isMine && !isSold) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (cat == 'SELLING')
                        Expanded(
                          child: SNButton(label: 'Mark Sold', variant: SNButtonVariant.secondary, onPressed: () => _markSold(post['id'])),
                        ),
                      if (cat == 'SELLING') const SizedBox(width: 12),
                      Expanded(
                        child: SNButton(label: 'Delete', variant: SNButtonVariant.ghost, onPressed: () => _deletePost(post['id'])),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(SNColorTokens c, String cat) {
    Color bg; Color fg; IconData icon;
    switch (cat) {
      case 'SELLING': bg = const Color(0xFF3FB68B).withOpacity(0.1); fg = const Color(0xFF3FB68B); icon = Icons.sell_outlined; break;
      case 'LOST_FOUND': bg = const Color(0xFFE8A33D).withOpacity(0.1); fg = const Color(0xFFE8A33D); icon = Icons.search_outlined; break;
      case 'EVENTS': bg = c.primary.withOpacity(0.1); fg = c.primary; icon = Icons.event_outlined; break;
      default: bg = c.muted; fg = c.mutedForeground; icon = Icons.chat_bubble_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(_categoryLabels[cat] ?? cat, style: SNText.caption.copyWith(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showCreateSheet(SNColorTokens c) {
    String selectedCat = 'GENERAL';
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    List<XFile> images = [];
    bool creating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SNSheetHandle(),
                const SizedBox(height: SNSpace.x2),
                Text('New Post', style: SNText.headingMd),
                const SizedBox(height: 16),

                // Category selector
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['SELLING', 'LOST_FOUND', 'EVENTS', 'GENERAL'].map((cat) {
                    final selected = selectedCat == cat;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedCat = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? c.primary : c.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? c.primary : c.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_categoryIcons[cat], size: 14, color: selected ? c.primaryForeground : c.mutedForeground),
                            const SizedBox(width: 4),
                            Text(_categoryLabels[cat] ?? cat, style: SNText.caption.copyWith(
                              color: selected ? c.primaryForeground : c.mutedForeground,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                SNInput(label: 'Title', controller: titleCtrl, hint: selectedCat == 'SELLING' ? 'What are you selling?' : 'Title'),
                const SizedBox(height: 12),
                SNInput(label: 'Description', controller: bodyCtrl, hint: 'Details...', maxLines: 3),
                if (selectedCat == 'SELLING') ...[
                  const SizedBox(height: 12),
                  SNInput(label: 'Price (GHS)', controller: priceCtrl, hint: 'e.g. 50', keyboardType: TextInputType.number),
                ],
                const SizedBox(height: 16),

                // Image picker
                Text('Photos', style: SNText.sectionLabel),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...images.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(entry.value.path), width: 80, height: 80, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: c.muted)),
                            ),
                            Positioned(
                              top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => setSheetState(() => images.removeAt(entry.key)),
                                child: Container(
                                  width: 22, height: 22,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (images.length < 5)
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickMultiImage(limit: 5 - images.length);
                            if (picked.isNotEmpty) setSheetState(() => images.addAll(picked));
                          },
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: c.muted,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: c.border, style: BorderStyle.solid),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 24, color: c.mutedForeground),
                                const SizedBox(height: 2),
                                Text('${images.length}/5', style: SNText.caption.copyWith(color: c.mutedForeground, fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: SNButton(
                    label: creating ? 'Posting...' : 'Post',
                    isLoading: creating,
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Title and description required')));
                        return;
                      }
                      setSheetState(() => creating = true);
                      try {
                        final dio = ref.read(dioProvider);

                        // Upload first image if any
                        String? imageUrl;
                        if (images.isNotEmpty) {
                          final formData = FormData.fromMap({
                            'file': await MultipartFile.fromFile(images.first.path, filename: images.first.name),
                            'folder': 'community',
                          });
                          final uploadRes = await dio.post('/media/upload', data: formData);
                          imageUrl = (uploadRes.data as Map<String, dynamic>)['url'] as String?;
                        }

                        final data = <String, dynamic>{
                          'category': selectedCat,
                          'title': titleCtrl.text.trim(),
                          'body': bodyCtrl.text.trim(),
                          if (imageUrl != null) 'imageUrl': imageUrl,
                        };
                        if (selectedCat == 'SELLING' && priceCtrl.text.trim().isNotEmpty) {
                          final ghsAmount = double.tryParse(priceCtrl.text.trim());
                          if (ghsAmount != null) data['pricePesewas'] = (ghsAmount * 100).round();
                        }
                        await dio.post('/community/${widget.hostelId}/posts', data: data);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadPosts();
                      } catch (e) {
                        setSheetState(() => creating = false);
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Failed to create post')));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _contactPoster(Map<String, dynamic> post) async {
    try {
      final msgRepo = ref.read(messagingRepositoryProvider);
      final userId = ref.read(authNotifierProvider)?.id;
      final conv = await msgRepo.getOrCreateDM(post['student_id']);
      if (mounted) {
        context.push('/messages/${conv.id}', extra: {
          'hostelName': post['author_name'] ?? 'Student',
          'userId': userId,
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to open chat')));
    }
  }

  Future<void> _markSold(String postId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/community/posts/$postId/sold');
      _loadPosts();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update')));
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This will remove your post permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFDC3545)))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/community/posts/$postId');
      _loadPosts();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete')));
    }
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

  int _safeInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
