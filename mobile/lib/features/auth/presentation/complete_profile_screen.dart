// features/auth/presentation/complete_profile_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/primitives/sn_picker_sheet.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/features/auth/data/auth_repository.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends ConsumerState<CompleteProfileScreen> {
  String? _university;
  String? _level;
  final _selectedInterests = <String>{};
  bool _loading = false;
  String? _errorText;

  static const _universities = [
    'Academic City University College',
    'Accra Technical University',
    'Akenten Appiah-Menka University of Skills Training',
    'Ashesi University',
    'Bolgatanga Technical University',
    'C.K. Tedam University of Technology and Applied Sciences',
    'Cape Coast Technical University',
    'Central University',
    'Ghana Christian University College',
    'Ghana Communication Technology University (GCTU)',
    'Ghana Institute of Journalism (GIJ)',
    'Ghana Institute of Management and Public Administration (GIMPA)',
    'Ho Technical University',
    'KNUST',
    'Knutsford University College',
    'Koforidua Technical University',
    'Kumasi Technical University',
    'Lancaster University Ghana',
    'Methodist University College Ghana',
    'Pentecost University',
    'Presbyterian University College, Ghana',
    'Regent University College of Science and Technology',
    'SD Dombo University of Business and Integrated Development Studies',
    'Sunyani Technical University',
    'Takoradi Technical University',
    'Tamale Technical University',
    'UCC',
    'UPSA (University of Professional Studies, Accra)',
    'University for Development Studies (UDS)',
    'University of Education, Winneba (UEW)',
    'University of Energy and Natural Resources (UENR)',
    'University of Ghana (Legon)',
    'University of Health and Allied Sciences (UHAS)',
    'University of Mines and Technology (UMaT)',
    'Valley View University',
    'Webster University Ghana',
    'Wisconsin International University College',
    'Zenith University College',
    'Other',
  ];

  static const _levels = [
    'Level 100',
    'Level 200',
    'Level 300',
    'Level 400',
    'Postgraduate',
  ];

  static const _interests = [
    ('Sports', Icons.sports_soccer),
    ('Arts', Icons.palette_outlined),
    ('Academics', Icons.menu_book_outlined),
    ('Gaming', Icons.sports_esports_outlined),
    ('Music', Icons.music_note_outlined),
    ('Tech', Icons.computer_outlined),
    ('Social', Icons.people_outline),
    ('Fitness', Icons.fitness_center_outlined),
  ];

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.completeProfile(
        university: _university,
        level: _level,
        interests: _selectedInterests.toList(),
      );
      if (!mounted) return;
      context.go(Routes.home);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['message'];
      setState(() {
        _loading = false;
        _errorText = msg is String ? msg : 'Something went wrong.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = 'Something went wrong.';
      });
    }
  }

  void _skip() => context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Your Profile',
        trailing: GestureDetector(
          onTap: _skip,
          child: Padding(
            padding: const EdgeInsets.all(SNSpace.x2),
            child: Text(
              'SKIP',
              style: SNText.microAction.copyWith(color: c.primary),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: SNSpace.x6),

            // ── Avatar ──
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: c.muted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 40,
                      color: c.mutedForeground,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // PHASE2: image picker
                      },
                      child: Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.background, width: 3),
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 16,
                          color: c.primaryForeground,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: SNSpace.x8),

            // ── University ──
            SNSectionLabel('University'),
            const SizedBox(height: SNSpace.x2),
            _Dropdown(
              title: 'University',
              hint: 'Select your university',
              value: _university,
              items: _universities,
              onChanged: (v) => setState(() => _university = v),
            ),

            const SizedBox(height: SNSpace.x6),

            // ── Level ──
            SNSectionLabel('Level / Year'),
            const SizedBox(height: SNSpace.x2),
            Wrap(
              spacing: SNSpace.x3,
              runSpacing: SNSpace.x3,
              children: _levels.map((lvl) {
                final selected = _level == lvl;
                return SNChip(
                  label: lvl,
                  selected: selected,
                  onTap: () => setState(() => _level = selected ? null : lvl),
                );
              }).toList(),
            ),

            const SizedBox(height: SNSpace.x6),

            // ── Interests ──
            SNSectionLabel('Interests'),
            const SizedBox(height: SNSpace.x2),
            Text(
              'Help us recommend hostels that match your lifestyle',
              style: SNText.caption.copyWith(color: c.mutedForeground),
            ),
            const SizedBox(height: SNSpace.x4),
            Wrap(
              spacing: SNSpace.x3,
              runSpacing: SNSpace.x3,
              children: _interests.map((item) {
                final (label, icon) = item;
                final selected = _selectedInterests.contains(label);
                return SNChip(
                  label: label,
                  icon: icon,
                  selected: selected,
                  onTap: () => setState(() {
                    selected
                        ? _selectedInterests.remove(label)
                        : _selectedInterests.add(label);
                  }),
                );
              }).toList(),
            ),

            if (_errorText != null) ...[
              const SizedBox(height: SNSpace.x4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SNSpace.x4),
                decoration: BoxDecoration(
                  color: c.destructive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(SNRadius.sm),
                ),
                child: Text(
                  _errorText!,
                  style: SNText.caption.copyWith(color: c.destructive),
                ),
              ),
            ],

            const SizedBox(height: SNSpace.x10),

            SNButton(
              label: 'Complete Profile',
              onPressed: _submit,
              isLoading: _loading,
            ),

            const SizedBox(height: SNSpace.section),
          ],
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.title,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return GestureDetector(
      onTap: () async {
        final result = await SNPickerSheet.show(
          context,
          title: title,
          items: items,
          selected: value,
          searchable: true,
        );
        if (result != null) onChanged(result);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: SNSpace.x4,
          vertical: SNSpace.x4,
        ),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: SNRadius.control,
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: SNText.body.copyWith(
                  color: value != null ? c.foreground : c.mutedForeground,
                ),
              ),
            ),
            Icon(Icons.expand_more, size: 20, color: c.mutedForeground),
          ],
        ),
      ),
    );
  }
}
