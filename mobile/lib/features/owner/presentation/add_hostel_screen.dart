// features/owner/presentation/add_hostel_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:staynest_mobile/core/data/ghana_locations.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';
import 'package:staynest_mobile/design/primitives/sn_map_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:staynest_mobile/design/primitives/sn_time_picker.dart';
import 'package:staynest_mobile/design/primitives/sn_input.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';
import 'package:staynest_mobile/features/owner/data/owner_repository.dart';

class AddHostelScreen extends ConsumerStatefulWidget {
  const AddHostelScreen({super.key, this.hostelId, this.initialData});

  final String? hostelId;
  final Map<String, dynamic>? initialData;

  @override
  ConsumerState<AddHostelScreen> createState() => _AddHostelScreenState();
}

class _AddHostelScreenState extends ConsumerState<AddHostelScreen> {
  int _step = 0;
  bool _submitting = false;

  bool get _isEditMode => widget.hostelId != null;
  String get _initialStatus => widget.initialData?['status'] as String? ?? 'DRAFT';

  // Step 1 — Details
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _digitalAddrCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _region = 'Ashanti Region';
  String _city = 'Kumasi';
  String _area = '';
  String _genderPolicy = 'MIXED';
  int _floorCount = 1;
  String _gateOpeningTime = '';
  String _gateClosingTime = '';
  String _cancellationPolicy = 'FLEXIBLE';
  final _houseRulesCtrl = TextEditingController();
  final List<String> _houseRulesList = [];
  final Set<String> _selectedAmenities = {};
  double? _latitude;
  double? _longitude;

  // Step 2 — Photos
  final List<File> _pickedImages = [];
  final List<String> _existingImageUrls = [];
  final List<String> _uploadedUrls = [];
  bool _uploading = false;

  static const _amenities = [
    ('e833bcd2-6275-4fd3-a607-f9b22812ccb1', 'WiFi', Icons.wifi_rounded),
    ('3de8ec74-41d4-4b8f-982c-565aef00866b', 'Backup Power', Icons.bolt_rounded),
    ('3580bc59-9009-462d-87e9-077994624703', 'Security', Icons.shield_outlined),
    ('4647ba21-851a-45df-ac35-68f5e4b75b3c', 'Laundry', Icons.local_laundry_service_rounded),
    ('a31320dc-53e2-4222-8411-c1c7398eac67', 'Water Supply', Icons.water_drop_outlined),
    ('4b364670-1789-464f-96f4-f8d7129e4dca', 'Study Room', Icons.menu_book_rounded),
    ('f7940281-7ab7-4893-bc18-f38a983f14d3', 'Kitchen', Icons.kitchen_rounded),
  ];

  static const _genderOptions = [
    ('MIXED', 'Mixed'),
    ('MALE', 'Men Only'),
    ('FEMALE', 'Women Only'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _nameCtrl.text = d['name'] as String? ?? '';
      _addressCtrl.text = d['address'] as String? ?? '';
      _digitalAddrCtrl.text = d['digitalAddress'] as String? ?? '';
      _landmarkCtrl.text = d['landmark'] as String? ?? '';
      _descCtrl.text = d['description'] as String? ?? '';
      _region = d['region'] as String? ?? 'Ashanti Region';
      _city = d['city'] as String? ?? 'Kumasi';
      _area = d['area'] as String? ?? '';
      _genderPolicy = d['genderPolicy'] as String? ?? 'MIXED';
      _floorCount = (d['floorCount'] as int?) ?? 1;
      _gateOpeningTime = d['gateOpeningTime'] as String? ?? '';
      _gateClosingTime = d['gateClosingTime'] as String? ?? '';
      _cancellationPolicy = d['cancellationPolicy'] as String? ?? 'FLEXIBLE';
      _latitude = (d['latitude'] as num?)?.toDouble();
      _longitude = (d['longitude'] as num?)?.toDouble();
      final rules = d['houseRules'];
      if (rules is List) {
        _houseRulesList.addAll(rules.cast<String>());
      } else if (rules is String && rules.trim().isNotEmpty) {
        _houseRulesList.addAll(rules.split('\n').where((r) => r.trim().isNotEmpty));
      }
      final aids = d['amenityIds'];
      if (aids is List) _selectedAmenities.addAll(aids.cast<String>());
      final imgs = d['imageUrls'];
      if (imgs is List) _existingImageUrls.addAll(imgs.cast<String>());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _digitalAddrCtrl.dispose();
    _landmarkCtrl.dispose();
    _descCtrl.dispose();
    _houseRulesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80, maxWidth: 1600);
    if (picked.isNotEmpty) {
      setState(() => _pickedImages.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1600);
    if (picked != null) setState(() => _pickedImages.add(File(picked.path)));
  }

  Future<void> _uploadAndProceed() async {
    final repo = ref.read(ownerRepositoryProvider);
    setState(() => _uploading = true);
    try {
      final newUrls = <String>[];
      for (final f in _pickedImages) {
        final url = await repo.uploadImage(f.path);
        newUrls.add(url);
      }
      _uploadedUrls
        ..clear()
        ..addAll(_existingImageUrls)
        ..addAll(newUrls);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
      setState(() => _uploading = false);
      return;
    }
    setState(() {
      _uploading = false;
      _step = 2;
    });
  }

  int get _totalPhotoCount => _existingImageUrls.length + _pickedImages.length;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final repo = ref.read(ownerRepositoryProvider);
      final user = ref.read(authNotifierProvider);

      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _city,
        'region': _region,
        if (_area.isNotEmpty) 'area': _area,
        'landmark': _landmarkCtrl.text.trim().isNotEmpty ? _landmarkCtrl.text.trim() : null,
        'digitalAddress': _digitalAddrCtrl.text.trim().isNotEmpty ? _digitalAddrCtrl.text.trim() : null,
        'description': _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        'genderPolicy': _genderPolicy,
        if (_gateOpeningTime.isNotEmpty) 'gateOpeningTime': _gateOpeningTime,
        if (_gateClosingTime.isNotEmpty) 'gateClosingTime': _gateClosingTime,
        'cancellationPolicy': _cancellationPolicy,
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
        if (_houseRulesList.isNotEmpty) 'houseRules': _houseRulesList,
        'university': user?.university,
        'amenityIds': _selectedAmenities.toList(),
        'imageUrls': _uploadedUrls,
      };

      if (_isEditMode) {
        await repo.updateHostel(widget.hostelId!, data);
        if (_initialStatus == 'REJECTED' || _initialStatus == 'DRAFT') {
          await repo.submitHostel(widget.hostelId!);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_initialStatus == 'REJECTED' ? 'Hostel resubmitted for review!' : 'Hostel updated!')),
          );
        }
      } else {
        data['floorCount'] = _floorCount;
        data['bookingMode'] = 'FLEXIBLE';
        final result = await repo.createHostel(
          name: data['name'], address: data['address'], city: data['city'],
          region: data['region'], area: data['area'], landmark: data['landmark'],
          digitalAddress: data['digitalAddress'], description: data['description'],
          genderPolicy: _genderPolicy, university: user?.university,
          amenityIds: _selectedAmenities.toList(), imageUrls: _uploadedUrls, floorCount: _floorCount,
        );
        final hostelId = result['id'] as String;
        await repo.submitHostel(hostelId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hostel submitted for review!')));
        }
      }
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
    if (mounted) setState(() => _submitting = false);
  }

  bool get _detailsValid => _nameCtrl.text.trim().isNotEmpty && _addressCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.close, color: c.foreground), onPressed: () => context.pop()),
        title: Text(_isEditMode ? 'Edit Property' : 'Add New Property', style: SNText.headingMd.copyWith(color: c.foreground)),
      ),
      body: Column(
        children: [
          _buildStepper(c),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SNSpace.screenX),
              child: _step == 0 ? _buildDetails(c) : _step == 1 ? _buildPhotos(c) : _buildReview(c),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(SNSpace.screenX),
              child: _step == 0
                  ? SNButton(label: 'Next: Photos', onPressed: _detailsValid ? () => setState(() => _step = 1) : null)
                  : _step == 1
                      ? SNButton(
                          label: _pickedImages.isEmpty && _existingImageUrls.isNotEmpty ? 'Next: Review' : 'Upload & Review',
                          isLoading: _uploading,
                          onPressed: _totalPhotoCount == 0
                              ? null
                              : _pickedImages.isEmpty
                                  ? () {
                                      _uploadedUrls..clear()..addAll(_existingImageUrls);
                                      setState(() => _step = 2);
                                    }
                                  : _uploadAndProceed,
                        )
                      : SNButton(label: _submitLabel, isLoading: _submitting, onPressed: _submit),
            ),
          ),
        ],
      ),
    );
  }

  String get _submitLabel {
    if (!_isEditMode) return 'Submit for Review';
    if (_initialStatus == 'REJECTED') return 'Save & Resubmit';
    if (_initialStatus == 'DRAFT') return 'Save & Submit';
    return 'Save Changes';
  }

  // ── Stepper ──

  Widget _buildStepper(SNColorTokens c) {
    const labels = ['Details', 'Photos', 'Review'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SNSpace.x6, vertical: SNSpace.x3),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border, width: 1))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(5, (i) {
          if (i.isOdd) {
            final stepBefore = i ~/ 2;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(height: 2, color: stepBefore < _step ? c.primary : c.muted),
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final active = stepIdx <= _step;
          return GestureDetector(
            onTap: stepIdx < _step ? () => setState(() => _step = stepIdx) : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: active ? c.primary : c.muted,
                  child: Text('${stepIdx + 1}', style: SNText.caption.copyWith(color: active ? c.primaryForeground : c.mutedForeground, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
                const SizedBox(height: 4),
                Text(labels[stepIdx].toUpperCase(), style: SNText.caption.copyWith(color: active ? c.primary : c.mutedForeground, fontWeight: FontWeight.w800, fontSize: 9)),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Picker helper ──

  Widget _pickerField(SNColorTokens c, String label, String value, VoidCallback onTap, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 10)),
        const SizedBox(height: SNSpace.x2),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
            child: Row(
              children: [
                Expanded(child: Text(value.isNotEmpty ? value : (hint ?? 'Select...'), style: SNText.body.copyWith(color: value.isNotEmpty ? c.foreground : c.mutedForeground))),
                Icon(Icons.keyboard_arrow_down, color: c.mutedForeground),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showListPicker(SNColorTokens c, String title, List<String> items, String current, ValueChanged<String> onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        String filter = '';
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final filtered = filter.isEmpty ? items : items.where((i) => i.toLowerCase().contains(filter.toLowerCase())).toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.85,
            minChildSize: 0.3,
            expand: false,
            builder: (_, scrollCtrl) => Column(
              children: [
                const SNSheetHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(title, style: SNText.headingMd.copyWith(color: c.foreground))),
                      IconButton(icon: Icon(Icons.close, color: c.mutedForeground), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                if (items.length > 8)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: SNText.body.copyWith(color: c.mutedForeground),
                        prefixIcon: Icon(Icons.search, color: c.mutedForeground, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: c.background,
                      ),
                      style: SNText.body.copyWith(color: c.foreground),
                      onChanged: (v) => setSheetState(() => filter = v),
                    ),
                  ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(filtered[i], style: SNText.body.copyWith(color: c.foreground)),
                      trailing: filtered[i] == current ? Icon(Icons.check, color: c.primary) : null,
                      onTap: () {
                        onSelect(filtered[i]);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showCustomTimePicker(String label, String current, ValueChanged<String> onSelect) async {
    final result = await showSNTimePicker(
      context: context,
      title: label,
      initialTime: current.isNotEmpty ? current : null,
    );
    if (result != null) onSelect(result);
  }

  // ── Step 1: Details ──

  Widget _buildDetails(SNColorTokens c) {
    final citiesForRegion = GhanaLocations.getCities(_region);
    final areasForCity = GhanaLocations.getAreas(_city);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SNInput(label: 'Hostel Name', hint: 'e.g. Royal Heights', controller: _nameCtrl, onChanged: (_) => setState(() {})),
        const SizedBox(height: SNSpace.x4),
        _pickerField(c, 'Region', _region, () {
          _showListPicker(c, 'Select Region', GhanaLocations.regions, _region, (v) {
            setState(() {
              _region = v;
              final newCities = GhanaLocations.getCities(v);
              _city = newCities.isNotEmpty ? newCities.first : '';
              _area = '';
            });
          });
        }),
        const SizedBox(height: SNSpace.x4),
        _pickerField(c, 'City / Town', _city, () {
          _showListPicker(c, 'Select City / Town', citiesForRegion, _city, (v) {
            setState(() { _city = v; _area = ''; });
          });
        }),
        const SizedBox(height: SNSpace.x4),
        if (areasForCity.isNotEmpty) ...[
          _pickerField(c, 'Area / Suburb', _area, () {
            _showListPicker(c, 'Select Area / Suburb', areasForCity, _area, (v) {
              setState(() => _area = v);
            });
          }, hint: 'Select area...'),
          const SizedBox(height: SNSpace.x4),
        ],
        SNInput(label: 'Street / Address', hint: 'Plot 42, University Avenue...', controller: _addressCtrl, maxLines: 2, onChanged: (_) => setState(() {})),
        const SizedBox(height: SNSpace.x4),
        SNInput(label: 'Digital Address', hint: 'e.g. AK-039-5028', controller: _digitalAddrCtrl),
        const SizedBox(height: SNSpace.x4),
        SNInput(label: 'Landmark', hint: 'e.g. Near KNUST Main Gate', controller: _landmarkCtrl),
        const SizedBox(height: SNSpace.x4),
        SNInput(label: 'Description (optional)', hint: 'A brief description of your property', controller: _descCtrl, maxLines: 3),
        const SizedBox(height: SNSpace.x6),
        if (!_isEditMode) ...[
          Text('Number of Floors', style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w800)),
          const SizedBox(height: SNSpace.x2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(10, (i) {
                final n = i + 1;
                final selected = _floorCount == n;
                return Padding(
                  padding: const EdgeInsets.only(right: SNSpace.x2),
                  child: GestureDetector(
                    onTap: () => setState(() => _floorCount = n),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected ? c.primary : c.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? c.primary : c.border),
                      ),
                      alignment: Alignment.center,
                      child: Text('$n', style: SNText.bodyBold.copyWith(color: selected ? c.primaryForeground : c.foreground)),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: SNSpace.x6),
        ],
        Text('Map Location', style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w800)),
        const SizedBox(height: SNSpace.x2),
        GestureDetector(
          onTap: () async {
            final result = await showSNMapPicker(
              context: context,
              initialLat: _latitude,
              initialLng: _longitude,
              title: 'Set Hostel Location',
            );
            if (result != null) {
              setState(() { _latitude = result.lat; _longitude = result.lng; });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(SNSpace.x4),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: c.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.map_rounded, color: c.primary, size: 20),
              ),
              const SizedBox(width: SNSpace.x3),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_latitude != null ? 'Location set' : 'Drop pin on map', style: SNText.bodyBold.copyWith(color: c.foreground)),
                  const SizedBox(height: 2),
                  Text(
                    _latitude != null
                        ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                        : 'Tap to open map and set exact location',
                    style: SNText.caption.copyWith(color: c.mutedForeground),
                  ),
                ],
              )),
              Icon(_latitude != null ? Icons.check_circle : Icons.chevron_right, color: _latitude != null ? c.success : c.mutedForeground, size: 22),
            ]),
          ),
        ),
        const SizedBox(height: SNSpace.x6),
        Text('Gate Hours', style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w800)),
        const SizedBox(height: SNSpace.x2),
        Row(children: [
          Expanded(child: _pickerField(c, 'Opens', _gateOpeningTime, () => _showCustomTimePicker('Gate Opens', _gateOpeningTime, (v) => setState(() => _gateOpeningTime = v)), hint: 'e.g. 05:00')),
          const SizedBox(width: SNSpace.x3),
          Expanded(child: _pickerField(c, 'Closes', _gateClosingTime, () => _showCustomTimePicker('Gate Closes', _gateClosingTime, (v) => setState(() => _gateClosingTime = v)), hint: 'e.g. 22:00')),
        ]),
        const SizedBox(height: SNSpace.x4),
        Text('Cancellation Policy', style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w800)),
        const SizedBox(height: SNSpace.x2),
        Wrap(
          spacing: SNSpace.x2,
          children: ['FLEXIBLE', 'MODERATE', 'STRICT'].map((cp) {
            final selected = _cancellationPolicy == cp;
            return ChoiceChip(
              label: Text(cp[0] + cp.substring(1).toLowerCase()),
              selected: selected,
              onSelected: (_) => setState(() => _cancellationPolicy = cp),
              selectedColor: c.primary,
              labelStyle: SNText.caption.copyWith(color: selected ? c.primaryForeground : c.foreground, fontWeight: FontWeight.w600),
              backgroundColor: c.card,
              side: BorderSide(color: selected ? c.primary : c.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SNSpace.x3)),
            );
          }).toList(),
        ),
        const SizedBox(height: SNSpace.x4),
        Text('House Rules', style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w800)),
        const SizedBox(height: SNSpace.x2),
        Row(children: [
          Expanded(child: SNInput(hint: 'e.g. No pets allowed', controller: _houseRulesCtrl)),
          const SizedBox(width: SNSpace.x2),
          GestureDetector(
            onTap: () {
              final rule = _houseRulesCtrl.text.trim();
              if (rule.isNotEmpty) {
                setState(() { _houseRulesList.add(rule); _houseRulesCtrl.clear(); });
              }
            },
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.add, color: c.primaryForeground),
            ),
          ),
        ]),
        const SizedBox(height: SNSpace.x2),
        ..._houseRulesList.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: SNSpace.x2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: SNSpace.x3, vertical: SNSpace.x2),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
            child: Row(children: [
              Icon(Icons.rule_rounded, size: 16, color: c.mutedForeground),
              const SizedBox(width: SNSpace.x2),
              Expanded(child: Text(e.value, style: SNText.body.copyWith(color: c.foreground))),
              GestureDetector(
                onTap: () => setState(() => _houseRulesList.removeAt(e.key)),
                child: Icon(Icons.close, size: 18, color: c.mutedForeground),
              ),
            ]),
          ),
        )),
        const SizedBox(height: SNSpace.x6),
        Text('Gender Policy', style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w800)),
        const SizedBox(height: SNSpace.x2),
        Wrap(
          spacing: SNSpace.x2,
          children: _genderOptions.map((opt) {
            final selected = _genderPolicy == opt.$1;
            return ChoiceChip(
              label: Text(opt.$2),
              selected: selected,
              onSelected: (_) => setState(() => _genderPolicy = opt.$1),
              selectedColor: c.primary,
              labelStyle: SNText.caption.copyWith(color: selected ? c.primaryForeground : c.foreground, fontWeight: FontWeight.w600),
              backgroundColor: c.card,
              side: BorderSide(color: selected ? c.primary : c.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SNSpace.x3)),
            );
          }).toList(),
        ),
        const SizedBox(height: SNSpace.x6),
        Text('Key Amenities', style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w800)),
        const SizedBox(height: SNSpace.x3),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: SNSpace.x3,
          crossAxisSpacing: SNSpace.x3,
          childAspectRatio: 3,
          children: _amenities.map((a) {
            final selected = _selectedAmenities.contains(a.$1);
            return GestureDetector(
              onTap: () => setState(() { selected ? _selectedAmenities.remove(a.$1) : _selectedAmenities.add(a.$1); }),
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? c.primary.withOpacity(0.05) : c.card,
                  borderRadius: BorderRadius.circular(SNSpace.x4),
                  border: Border.all(color: selected ? c.primary : c.border, width: selected ? 2 : 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: SNSpace.x3),
                child: Row(children: [
                  Icon(a.$3, size: 20, color: selected ? c.primary : c.mutedForeground),
                  const SizedBox(width: SNSpace.x2),
                  Expanded(child: Text(a.$2, style: SNText.caption.copyWith(color: selected ? c.primary : c.mutedForeground, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: SNSpace.x4),
      ],
    );
  }

  // ── Step 2: Photos ──

  Widget _buildPhotos(SNColorTokens c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Property Photos', style: SNText.headingMd.copyWith(color: c.foreground)),
        const SizedBox(height: SNSpace.x2),
        Text('Add at least 3 photos of your property', style: SNText.caption.copyWith(color: c.mutedForeground)),
        const SizedBox(height: SNSpace.x4),
        Row(children: [
          Expanded(child: SNButton(label: 'Gallery', variant: SNButtonVariant.secondary, onPressed: _pickImages)),
          const SizedBox(width: SNSpace.x3),
          Expanded(child: SNButton(label: 'Camera', variant: SNButtonVariant.secondary, onPressed: _takePhoto)),
        ]),
        const SizedBox(height: SNSpace.x4),
        if (_totalPhotoCount == 0)
          Container(
            height: 200,
            decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(SNSpace.x4), border: Border.all(color: c.border)),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_photo_alternate_outlined, size: 48, color: c.mutedForeground),
              const SizedBox(height: SNSpace.x2),
              Text('No photos yet', style: SNText.caption.copyWith(color: c.mutedForeground)),
            ])),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: SNSpace.x2, mainAxisSpacing: SNSpace.x2),
            itemCount: _totalPhotoCount,
            itemBuilder: (_, i) {
              final isExisting = i < _existingImageUrls.length;
              return Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(SNSpace.x3),
                  child: isExisting
                      ? Image.network(_existingImageUrls[i], fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                      : Image.file(_pickedImages[i - _existingImageUrls.length], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      if (isExisting) {
                        _existingImageUrls.removeAt(i);
                      } else {
                        _pickedImages.removeAt(i - _existingImageUrls.length);
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ]);
            },
          ),
        const SizedBox(height: SNSpace.x2),
        Text('$_totalPhotoCount photo${_totalPhotoCount == 1 ? '' : 's'}', style: SNText.caption.copyWith(color: c.mutedForeground)),
      ],
    );
  }

  // ── Step 3: Review ──

  Widget _buildReview(SNColorTokens c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isEditMode ? 'Review Changes' : 'Review & Submit', style: SNText.headingMd.copyWith(color: c.foreground)),
        const SizedBox(height: SNSpace.x4),

        if (_isEditMode && _initialStatus == 'REJECTED') ...[
          Container(
            padding: const EdgeInsets.all(SNSpace.x4),
            margin: const EdgeInsets.only(bottom: SNSpace.x4),
            decoration: BoxDecoration(color: c.destructive.withOpacity(0.08), borderRadius: BorderRadius.circular(SNSpace.x3)),
            child: Row(children: [
              Icon(Icons.error_outline, color: c.destructive, size: 20),
              const SizedBox(width: SNSpace.x3),
              Expanded(child: Text('This listing was returned for changes. Edit the details and resubmit.', style: SNText.caption.copyWith(color: c.foreground))),
            ]),
          ),
        ],

        _reviewRow(c, 'Name', _nameCtrl.text),
        _reviewRow(c, 'Region', _region),
        _reviewRow(c, 'City', _city),
        if (_area.isNotEmpty) _reviewRow(c, 'Area', _area),
        _reviewRow(c, 'Address', _addressCtrl.text),
        if (_digitalAddrCtrl.text.trim().isNotEmpty) _reviewRow(c, 'Digital Addr', _digitalAddrCtrl.text),
        if (_landmarkCtrl.text.trim().isNotEmpty) _reviewRow(c, 'Landmark', _landmarkCtrl.text),
        if (_descCtrl.text.trim().isNotEmpty) _reviewRow(c, 'Description', _descCtrl.text),
        if (!_isEditMode) _reviewRow(c, 'Floors', '$_floorCount'),
        _reviewRow(c, 'Gender', _genderOptions.firstWhere((o) => o.$1 == _genderPolicy).$2),
        if (_gateOpeningTime.isNotEmpty || _gateClosingTime.isNotEmpty) _reviewRow(c, 'Gate Hours', '${_gateOpeningTime.isNotEmpty ? _gateOpeningTime : "—"} — ${_gateClosingTime.isNotEmpty ? _gateClosingTime : "—"}'),
        _reviewRow(c, 'Cancellation', _cancellationPolicy[0] + _cancellationPolicy.substring(1).toLowerCase()),
        if (_houseRulesList.isNotEmpty) _reviewRow(c, 'House Rules', _houseRulesList.join(', ')),
        _reviewRow(c, 'Amenities', _amenities.where((a) => _selectedAmenities.contains(a.$1)).map((a) => a.$2).join(', ')),
        _reviewRow(c, 'Photos', '${_uploadedUrls.length}'),
        const SizedBox(height: SNSpace.x4),
        GestureDetector(
          onTap: () async {
            final q = Uri.encodeComponent('${_nameCtrl.text}, ${_addressCtrl.text}, $_city');
            final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
            if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
          },
          child: Container(
            padding: const EdgeInsets.all(SNSpace.x4),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: c.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.map_rounded, color: c.success, size: 20),
              ),
              const SizedBox(width: SNSpace.x3),
              Expanded(child: Text('Preview on Google Maps', style: SNText.bodyBold.copyWith(color: c.foreground))),
              Icon(Icons.open_in_new_rounded, size: 18, color: c.mutedForeground),
            ]),
          ),
        ),
        const SizedBox(height: SNSpace.x4),
        if (_uploadedUrls.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadedUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: SNSpace.x2),
              itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(SNSpace.x2), child: Image.network(_uploadedUrls[i], width: 80, height: 80, fit: BoxFit.cover)),
            ),
          ),
        const SizedBox(height: SNSpace.x6),
        if (!_isEditMode || _initialStatus == 'DRAFT')
          Container(
            padding: const EdgeInsets.all(SNSpace.x4),
            decoration: BoxDecoration(color: c.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(SNSpace.x3)),
            child: Row(children: [
              Icon(Icons.info_outline, color: c.warning, size: 20),
              const SizedBox(width: SNSpace.x3),
              Expanded(child: Text('Your property will be reviewed before it goes live. This usually takes 24-48 hours.', style: SNText.caption.copyWith(color: c.foreground))),
            ]),
          ),
        if (_isEditMode && _initialStatus == 'PENDING_REVIEW')
          Container(
            padding: const EdgeInsets.all(SNSpace.x4),
            decoration: BoxDecoration(color: c.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(SNSpace.x3)),
            child: Row(children: [
              Icon(Icons.schedule, color: c.primary, size: 20),
              const SizedBox(width: SNSpace.x3),
              Expanded(child: Text('Your listing is under review. Changes will be saved and reviewed.', style: SNText.caption.copyWith(color: c.foreground))),
            ]),
          ),
      ],
    );
  }

  Widget _reviewRow(SNColorTokens c, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SNSpace.x3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 100, child: Text(label, style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value.isEmpty ? '—' : value, style: SNText.body.copyWith(color: c.foreground))),
      ]),
    );
  }
}
