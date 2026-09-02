// features/discovery/presentation/gallery_screen.dart
//
// Screen 16 — Gallery.
// Grid of photos, tap to full-screen pager with pinch zoom.
// Trap: thumbnails request small variant, full-screen requests large.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';
import 'package:staynest_mobile/design/domain/sn_image.dart';
import 'package:staynest_mobile/design/layout/sn_scaffold.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key, required this.hostelId, this.imageUrls = const []});

  final String hostelId;
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final c = context.sn;


    return Scaffold(
      backgroundColor: c.background,
      appBar: SNAppBar(
        title: 'Photos',
        onBack: () => context.pop(),
        trailing: Text(
          '${imageUrls.length} PHOTOS',
          style: SNText.microAction.copyWith(color: c.mutedForeground),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(SNSpace.x3),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: SNSpace.x1 + 2,
          crossAxisSpacing: SNSpace.x1 + 2,
          childAspectRatio: 1,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _openViewer(context, i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SNRadius.xs),
            child: SNImage(
              url: imageUrls.isNotEmpty ? imageUrls[i] : null,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }

  void _openViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _FullScreenViewer(
          images: imageUrls,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }
}

class _FullScreenViewer extends StatefulWidget {
  const _FullScreenViewer({
    required this.images,
    required this.initialIndex,
  });

  final List<String?> images;
  final int initialIndex;

  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Pager with pinch zoom
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1.0,
              maxScale: 3.0,
              child: Center(
                child: SNImage(
                  url: widget.images[i],
                  width: double.infinity,
                  height: 400,
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SNSpace.screenX,
                  vertical: SNSpace.x3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: SNSize.circleButton,
                        width: SNSize.circleButton,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Text(
                      '${_current + 1} / ${widget.images.length}',
                      style: SNText.bodyBold.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
