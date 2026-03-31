import 'dart:math';
import 'package:dio/dio.dart';
import '../models/offer_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/supermarket_constants.dart';

class MarktguruRemoteSource {
  final Dio _dio;

  MarktguruRemoteSource(this._dio);

  static const int _weeklyPageSize = 200; // 주간딜: 키워드당 1회 요청
  static const int _searchPageSize = 200; // 검색: 페이지네이션 적용
  static const int _searchMaxPages = 3;   // 검색: 최대 3페이지(600개)
  static const int _batchSize = 5;        // 동시 요청 수 제한

  /// 주간 세일 전체 — 35개 키워드를 5개씩 배치로 처리
  Future<List<OfferModel>> getWeeklyDeals({
    required String zipCode,
    String? category,
  }) async {
    final keywords = category != null
        ? [category]
        : [
            'Milch', 'Butter', 'Käse', 'Joghurt', 'Sahne', 'Quark',
            'Fleisch', 'Hähnchen', 'Rind', 'Schwein', 'Wurst', 'Schinken',
            'Fisch', 'Lachs', 'Thunfisch',
            'Gemüse', 'Obst', 'Salat', 'Kartoffel', 'Tomate', 'Paprika',
            'Brot', 'Brötchen', 'Kuchen',
            'Getränke', 'Bier', 'Wein', 'Saft', 'Wasser',
            'Tiefkühl',
            'Schokolade', 'Chips',
            'Eier', 'Kaffee', 'Nudeln',
          ];

    try {
      final seen = <String>{};
      final all = <OfferModel>[];

      // 5개씩 배치 처리로 동시 요청 수 제한
      for (int i = 0; i < keywords.length; i += _batchSize) {
        final batch = keywords.sublist(i, min(i + _batchSize, keywords.length));
        final futures = batch.map((kw) => _fetchPage(
              query: kw,
              zipCode: zipCode,
              limit: _weeklyPageSize,
              offset: 0,
            ));
        final results = await Future.wait(futures);

        for (final list in results) {
          for (final offer in list) {
            if (seen.add(offer.id)) all.add(offer);
          }
        }
      }

      return all;
    } on DioException catch (e) {
      if (_isFallbackError(e)) return OfferModel.generateWeeklyMockDeals();
      rethrow;
    }
  }

  /// 상품 검색 (전체 페이지 수집)
  Future<List<OfferModel>> searchOffers({
    required String query,
    required String zipCode,
  }) async {
    try {
      return await _fetchAllPages(query: query, zipCode: zipCode);
    } on DioException catch (e) {
      if (_isFallbackError(e)) return OfferModel.generateMockData(query);
      rethrow;
    }
  }

  /// 검색용 전체 페이지 수집
  Future<List<OfferModel>> _fetchAllPages({
    required String query,
    required String zipCode,
  }) async {
    final firstPage = await _fetchPage(
      query: query,
      zipCode: zipCode,
      limit: _searchPageSize,
      offset: 0,
    );

    if (firstPage.length < _searchPageSize) return firstPage;

    // 추가 페이지 병렬 수집 (최대 _searchMaxPages - 1개 추가)
    final extraCount = min(_searchMaxPages - 1, 2);
    final futures = List.generate(
      extraCount,
      (i) => _fetchPage(
        query: query,
        zipCode: zipCode,
        limit: _searchPageSize,
        offset: _searchPageSize * (i + 1),
      ),
    );
    final extraPages = await Future.wait(futures);

    return [
      ...firstPage,
      for (final page in extraPages) ...page,
    ];
  }

  /// 단일 페이지 API 호출
  Future<List<OfferModel>> _fetchPage({
    required String query,
    required String zipCode,
    required int limit,
    required int offset,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.marktguruBaseUrl}${ApiConstants.marktguruSearchPath}',
      queryParameters: {
        'as': 'web',
        'q': query,
        'zipCode': zipCode,
        'limit': limit,
        'offset': offset,
      },
      options: Options(headers: ApiConstants.marktguruHeaders),
    );

    final data = response.data as Map<String, dynamic>?;
    final results = data?['results'] as List<dynamic>? ?? [];

    return results
        .map((e) => OfferModel.fromMarktguru(e as Map<String, dynamic>))
        .where((o) =>
            o.price > 0 &&
            SupermarketConstants.isKnownSupermarket(o.supermarketName))
        .toList();
  }

  bool _isFallbackError(DioException e) =>
      e.response?.statusCode == 403 ||
      e.response?.statusCode == 401 ||
      e.response?.statusCode == 429 ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError;
}
