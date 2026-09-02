// design/primitives/sn_date_picker.dart

import 'package:flutter/material.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';

Future<DateTime?> showSNDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SNDatePickerSheet(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class _SNDatePickerSheet extends StatefulWidget {
  const _SNDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_SNDatePickerSheet> createState() => _SNDatePickerSheetState();
}

class _SNDatePickerSheetState extends State<_SNDatePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _viewMonth;

  static const _months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  static const _days = ['M','T','W','T','F','S','S'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _viewMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
    });
  }

  bool _isSelectable(DateTime d) {
    return !d.isBefore(DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day)) &&
           !d.isAfter(widget.lastDate);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    // Build calendar grid
    final firstDayOfMonth = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    // Monday = 1, Sunday = 7 → offset
    final startWeekday = (firstDayOfMonth.weekday - 1) % 7;

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(SNSpace.screenX, 12, SNSpace.screenX, SNSpace.screenX),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Select Check-in Date',
                style: SNText.headingMd.copyWith(color: c.foreground, fontSize: 18),
              ),
              const SizedBox(height: 24),

              // Month nav
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _prevMonth,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.chevron_left, color: c.foreground, size: 20),
                    ),
                  ),
                  Text(
                    '${_months[_viewMonth.month - 1]} ${_viewMonth.year}',
                    style: SNText.bodyBold.copyWith(color: c.foreground, fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: _nextMonth,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.chevron_right, color: c.foreground, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Day headers
              Row(
                children: _days.map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: SNText.caption.copyWith(
                        color: c.mutedForeground,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 8),

              // Calendar grid
              ...List.generate(6, (week) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: List.generate(7, (dayIndex) {
                      final dayNum = week * 7 + dayIndex - startWeekday + 1;
                      if (dayNum < 1 || dayNum > daysInMonth) {
                        return const Expanded(child: SizedBox(height: 44));
                      }

                      final date = DateTime(_viewMonth.year, _viewMonth.month, dayNum);
                      final isSelected = date.year == _selectedDate.year &&
                          date.month == _selectedDate.month &&
                          date.day == _selectedDate.day;
                      final isToday = date.year == DateTime.now().year &&
                          date.month == DateTime.now().month &&
                          date.day == DateTime.now().day;
                      final selectable = _isSelectable(date);

                      return Expanded(
                        child: GestureDetector(
                          onTap: selectable ? () => setState(() => _selectedDate = date) : null,
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected ? c.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '$dayNum',
                                style: SNText.body.copyWith(
                                  color: isSelected
                                      ? c.primaryForeground
                                      : !selectable
                                          ? c.mutedForeground.withValues(alpha: 0.3)
                                          : isToday
                                              ? c.primary
                                              : c.foreground,
                                  fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Selected date display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SNSpace.x4),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: c.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${_days[(_selectedDate.weekday - 1) % 7]}  ${_selectedDate.day} ${_months[_selectedDate.month - 1]} ${_selectedDate.year}',
                      style: SNText.bodyBold.copyWith(color: c.primary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Confirm button
              GestureDetector(
                onTap: () => Navigator.pop(context, _selectedDate),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Confirm Date',
                      style: SNText.bodyBold.copyWith(color: c.primaryForeground, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
