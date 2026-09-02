// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staynest_mobile/app/bootstrap.dart';
import 'package:staynest_mobile/app/router.dart';
import 'package:staynest_mobile/core/theme/theme.dart';

void main() async {
  await bootstrap();
  runApp(const ProviderScope(child: StayNestApp()));
}

class StayNestApp extends StatelessWidget {
  const StayNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StayNest',
      debugShowCheckedModeBanner: false,
      theme: snLightTheme,
      routerConfig: router,
    );
  }
}
