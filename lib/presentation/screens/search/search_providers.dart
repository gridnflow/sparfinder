import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/offer.dart';
import '../../../core/providers/app_providers.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

/// 슈퍼마켓별 최저가 결과 — 각 슈퍼마켓당 가장 저렴한 offer 하나씩
final searchResultsProvider =
    FutureProvider.autoDispose<List<Offer>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final zipCode = ref.watch(zipCodeProvider);

  if (query.trim().isEmpty) return [];

  // Debounce: wait 500ms before making API call
  final cancelled = Completer<void>();
  ref.onDispose(() {
    if (!cancelled.isCompleted) cancelled.complete();
  });

  await Future.any([
    Future.delayed(const Duration(milliseconds: 500)),
    cancelled.future,
  ]);

  // If disposed during debounce, don't proceed
  if (cancelled.isCompleted) return [];

  final useCase = ref.watch(searchOffersUseCaseProvider);
  final results = await useCase(query: query, zipCode: zipCode);

  // 슈퍼마켓별 그룹화 → 각 슈퍼마켓의 최저가만 남김
  final Map<String, Offer> cheapestPerMarket = {};
  for (final offer in results) {
    final market = offer.supermarketName.toLowerCase();
    final existing = cheapestPerMarket[market];
    if (existing == null || offer.price < existing.price) {
      cheapestPerMarket[market] = offer;
    }
  }

  // 가격 오름차순 정렬
  final grouped = cheapestPerMarket.values.toList()
    ..sort((a, b) => a.price.compareTo(b.price));
  return grouped;
});

/// 상품 상세 화면용 가격 비교 — 제품명으로 독립 검색
final productComparisonProvider =
    FutureProvider.autoDispose.family<List<Offer>, String>((ref, productName) async {
  if (productName.trim().isEmpty) return [];

  final zipCode = ref.watch(zipCodeProvider);
  final useCase = ref.watch(searchOffersUseCaseProvider);
  final results = await useCase(query: productName, zipCode: zipCode);

  // 슈퍼마켓별 최저가만
  final Map<String, Offer> cheapestPerMarket = {};
  for (final offer in results) {
    final market = offer.supermarketName.toLowerCase();
    final existing = cheapestPerMarket[market];
    if (existing == null || offer.price < existing.price) {
      cheapestPerMarket[market] = offer;
    }
  }

  final grouped = cheapestPerMarket.values.toList()
    ..sort((a, b) => a.price.compareTo(b.price));
  return grouped;
});
