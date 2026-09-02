import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/primitives/sn_button.dart';
import 'package:staynest_mobile/design/primitives/sn_sheet_handle.dart';

/// Full-screen map picker. Returns LatLng on confirm, null on cancel.
class SNMapPicker extends StatefulWidget {
  const SNMapPicker({
    super.key,
    this.initialLat,
    this.initialLng,
    this.title = 'Set Hostel Location',
  });

  final double? initialLat;
  final double? initialLng;
  final String title;

  @override
  State<SNMapPicker> createState() => _SNMapPickerState();
}

class _SNMapPickerState extends State<SNMapPicker> {
  late LatLng _center;
  final _mapCtrl = MapController();

  // KNUST area default
  static const _defaultLat = 6.6745;
  static const _defaultLng = -1.5716;

  bool _loadingGps = false;

  @override
  void initState() {
    super.initState();
    _center = LatLng(
      widget.initialLat ?? _defaultLat,
      widget.initialLng ?? _defaultLng,
    );
    // If no initial location set, try GPS
    if (widget.initialLat == null) _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _loadingGps = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _loadingGps = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final newCenter = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _center = newCenter;
        _loadingGps = false;
      });
      _mapCtrl.move(newCenter, 17);
    } catch (_) {
      setState(() => _loadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: c.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title, style: SNText.headingMd.copyWith(color: c.foreground)),
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16,
              onPositionChanged: (pos, _) {
                setState(() => _center = pos.center);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.staynest.mobile',
              ),
            ],
          ),

          // Fixed center pin
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Icon(Icons.location_pin, size: 48, color: c.primary),
            ),
          ),

          // Center pin shadow dot
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Coordinate display + confirm button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(SNSpace.screenX, SNSpace.x4, SNSpace.screenX, SNSpace.x4),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: SNSpace.x4, vertical: SNSpace.x3),
                      decoration: BoxDecoration(
                        color: c.muted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.my_location_rounded, size: 18, color: c.primary),
                          const SizedBox(width: SNSpace.x3),
                          Expanded(
                            child: Text(
                              '${_center.latitude.toStringAsFixed(6)}, ${_center.longitude.toStringAsFixed(6)}',
                              style: SNText.caption.copyWith(color: c.foreground, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: SNSpace.x2),
                    Text(
                      'Drag the map to position the pin on your hostel',
                      style: SNText.caption.copyWith(color: c.mutedForeground),
                    ),
                    const SizedBox(height: SNSpace.x4),
                    SNButton(
                      label: 'Confirm Location',
                      onPressed: () => Navigator.pop(context, _center),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // GPS loading
          if (_loadingGps)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('Getting your location...', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),

          // Re-center button
          Positioned(
            right: SNSpace.screenX,
            bottom: 220,
            child: GestureDetector(
              onTap: () => _fetchCurrentLocation(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.card,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: Icon(Icons.my_location, color: c.foreground, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the map picker as a full-screen route. Returns (lat, lng) or null.
Future<({double lat, double lng})?> showSNMapPicker({
  required BuildContext context,
  double? initialLat,
  double? initialLng,
  String title = 'Set Hostel Location',
}) async {
  final result = await Navigator.push<LatLng>(
    context,
    MaterialPageRoute(
      builder: (_) => SNMapPicker(
        initialLat: initialLat,
        initialLng: initialLng,
        title: title,
      ),
    ),
  );
  if (result != null) {
    return (lat: result.latitude, lng: result.longitude);
  }
  return null;
}
