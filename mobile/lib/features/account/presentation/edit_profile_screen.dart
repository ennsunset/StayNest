// features/account/presentation/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_surfaces.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';
import 'package:staynest_mobile/design/domain/sn_domain_bits.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String? _selectedLevel;
  String? _selectedUniversity;
  bool _changed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider);
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _selectedLevel = user?.level;
    _selectedUniversity = user?.university;
    _selectedUniversity = user?.university;
    _nameController.addListener(_markChanged);
    _phoneController.addListener(_markChanged);
  }

  void _markChanged() {
    final user = ref.read(authNotifierProvider);
    final changed = _nameController.text.trim() != (user?.fullName ?? '') ||
        _phoneController.text.trim() != (user?.phone ?? '') ||
        _selectedLevel != (user?.level) ||
        _selectedUniversity != (user?.university);
    if (changed != _changed) setState(() => _changed = changed);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();


    super.dispose();
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return parts[0][0] + parts[1][0];
    return name.isNotEmpty ? name[0] : '?';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final user = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Edit Profile',
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SNSpace.screenX),
              child: Column(
                children: [
                  SNAvatar(size: 80, initials: _initials(user?.fullName ?? 'S')),
                  const SizedBox(height: SNSpace.section),

                  _field(c, 'Full Name', _nameController),
                  const SizedBox(height: SNSpace.x5),
                  _field(c, 'Phone Number', _phoneController, keyboard: TextInputType.phone),
                  const SizedBox(height: SNSpace.x5),
                  _readOnlyField(c, 'Email', user?.email ?? ''),
                  const SizedBox(height: SNSpace.x5),
                  _universityPicker(c),
                  const SizedBox(height: SNSpace.x5),
                  _levelPicker(c),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(SNSpace.screenX),
            decoration: BoxDecoration(
              color: c.card,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: SafeArea(
              top: false,
              child: SNButton(
                label: 'Save Changes',
                isLoading: _saving,
                onPressed: _changed
                    ? () async {
                        setState(() => _saving = true);
                        try {
                          await ref.read(authNotifierProvider.notifier).updateProfile(
                            fullName: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            level: _selectedLevel,
                            university: _selectedUniversity,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated')),
                            );
                            context.pop();
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not update profile')),
                            );
                          }
                        }
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _universities = [
    'Academic City University College', 'Accra Technical University',
    'Akenten Appiah-Menka University of Skills Training', 'Ashesi University',
    'Bolgatanga Technical University', 'C.K. Tedam University of Technology and Applied Sciences',
    'Cape Coast Technical University', 'Central University',
    'Ghana Christian University College', 'Ghana Communication Technology University (GCTU)',
    'Ghana Institute of Journalism (GIJ)', 'Ghana Institute of Management and Public Administration (GIMPA)',
    'Ho Technical University', 'KNUST', 'Knutsford University College',
    'Koforidua Technical University', 'Kumasi Technical University', 'Lancaster University Ghana',
    'Methodist University College Ghana', 'Pentecost University',
    'Presbyterian University College, Ghana', 'Regent University College of Science and Technology',
    'SD Dombo University of Business and Integrated Development Studies',
    'Sunyani Technical University', 'Takoradi Technical University', 'Tamale Technical University',
    'UCC', 'UPSA (University of Professional Studies, Accra)',
    'University for Development Studies (UDS)', 'University of Education, Winneba (UEW)',
    'University of Energy and Natural Resources (UENR)', 'University of Ghana (Legon)',
    'University of Health and Allied Sciences (UHAS)', 'University of Mines and Technology (UMaT)',
    'Valley View University', 'Webster University Ghana',
    'Wisconsin International University College', 'Zenith University College', 'Other',
  ];

  Widget _universityPicker(SNColorTokens c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('University', style: SNText.bodyBold.copyWith(color: c.foreground)),
        const SizedBox(height: SNSpace.x2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: SNSpace.x5),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(SNRadius.sm),
            border: Border.all(color: c.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _universities.contains(_selectedUniversity) ? _selectedUniversity : null,
              hint: Text('Select university', style: SNText.body.copyWith(color: c.mutedForeground)),
              isExpanded: true,
              dropdownColor: c.card,
              style: SNText.body.copyWith(color: c.foreground),
              items: _universities.map((u) => DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) {
                setState(() => _selectedUniversity = v);
                _markChanged();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _levelPicker(SNColorTokens c) {
    const levels = ['Level 100', 'Level 200', 'Level 300', 'Level 400', 'Level 500', 'Level 600', 'Graduate'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Level', style: SNText.bodyBold.copyWith(color: c.foreground)),
        const SizedBox(height: SNSpace.x2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: SNSpace.x5),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(SNRadius.sm),
            border: Border.all(color: c.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: levels.contains(_selectedLevel) ? _selectedLevel : null,
              hint: Text('Select level', style: SNText.body.copyWith(color: c.mutedForeground)),
              isExpanded: true,
              dropdownColor: c.card,
              style: SNText.body.copyWith(color: c.foreground),
              items: levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) {
                setState(() => _selectedLevel = v);
                _markChanged();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(SNColorTokens c, String label, TextEditingController controller,
      {TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SNText.bodyBold.copyWith(color: c.foreground)),
        const SizedBox(height: SNSpace.x2),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: SNText.body.copyWith(color: c.foreground),
          decoration: InputDecoration(
            filled: true,
            fillColor: c.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SNRadius.sm),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SNRadius.sm),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SNRadius.sm),
              borderSide: BorderSide(color: c.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SNSpace.x5, vertical: SNSpace.x4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _readOnlyField(SNColorTokens c, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SNText.bodyBold.copyWith(color: c.foreground)),
        const SizedBox(height: SNSpace.x2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: SNSpace.x5, vertical: SNSpace.x4,
          ),
          decoration: BoxDecoration(
            color: c.muted,
            borderRadius: BorderRadius.circular(SNRadius.sm),
          ),
          child: Text(value, style: SNText.body.copyWith(color: c.mutedForeground)),
        ),
      ],
    );
  }
}
