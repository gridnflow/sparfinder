import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app.dart';
import 'core/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch uncaught Dart/Flutter errors before they crash the process
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled error: $error');
    return true; // prevent crash
  };

  final prefs = await SharedPreferences.getInstance();

  // AdMob init can fail on emulators (OOM → DeadSystemException in JNI).
  // A timeout + try-catch lets the app run without ads rather than crashing.
  try {
    await MobileAds.instance
        .initialize()
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('AdMob init failed (ads disabled): $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SparFinderApp(),
    ),
  );
}
