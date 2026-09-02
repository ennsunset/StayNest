// design/primitives/sn_sheet_handle.dart

import 'package:flutter/material.dart';

/// Yango-style drag handle — 40×4 pill, 8px top / 4px bottom.
class SNSheetHandle extends StatelessWidget {
  const SNSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
