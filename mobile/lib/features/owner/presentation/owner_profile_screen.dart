import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';

class OwnerProfileScreen extends ConsumerWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sn;
    final user = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SingleChildScrollView(child: Column(children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(height: 220, width: double.infinity, decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1C2B41), Color(0xFF2A3F5A)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          )),
          Positioned(top: MediaQuery.of(context).padding.top + 8, left: 16, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop())),
          Positioned(bottom: -40, left: 24, child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
            child: CircleAvatar(radius: 44, backgroundColor: c.muted, child: Text(user?.fullName.substring(0, 1).toUpperCase() ?? 'O', style: SNText.headingLg.copyWith(color: c.foreground))),
          )),
          Positioned(bottom: 20, left: 130, right: 24, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(user?.fullName ?? 'Owner', style: SNText.headingMd.copyWith(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              Icon(Icons.verified, color: c.primary, size: 20),
            ]),
            const SizedBox(height: 2),
            Text('VERIFIED STAYNEST PARTNER', style: SNText.microAction.copyWith(color: Colors.white70, letterSpacing: 1.2)),
          ])),
        ]),
        const SizedBox(height: 56),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: IntrinsicHeight(child: Row(children: [
          _stat(c, '02', 'PROPERTIES'),
          VerticalDivider(width: 1, thickness: 1, color: c.border),
          _stat(c, '4.0', 'RATING'),
        ]))),
        const SizedBox(height: 28),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ABOUT MANAGEMENT', style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SNCard(child: Text('"Committed to providing premium student housing with a focus on safety and academic excellence."', style: SNText.body.copyWith(color: c.foreground, height: 1.6, fontStyle: FontStyle.italic))),
        ])),
        const SizedBox(height: 28),
        Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 40), child: Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => context.go('/owner/messages'),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(16)), child: Center(child: Text('CONTACT MANAGER', style: SNText.bodyBold.copyWith(color: c.primaryForeground, fontSize: 12, letterSpacing: 1.5)))),
          )),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share coming soon'))),
            child: Container(width: 54, height: 54, decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(16)), child: Icon(Icons.ios_share, color: c.foreground, size: 22)),
          ),
        ])),
      ])),
    );
  }

  Widget _stat(SNColorTokens c, String value, String label) {
    return Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: SNText.headingLg.copyWith(color: c.foreground)),
      const SizedBox(height: 2),
      Text(label, style: SNText.microAction.copyWith(color: c.mutedForeground, letterSpacing: 1.2)),
    ]));
  }
}
