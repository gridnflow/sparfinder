import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/offers_repository.dart';
import '../../data/sources/marktguru_remote_source.dart';
import '../../domain/entities/offer.dart';
import '../../domain/usecases/compare_prices.dart';
import '../../domain/usecases/get_weekly_deals.dart';
import '../../domain/usecases/search_offers.dart';
import '../../core/constants/api_constants.dart';

// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize via ProviderScope override');
});

// Dio HTTP client with retry interceptor
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));
  dio.interceptors.add(_RetryInterceptor(dio, maxRetries: 2));
  return dio;
});

/// Retries failed requests with exponential backoff (500ms, 1s)
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int maxRetries;

  _RetryInterceptor(this._dio, {this.maxRetries = 2});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    if (_shouldRetry(err) && retryCount < maxRetries) {
      final delay = Duration(milliseconds: 500 * (retryCount + 1));
      await Future.delayed(delay);

      final opts = err.requestOptions;
      opts.extra['retryCount'] = retryCount + 1;

      try {
        final response = await _dio.fetch(opts);
        handler.resolve(response);
        return;
      } on DioException catch (e) {
        handler.next(e);
        return;
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }
}

// Data sources
final marktguruRemoteSourceProvider = Provider<MarktguruRemoteSource>((ref) {
  return MarktguruRemoteSource(ref.watch(dioProvider));
});

// Repository
final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  return OffersRepositoryImpl(ref.watch(marktguruRemoteSourceProvider));
});

// UseCases
final searchOffersUseCaseProvider = Provider<SearchOffersUseCase>((ref) {
  return SearchOffersUseCase(ref.watch(offersRepositoryProvider));
});

final getWeeklyDealsUseCaseProvider = Provider<GetWeeklyDealsUseCase>((ref) {
  return GetWeeklyDealsUseCase(ref.watch(offersRepositoryProvider));
});

final comparePricesUseCaseProvider = Provider<ComparePricesUseCase>((ref) {
  return ComparePricesUseCase(ref.watch(offersRepositoryProvider));
});

// 현재 사용자 우편번호 (설정에서 저장)
final zipCodeProvider = StateProvider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('zipCode') ?? ApiConstants.defaultZipCode;
});

// 저장된 상품 ID 목록 (contains 체크용) — Set for O(1) lookups
final savedOfferIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(savedOffersProvider).map((o) => o.id).toSet();
});

// 저장된 상품 목록
final savedOffersProvider =
    StateNotifierProvider<SavedOffersNotifier, List<Offer>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SavedOffersNotifier(prefs);
});

class SavedOffersNotifier extends StateNotifier<List<Offer>> {
  final SharedPreferences _prefs;
  static const _key = 'saved_offers';

  SavedOffersNotifier(this._prefs) : super([]) {
    // Load persisted IDs (offers will be re-added when user interacts)
    _prefs.getStringList(_key);
  }

  void toggle(Offer offer) {
    if (state.any((o) => o.id == offer.id)) {
      state = state.where((o) => o.id != offer.id).toList();
    } else {
      state = [...state, offer];
    }
    _prefs.setStringList(_key, state.map((o) => o.id).toList());
  }

  bool isSaved(String offerId) => state.any((o) => o.id == offerId);
}
