import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  static const String _adUnitId = 'ca-app-pub-6139362725426823/2762145308';

  AppOpenAd? _appOpenAd;
  bool _isLoading = false;
  DateTime? _loadTime;

  static const _adExpireHours = 4;

  bool get _isAdAvailable {
    if (_appOpenAd == null || _loadTime == null) return false;
    return DateTime.now().difference(_loadTime!).inHours < _adExpireHours;
  }

  void loadAd() {
    if (!Platform.isAndroid) return;
    if (_isLoading || _isAdAvailable) return;

    _isLoading = true;
    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _loadTime = DateTime.now();
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  void showAdIfAvailable() {
    if (!_isAdAvailable) {
      loadAd();
      return;
    }
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );
    _appOpenAd!.show();
  }
}
