// design/primitives/sn_picker_sheet.dart

import 'package:flutter/material.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';

class SNPickerSheet extends StatefulWidget {
  const SNPickerSheet({
    super.key,
    required this.title,
    required this.items,
    this.selected,
    this.searchable = false,
  });

  final String title;
  final List<String> items;
  final String? selected;
  final bool searchable;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<String> items,
    String? selected,
    bool searchable = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SNPickerSheet(
        title: title,
        items: items,
        selected: selected,
        searchable: searchable,
      ),
    );
  }

  @override
  State<SNPickerSheet> createState() => _SNPickerSheetState();
}

class _SNPickerSheetState extends State<SNPickerSheet> {
  final _searchCtl = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.items;
      } else {
        _filtered = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SNRadius.lg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SNSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SNSpace.screenX, SNSpace.x5, SNSpace.screenX, SNSpace.x4,
            ),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: SNText.headingMd.copyWith(color: c.foreground),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.muted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 16, color: c.mutedForeground),
                  ),
                ),
              ],
            ),
          ),

          if (widget.searchable) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
              child: TextField(
                controller: _searchCtl,
                onChanged: _onSearch,
                style: SNText.body.copyWith(color: c.foreground),
                cursorColor: c.primary,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: SNText.body.copyWith(color: c.mutedForeground),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: c.mutedForeground),
                  prefixIconConstraints: const BoxConstraints(minWidth: 44),
                  suffixIcon: _searchCtl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtl.clear();
                            _onSearch('');
                          },
                          child: Icon(Icons.close_rounded, size: 18, color: c.mutedForeground),
                        )
                      : null,
                  filled: true,
                  fillColor: c.muted,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: SNSpace.x3),
          ],

          Divider(height: 1, color: c.border),

          Flexible(
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(SNSpace.x8),
                    child: Text(
                      'No results',
                      style: SNText.body.copyWith(color: c.mutedForeground),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: SNSpace.x1),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
                      child: Divider(height: 1, color: c.border.withValues(alpha: 0.5)),
                    ),
                    itemBuilder: (ctx, i) {
                      final item = _filtered[i];
                      final isSelected = item == widget.selected;
                      return GestureDetector(
                        onTap: () => Navigator.pop(context, item),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SNSpace.screenX,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item,
                                  style: SNText.body.copyWith(
                                    color: isSelected ? c.primary : c.foreground,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: c.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + SNSpace.x4),
        ],
      ),
    );
  }
}
