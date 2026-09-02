import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/domain/sn_image.dart';
import 'package:staynest_mobile/features/ai/data/ai_repository.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';
import 'package:staynest_mobile/core/utils/money.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key, this.initialPrompt});
  final String? initialPrompt;

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;
    _messages.add(ChatMessage(
      text: 'Hello $firstName! I\u2019m your StayNest AI assistant. I can help you find hostels, compare prices, or understand house rules.\n\nWhat can I help you find today?',
      isUser: false,
    ));
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialPrompt!);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;
    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text.trim(), isUser: true));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final repo = ref.read(aiRepositoryProvider);
      final response = await repo.chat(
        message: text.trim(),
        history: _messages
            .where((m) => m != _messages.last || m.isUser)
            .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
            .toList(),
      );
      setState(() {
        _messages.add(ChatMessage(
          text: response.message,
          isUser: false,
          hostels: response.hostels?.map((h) => AiHostelResult.fromJson(h as Map<String, dynamic>)).toList(),
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I couldn\u2019t process that right now. Please try again.',
          isUser: false,
        ));
      });
    } finally {
      setState(() => _isSending = false);
      _scrollToBottom();
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
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(c),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(SNSpace.screenX),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) return _buildTypingIndicator(c);
                  return _buildBubble(c, _messages[index]);
                },
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
            onTap: () => context.pop(),
          ),
          const SizedBox(width: SNSpace.x3),
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          ),
          const SizedBox(width: SNSpace.x3),
          Text('StayNest AI', style: SNText.headingMd.copyWith(color: c.foreground)),
        ],
      ),
    );
  }

  Widget _buildBubble(SNColorTokens c, ChatMessage msg) {
    if (msg.isUser) return _buildUserBubble(c, msg);
    return _buildAiBubble(c, msg);
  }

  Widget _buildUserBubble(SNColorTokens c, ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SNSpace.x4, left: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(SNSpace.x4),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                msg.text,
                style: SNText.body.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble(SNColorTokens c, ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SNSpace.x4, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          ),
          const SizedBox(width: SNSpace.x3),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(SNSpace.x4),
                  decoration: BoxDecoration(
                    color: c.card,
                    border: Border.all(color: c.border),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: SNText.body.copyWith(color: c.foreground, height: 1.5),
                  ),
                ),
                if (msg.hostels != null)
                  ...msg.hostels!.map((h) => _buildHostelCard(c, h)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostelCard(SNColorTokens c, AiHostelResult hostel) {
    return GestureDetector(
      onTap: () {
        context.pop();
        Future.microtask(() => context.push('/home/hostel/${hostel.id}'));
      },
      child: Container(
        margin: const EdgeInsets.only(top: SNSpace.x2),
        padding: const EdgeInsets.all(SNSpace.x3),
        decoration: BoxDecoration(
          color: c.muted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SNImage(
              url: hostel.imageUrl,
              variant: SNImageVariant.small,
              width: 48,
              height: 48,
              borderRadius: SNRadius.control,
            ),
            const SizedBox(width: SNSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hostel.name, style: SNText.caption.copyWith(color: c.foreground), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(Money.formatCompact(hostel.pricePesewas), style: SNText.microAction.copyWith(color: c.primary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(SNColorTokens c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SNSpace.x4, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          ),
          const SizedBox(width: SNSpace.x3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: SNSpace.x4, vertical: SNSpace.x3),
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0, color: c.mutedForeground),
                const SizedBox(width: 4),
                _Dot(delay: 150, color: c.mutedForeground),
                const SizedBox(width: 4),
                _Dot(delay: 300, color: c.mutedForeground),
              ],
            ),
          ),
        ],
      ),
    );
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
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: 'Ask anything...',
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
                onTap: () => _sendMessage(_controller.text),
                child: const Icon(Icons.send_rounded, size: 22, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data models ─────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isUser;
  final List<AiHostelResult>? hostels;
  ChatMessage({required this.text, required this.isUser, this.hostels});
}

class AiHostelResult {
  final String id;
  final String name;
  final int pricePesewas;
  final String? imageUrl;
  AiHostelResult({required this.id, required this.name, required this.pricePesewas, this.imageUrl});

  factory AiHostelResult.fromJson(Map<String, dynamic> json) {
    return AiHostelResult(
      id: json['id'],
      name: json['name'],
      pricePesewas: json['pricePesewas'] is String ? int.parse(json['pricePesewas']) : json['pricePesewas'],
      imageUrl: (json['imageUrls'] as List?)?.isNotEmpty == true ? json['imageUrls'][0] : null,
    );
  }
}

// ── Typing dots animation ───────────────────────────

class _Dot extends StatefulWidget {
  const _Dot({required this.delay, required this.color});
  final int delay;
  final Color color;
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: 0.3 + 0.7 * _anim.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
