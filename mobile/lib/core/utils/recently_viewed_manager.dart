import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentlyViewedItem {
  final String hostelId;
  final String name;
  final String? imageUrl;
  final int pricePesewas;
  final double rating;
  final DateTime viewedAt;

  RecentlyViewedItem({
    required this.hostelId,
    required this.name,
    this.imageUrl,
    required this.pricePesewas,
    required this.rating,
    required this.viewedAt,
  });

  Map<String, dynamic> toJson() => {
        'hostelId': hostelId,
        'name': name,
        'imageUrl': imageUrl,
        'pricePesewas': pricePesewas,
        'rating': rating,
        'viewedAt': viewedAt.toIso8601String(),
      };

  factory RecentlyViewedItem.fromJson(Map<String, dynamic> json) =>
      RecentlyViewedItem(
        hostelId: json['hostelId'] as String,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String?,
        pricePesewas: json['pricePesewas'] as int,
        rating: (json['rating'] as num).toDouble(),
        viewedAt: DateTime.parse(json['viewedAt'] as String),
      );
}

class RecentlyViewedManager {
  static const _key = 'recently_viewed_hostels';
  static const _maxItems = 20;

  static Future<List<RecentlyViewedItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) {
      try {
        return RecentlyViewedItem.fromJson(
            jsonDecode(e) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<RecentlyViewedItem>().toList();
  }

  static Future<void> add(RecentlyViewedItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getAll();
    // Remove duplicate
    items.removeWhere((i) => i.hostelId == item.hostelId);
    // Insert at top
    items.insert(0, item);
    // Trim to max
    if (items.length > _maxItems) {
      items.removeRange(_maxItems, items.length);
    }
    await prefs.setStringList(
      _key,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> remove(String hostelId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getAll();
    items.removeWhere((i) => i.hostelId == hostelId);
    await prefs.setStringList(
      _key,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
