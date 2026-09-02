import 'package:flutter/material.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';

Future<String?> showSNTimePicker({
  required BuildContext context,
  required String title,
  String? initialTime,
}) {
  final parts = (initialTime != null && initialTime.contains(':'))
      ? initialTime.split(':')
      : ['12', '00'];
  int selectedHour = int.tryParse(parts[0]) ?? 12;
  int selectedMinute = int.tryParse(parts[1]) ?? 0;

  final c = context.sn;

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: c.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      final hourCtrl = FixedExtentScrollController(initialItem: selectedHour);
      final minuteCtrl = FixedExtentScrollController(initialItem: selectedMinute ~/ 5);

      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          String formatted =
              '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: SNSpace.x4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SNSheetHandle(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: SNText.headingMd.copyWith(color: c.foreground),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: c.mutedForeground),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SNSpace.x2),
                  SizedBox(
                    height: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hour wheel
                        SizedBox(
                          width: 80,
                          child: ListWheelScrollView.useDelegate(
                            controller: hourCtrl,
                            itemExtent: 48,
                            physics: const FixedExtentScrollPhysics(),
                            diameterRatio: 1.5,
                            onSelectedItemChanged: (i) {
                              setSheetState(() => selectedHour = i);
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 24,
                              builder: (_, i) {
                                final isSelected = i == selectedHour;
                                return Center(
                                  child: Text(
                                    i.toString().padLeft(2, '0'),
                                    style: SNText.headingLg.copyWith(
                                      color: isSelected ? c.primary : c.mutedForeground,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                                      fontSize: isSelected ? 28 : 20,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            ':',
                            style: SNText.headingLg.copyWith(
                              color: c.foreground,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        // Minute wheel (5-min intervals)
                        SizedBox(
                          width: 80,
                          child: ListWheelScrollView.useDelegate(
                            controller: minuteCtrl,
                            itemExtent: 48,
                            physics: const FixedExtentScrollPhysics(),
                            diameterRatio: 1.5,
                            onSelectedItemChanged: (i) {
                              setSheetState(() => selectedMinute = i * 5);
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 12,
                              builder: (_, i) {
                                final val = i * 5;
                                final isSelected = val == selectedMinute;
                                return Center(
                                  child: Text(
                                    val.toString().padLeft(2, '0'),
                                    style: SNText.headingLg.copyWith(
                                      color: isSelected ? c.primary : c.mutedForeground,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                                      fontSize: isSelected ? 28 : 20,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Selection highlight label
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: SNSpace.x2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: SNSpace.x4, vertical: SNSpace.x2),
                      decoration: BoxDecoration(
                        color: c.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        formatted,
                        style: SNText.headingMd.copyWith(color: c.primary, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: SNSpace.x2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SNButton(
                      label: 'Confirm',
                      onPressed: () => Navigator.pop(ctx, formatted),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
