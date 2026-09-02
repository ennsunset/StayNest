import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/core/utils/money.dart';
import 'package:staynest_mobile/design/domain/sn_image.dart';
import 'package:staynest_mobile/features/discovery/data/hostels_repository.dart';

class ExploreMapScreen extends ConsumerStatefulWidget {
  const ExploreMapScreen({super.key, this.hostels});
  final List<Hostel>? hostels;

  @override
  ConsumerState<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends ConsumerState<ExploreMapScreen> {
  Hostel? _selected;
  String _search = '';
  final _searchController = TextEditingController();
  final _mapController = MapController();
  LatLng? _userLocation;
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _locationLoading = false); return; }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) { setState(() => _locationLoading = false); return; }
      }
      if (perm == LocationPermission.deniedForever) { setState(() => _locationLoading = false); return; }

      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _locationLoading = false;
        });
        // Check if any hostels are within ~10km of user
        final nearby = _mapped.where((h) {
          final d = const Distance();
          return d.as(LengthUnit.Kilometer, _userLocation!, LatLng(h.latitude!, h.longitude!)) < 10;
        }).toList();
        if (nearby.isNotEmpty) {
          _mapController.move(_userLocation!, 16);
        } else {
          _fitAllMarkers();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  List<Hostel> get _allHostels => widget.hostels ?? [];

  List<Hostel> get _mapped {
    var list = _allHostels.where((h) => h.latitude != null && h.longitude != null).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((h) => h.name.toLowerCase().contains(q) || h.address.toLowerCase().contains(q)).toList();
    }
    if (_minPrice != null || _maxPrice != null) {
      list = list.where((h) {
        final cedis = h.fromPricePesewas / 100;
        if (_minPrice != null && cedis < _minPrice!) return false;
        if (_maxPrice != null && cedis > _maxPrice!) return false;
        return true;
      }).toList();
    }
    return list;
  }

  String _shortPrice(int pesewas) {
    final cedis = pesewas / 100;
    if (cedis >= 1000) {
      final k = cedis / 1000;
      return 'GH\u20B5 ${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k';
    }
    return Money.format(pesewas);
  }

  double? _minPrice;
  double? _maxPrice;

  void _showFilterSheet(BuildContext context) {
    final c = context.sn;
    double tempMin = _minPrice ?? 0;
    double tempMax = _maxPrice ?? 10000;

    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SNRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(SNSpace.screenX, SNSpace.x6, SNSpace.screenX, SNSpace.x8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: SNSpace.x6),
              Text('Filter Hostels', style: SNText.headingMd.copyWith(color: c.foreground)),
              const SizedBox(height: SNSpace.x6),
              Text('Price Range (GH\u20B5 per semester)', style: SNText.caption.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w600)),
              const SizedBox(height: SNSpace.x3),
              RangeSlider(
                values: RangeValues(tempMin, tempMax),
                min: 0,
                max: 10000,
                divisions: 100,
                activeColor: c.primary,
                labels: RangeLabels(
                  'GH\u20B5 ${tempMin.round()}',
                  'GH\u20B5 ${tempMax.round()}',
                ),
                onChanged: (v) => setSheet(() { tempMin = v.start; tempMax = v.end; }),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('GH\u20B5 ${tempMin.round()}', style: SNText.bodyBold.copyWith(color: c.foreground)),
                  Text('GH\u20B5 ${tempMax.round()}', style: SNText.bodyBold.copyWith(color: c.foreground)),
                ],
              ),
              const SizedBox(height: SNSpace.x6),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() { _minPrice = null; _maxPrice = null; });
                        Navigator.pop(ctx);
                        _fitAllMarkers();
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(SNRadius.sm),
                        ),
                        child: Center(child: Text('Reset', style: SNText.bodyBold.copyWith(color: c.foreground))),
                      ),
                    ),
                  ),
                  const SizedBox(width: SNSpace.x3),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() { _minPrice = tempMin; _maxPrice = tempMax; });
                        Navigator.pop(ctx);
                        if (_mapped.isNotEmpty) _fitAllMarkers();
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(SNRadius.sm),
                        ),
                        child: Center(child: Text('Apply', style: SNText.bodyBold.copyWith(color: Colors.white))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fitAllMarkers() {
    if (_mapped.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(
      _mapped.map((h) => LatLng(h.latitude!, h.longitude!)).toList(),
    );
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final center = _userLocation
        ?? (_mapped.isNotEmpty ? LatLng(_mapped.first.latitude!, _mapped.first.longitude!) : const LatLng(6.6745, -1.5716));

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          // ── Map ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.staynest.mobile',
              ),
              MarkerLayer(
                markers: _mapped.map((h) {
                  final isSelected = _selected?.id == h.id;
                  return Marker(
                    point: LatLng(h.latitude!, h.longitude!),
                    width: isSelected ? 120 : 100,
                    height: isSelected ? 50 : 44,
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = h),
                      child: _PriceMarker(
                        price: _shortPrice(h.fromPricePesewas),
                        isSelected: isSelected,
                        primaryColor: c.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              // User location blue dot
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF4285F4).withOpacity(0.3), blurRadius: 8, spreadRadius: 2),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Top bar: back + search + filter ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: SNSpace.screenX, vertical: SNSpace.x3),
                child: Row(
                  children: [
                    _CircleButton(
                      icon: Icons.arrow_back,
                      color: c.card,
                      iconColor: c.foreground,
                      onTap: () => context.canPop() ? context.pop() : context.go('/'),
                    ),
                    const SizedBox(width: SNSpace.x3),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(SNRadius.pill),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) {
                            setState(() {
                              _search = v;
                              if (v.isNotEmpty && _mapped.length == 1) {
                                _selected = _mapped.first;
                                _mapController.move(LatLng(_mapped.first.latitude!, _mapped.first.longitude!), 17);
                              } else if (v.isNotEmpty && _mapped.length > 1) {
                                _selected = null;
                                _fitAllMarkers();
                              } else if (v.isEmpty) {
                                _selected = null;
                                _fitAllMarkers();
                              }
                            });
                          },
                          style: SNText.body.copyWith(color: c.foreground),
                          decoration: InputDecoration(
                            hintText: 'Search area...',
                            hintStyle: SNText.body.copyWith(color: c.mutedForeground),
                            prefixIcon: Icon(Icons.search, color: c.mutedForeground, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: SNSpace.x3),
                    _CircleButton(
                      icon: Icons.tune_rounded,
                      color: c.primary,
                      iconColor: Colors.white,
                      onTap: () => _showFilterSheet(context),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── My location button ──
          Positioned(
            right: SNSpace.screenX,
            bottom: _selected != null ? 160 : SNSpace.x6,
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: () {
                  if (_userLocation != null) {
                    _mapController.move(_userLocation!, 16);
                  } else {
                    _getLocation();
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.card,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Icon(
                    _userLocation != null ? Icons.my_location : Icons.location_searching,
                    color: _userLocation != null ? const Color(0xFF4285F4) : c.mutedForeground,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom hostel preview card ──
          if (_selected != null)
            Positioned(
              left: SNSpace.screenX,
              right: SNSpace.screenX,
              bottom: SNSpace.x6,
              child: SafeArea(
                top: false,
                child: GestureDetector(
                  onTap: () => context.push('/home/hostel/${_selected!.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(SNSpace.x3),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SNImage(
                            url: _selected!.imageUrls.isNotEmpty ? _selected!.imageUrls.first : null,
                            width: 72,
                            height: 72,
                          ),
                        ),
                        const SizedBox(width: SNSpace.x3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(_selected!.name, style: SNText.bodyBold.copyWith(color: c.foreground), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),

                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(_selected!.address, style: SNText.caption.copyWith(color: c.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _selected!.fromPricePesewas > 0 ? '${Money.format(_selected!.fromPricePesewas)} / sem' : 'Price TBD',
                                    style: SNText.bodyBold.copyWith(color: c.primary, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(SNRadius.pill),
                                    ),
                                    child: Text('AVAILABLE', style: SNText.microAction.copyWith(color: const Color(0xFF16A34A), fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Price Marker Bubble ──
class _PriceMarker extends StatelessWidget {
  const _PriceMarker({required this.price, required this.isSelected, required this.primaryColor});
  final String price;
  final bool isSelected;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(SNRadius.pill),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))],
            border: isSelected ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            price,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : Colors.black87,
              letterSpacing: 0.3,
            ),
          ),
        ),
        // Triangle pointer
        CustomPaint(
          size: const Size(12, 6),
          painter: _TrianglePainter(color: isSelected ? primaryColor : Colors.white),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) => old.color != color;
}

// ── Circle Button ──
class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.color, required this.iconColor, required this.onTap});
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}
