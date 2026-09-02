// app/bootstrap.dart
//
// Everything that runs before the first frame. Sentry, env, secure storage.
// Called from main.dart once.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — hostel browsing doesn't benefit from landscape, and
  // supporting both doubles layout testing on every screen.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style — light content looks wrong on our light background.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // PHASE2: Sentry init (needs DSN from Render env)
  // PHASE2: Hive init for cache
  // PHASE2: Load .env / Doppler config
}
