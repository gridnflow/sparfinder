import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  static const String _adUnitId = 'ca-app-pub-6139362725426823/7136189956';

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  int _showCount = 0;

  void loadAd() {
    if (!Platform.isAndroid) return;
    if (_isLoading || _interstitialAd != null) return;

    _isLoading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  // 5번 탭마다 1번 표시 (사용자 경험 보호)
  void showAdIfAvailable() {
    _showCount++;
    if (_showCount % 5 != 0) return;

    if (_interstitialAd == null) {
      loadAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadAd();
      },
    );
    _interstitialAd!.show();
  }
}
