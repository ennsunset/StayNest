import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/primitives/sn_feedback.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';

const _kSearchHistoryKey = 'search_history';

class SearchHistoryEntry {
  final String query;
  final int filterCount;
  final DateTime timestamp;

  SearchHistoryEntry({required this.query, this.filterCount = 0, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'query': query,
    'filterCount': filterCount,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) => SearchHistoryEntry(
    query: json['query'] as String,
    filterCount: json['filterCount'] as int? ?? 0,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class SearchHistoryManager {
  static Future<List<SearchHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSearchHistoryKey) ?? [];
    return raw.map((s) => SearchHistoryEntry.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  static Future<void> add(String query, {int filterCount = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await load();
    entries.removeWhere((e) => e.query.toLowerCase() == query.toLowerCase());
    entries.insert(0, SearchHistoryEntry(query: query, filterCount: filterCount, timestamp: DateTime.now()));
    if (entries.length > 20) entries.removeRange(20, entries.length);
    await prefs.setStringList(_kSearchHistoryKey, entries.map((e) => jsonEncode(e.toJson())).toList());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSearchHistoryKey);
  }
}

class SearchHistoryScreen extends StatefulWidget {
  const SearchHistoryScreen({super.key});

  @override
  State<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends State<SearchHistoryScreen> {
  List<SearchHistoryEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await SearchHistoryManager.load();
    if (mounted) setState(() { _entries = entries; _loading = false; });
  }

  Future<void> _clear() async {
    await SearchHistoryManager.clear();
    if (mounted) setState(() => _entries = []);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Search History',
        onBack: () => context.pop(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: SNEmptyState(
                    icon: Icons.search_off_rounded,
                    headline: 'No search history',
                    actionLabel: 'Start searching',
                    onAction: () => context.pop(),
                  ),
                )
              : _buildList(c),
    );
  }

  Widget _buildList(SNColorTokens c) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.navClear,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT QUERIES',
              style: SNText.microAction.copyWith(
                color: c.mutedForeground,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
              ),
            ),
            GestureDetector(
              onTap: _clear,
              child: Text(
                'CLEAR HISTORY',
                style: SNText.microAction.copyWith(
                  color: c.destructive,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: SNSpace.x4),
        ..._entries.map(_buildEntry),
        const SizedBox(height: SNSpace.section),
        _buildAiCard(c),
      ],
    );
  }

  Widget _buildEntry(SearchHistoryEntry entry) {
    final c = context.sn;
    return Padding(
      padding: const EdgeInsets.only(bottom: SNSpace.x3),
      child: Dismissible(
        key: ValueKey(entry.query),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: SNSpace.x4),
          decoration: BoxDecoration(
            color: c.destructive.withOpacity(0.1),
            borderRadius: BorderRadius.circular(SNRadius.lg),
          ),
          child: Icon(Icons.delete_outline, color: c.destructive),
        ),
        onDismissed: (_) async {
          setState(() => _entries.removeWhere((e) => e.query == entry.query));
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(_kSearchHistoryKey,
            _entries.map((e) => jsonEncode(e.toJson())).toList());
        },
        child: SNCard(
          onTap: () {
            // Pop back to profile, user navigates to explore to search
            context.go("/home/search-results?q=${Uri.encodeComponent(entry.query)}");
          },
          padding: const EdgeInsets.all(SNSpace.x4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.muted,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search, size: 20, color: c.mutedForeground),
              ),
              const SizedBox(width: SNSpace.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.query.toUpperCase(),
                      style: SNText.bodyBold.copyWith(
                        color: c.foreground,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.filterCount > 0 ? "${entry.filterCount} FILTERS APPLIED \u2022 " : ""}${_timeAgo(entry.timestamp).toUpperCase()}',
                      style: SNText.microAction.copyWith(
                        color: c.mutedForeground,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.mutedForeground, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiCard(SNColorTokens c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI SUGGESTIONS FOR YOU',
          style: SNText.microAction.copyWith(
            color: c.mutedForeground,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: SNSpace.x4),
        GestureDetector(
          onTap: () => context.push('${Routes.aiChat}?q=${Uri.encodeComponent("Hostels with fiber wifi")}'),
          child: Container(
            padding: const EdgeInsets.all(SNSpace.x6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.primary, c.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(SNRadius.xxl),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(Icons.auto_awesome, size: 80, color: Colors.white.withOpacity(0.1)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRY: "HOSTELS WITH FIBER WIFI"',
                      style: SNText.bodyBold.copyWith(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: SNSpace.x2),
                    Text(
                      'We noticed you frequently filter for high-speed internet.',
                      style: SNText.caption.copyWith(color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: SNSpace.x4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: SNSpace.x5, vertical: SNSpace.x3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(SNRadius.pill),
                      ),
                      child: Text(
                        'START AI SEARCH',
                        style: SNText.microAction.copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
