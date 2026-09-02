// features/auth/presentation/splash_screen.dart
//
// Screen 1 — Splash.
// Primary-filled screen, white rounded logo tile with home icon,
// "StayNest" heading, "CAMPUS LIVING REDEFINED" subtitle,
// two blurred circles for depth, dot indicators, version footer.
//
// Job: decide the route. Read token → refresh → resolve role → route.
// Nothing else.
//
// Trap: never block on a network call. 800ms max, then route regardless.

import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:staynest_mobile/core/network/api_client.dart';
import 'package:staynest_mobile/core/network/token_storage.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staynest_mobile/features/auth/data/auth_provider.dart';
import 'package:staynest_mobile/features/auth/data/auth_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';
import 'package:staynest_mobile/core/theme/tokens.dart';
import 'package:staynest_mobile/core/theme/typography.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();

    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoScale = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctl, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctl, curve: Curves.easeOut),
    );

    _ctl.forward();

    // Route after 800ms — never block on network here.
    Timer(const Duration(milliseconds: 800), _resolveRoute);
  }

  Future<void> _resolveRoute() async {
    if (!mounted) return;

    try {
      final storage = TokenStorage();
      final accessToken = await storage.getAccessToken();

      if (accessToken == null) {
        if (mounted) context.go(Routes.onboarding);
        return;
      }

      // Try using the existing token
      final dio = Dio(BaseOptions(
        baseUrl: apiBaseUrl,
        headers: {'Authorization': 'Bearer $accessToken'},
      ));

      try {
        final res = await dio.get('/auth/me');
        final user = AuthUser.fromJson(res.data as Map<String, dynamic>);
        ref.read(authNotifierProvider.notifier).state = user;
        final role = user.role;
        if (!mounted) return;
        context.go(role == 'OWNER' ? Routes.ownerDashboard : Routes.home);
      } on DioException {
        // Token expired — try refresh
        final refreshToken = await storage.getRefreshToken();
        if (refreshToken == null) {
          if (mounted) context.go(Routes.onboarding);
          return;
        }

        try {
          final refreshDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
          final res = await refreshDio.post(
            '/auth/refresh',
            options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
          );
          final data = res.data;
          final tokens = data['tokens'] as Map<String, dynamic>? ?? data;
          final newAccess = tokens['accessToken'] as String;
          final newRefresh = tokens['refreshToken'] as String;
          await storage.saveTokens(newAccess, newRefresh);

          // Get role with new token
          final meDio = Dio(BaseOptions(
            baseUrl: apiBaseUrl,
            headers: {'Authorization': 'Bearer $newAccess'},
          ));
          final meRes = await meDio.get('/auth/me');
          final user = AuthUser.fromJson(meRes.data as Map<String, dynamic>);
          ref.read(authNotifierProvider.notifier).state = user;
          final role = user.role;
          if (!mounted) return;
          context.go(role == 'OWNER' ? Routes.ownerDashboard : Routes.home);
        } catch (_) {
          await storage.clear();
          if (mounted) context.go(Routes.onboarding);
        }
      }
    } catch (_) {
      if (mounted) context.go(Routes.onboarding);
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sn;
    final year = DateTime.now().year;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: c.primary,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Blurred background circles for depth ──
            Positioned(
              top: -60,
              left: -80,
              child: _BlurredCircle(
                size: 260,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              bottom: -40,
              right: -60,
              child: _BlurredCircle(
                size: 320,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),

            // ── Centre content: logo + title + subtitle ──
            AnimatedBuilder(
              animation: _ctl,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo tile — white rounded square with home icon
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32), // rounded-[2rem]
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.home_rounded,
                        size: 48,
                        color: c.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // "StayNest" heading
                  Text(
                    'StayNest',
                    style: SNText.displayLg.copyWith(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'CAMPUS LIVING REDEFINED',
                    style: SNText.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3.0,
                    ),
                  ),
                ],
              ),
            ),

            // ── Dot indicators + version footer ──
            Positioned(
              bottom: 48,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Three dots: small · wide pill · small
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 32,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Version footer — dynamic year
                  Text(
                    'v1.0.0 • © $year StayNest Inc.',
                    style: SNText.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurredCircle extends StatelessWidget {
  const _BlurredCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
