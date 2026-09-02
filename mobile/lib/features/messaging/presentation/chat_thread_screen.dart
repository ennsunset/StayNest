import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/messaging/data/messaging_repository.dart';
import 'package:staynest_mobile/features/messaging/presentation/messages_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/owner_messages_screen.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.conversationId, this.hostelName, this.currentUserId});
  final String conversationId;
  final String? hostelName;
  final String? currentUserId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages(silent: true));
  }

  void _invalidateConversations() {
    ref.invalidate(conversationsProvider);
    ref.invalidate(ownerConversationsProvider);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final msgs = await repo.getMessages(widget.conversationId);
      if (mounted) {
        final wasAtBottom = !_scrollController.hasClients ||
            _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50;
        setState(() {
          _messages = msgs;
          _loading = false;
        });
        if (wasAtBottom) _scrollToBottom();
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    try {
      final repo = ref.read(messagingRepositoryProvider);
      final msg = await repo.sendMessage(widget.conversationId, text);
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final userId = widget.currentUserId ?? ref.watch(authNotifierProvider)?.id;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(c),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(SNSpace.screenX),
                            child: Text(
                              'No messages yet. Say hello!',
                              style: SNText.body.copyWith(color: c.mutedForeground),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(SNSpace.screenX),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => _buildBubble(c, _messages[i], userId),
                        ),
            ),
            _buildInput(c),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SNColorTokens c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX, vertical: SNSpace.x3),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          SNCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              _invalidateConversations();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: SNSpace.x3),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.muted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                (widget.hostelName ?? '??').substring(0, 2).toUpperCase(),
                style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: SNSpace.x3),
          Expanded(
            child: Text(
              widget.hostelName ?? 'Chat',
              style: SNText.headingMd.copyWith(color: c.foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(SNColorTokens c, ChatMessage msg, String? userId) {
    final isMe = msg.senderId == userId;
    return Padding(
      padding: EdgeInsets.only(
        bottom: SNSpace.x3,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: SNSpace.x4, vertical: SNSpace.x3),
          decoration: BoxDecoration(
            color: isMe ? c.primary : c.card,
            border: isMe ? null : Border.all(color: c.border),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                msg.body,
                style: SNText.body.copyWith(color: isMe ? Colors.white : c.foreground),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(msg.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : c.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildInput(SNColorTokens c) {
    return Container(
      padding: const EdgeInsets.all(SNSpace.screenX),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: SNText.body.copyWith(color: c.mutedForeground),
                filled: true,
                fillColor: c.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: SNSpace.x5, vertical: SNSpace.x4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: c.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: SNSpace.x3),
          SizedBox(
            height: 52,
            width: 52,
            child: Material(
              color: c.primary,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _sendMessage,
                child: const Icon(Icons.send_rounded, size: 22, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
