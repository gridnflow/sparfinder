import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/offer.dart';
import '../../../core/providers/app_providers.dart';

/// 홈 화면에서 사용하는 중복 제거된 딜 — 같은 제품 중 최저가만 표시
class HomeOffer {
  final Offer cheapest;        // 표시할 최저가 offer
  final int storeCount;        // 이 제품을 세일하는 총 마켓 수
  final List<Offer> allOffers; // 가격비교 화면 전달용 전체 목록

  const HomeOffer({
    required this.cheapest,
    required this.storeCount,
    required this.allOffers,
  });
}

// 선택된 카테고리 필터
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// 선택된 슈퍼마켓 필터
final selectedSupermarketProvider = StateProvider<String?>((ref) => null);

/// In-memory cache for raw offers to avoid re-fetching 35 parallel API calls
class _OffersCache {
  List<Offer>? data;
  String? zipCode;
  String? category;
  DateTime? fetchedAt;

  bool isValid(String zip, String? cat) {
    if (data == null || fetchedAt == null) return false;
    if (zipCode != zip || category != cat) return false;
    // Cache valid for 10 minutes
    return DateTime.now().difference(fetchedAt!).inMinutes < 10;
  }
}

final _offersCache = _OffersCache();

/// Clear the offers cache (e.g. on retry or zip code change)
void clearOffersCache() {
  _offersCache
    ..data = null
    ..fetchedAt = null;
}

// 원시 Offer 목록 — API 호출은 여기서만, 슈퍼마켓 필터는 적용하지 않음
// keepAlive: don't dispose on tab switch (IndexedStack already preserves state)
final _rawOffersProvider = FutureProvider<List<Offer>>((ref) async {
  final zipCode = ref.watch(zipCodeProvider);
  final category = ref.watch(selectedCategoryProvider);

  // Return cached data if still valid
  if (_offersCache.isValid(zipCode, category)) {
    return _offersCache.data!;
  }

  final useCase = ref.watch(getWeeklyDealsUseCaseProvider);
  final offers = await useCase(zipCode: zipCode, category: category);

  // Update cache
  _offersCache
    ..data = offers
    ..zipCode = zipCode
    ..category = category
    ..fetchedAt = DateTime.now();

  return offers;
});

// 실제 데이터에서 동적으로 슈퍼마켓 목록 생성 (제품 수 많은 순)
final availableSupermarketsProvider =
    FutureProvider<List<String>>((ref) async {
  final offers = await ref.watch(_rawOffersProvider.future);

  final counts = <String, int>{};
  for (final offer in offers) {
    counts[offer.supermarketName] = (counts[offer.supermarketName] ?? 0) + 1;
  }

  final sorted = counts.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

  return ['Alle', ...sorted];
});

// 홈 화면 주간 세일 데이터 (슈퍼마켓 필터 + 중복 제거)
final weeklyDealsProvider =
    FutureProvider<List<HomeOffer>>((ref) async {
  final supermarket = ref.watch(selectedSupermarketProvider);
  final allOffers = await ref.watch(_rawOffersProvider.future);

  // 슈퍼마켓 필터 적용
  final filtered = supermarket != null
      ? allOffers
          .where((o) => o.supermarketName
              .toLowerCase()
              .contains(supermarket.toLowerCase()))
          .toList()
      : allOffers;

  return _deduplicateCheapest(filtered);
});

/// 같은 제품명 그룹화 → 최저가 하나만 남기고 storeCount 기록
List<HomeOffer> _deduplicateCheapest(List<Offer> offers) {
  String normalize(String name) => name.toLowerCase().trim();

  final Map<String, List<Offer>> groups = {};
  for (final offer in offers) {
    final key = normalize(offer.productName);
    groups.putIfAbsent(key, () => []).add(offer);
  }

  final result = <HomeOffer>[];
  for (final group in groups.values) {
    group.sort((a, b) => a.price.compareTo(b.price));
    result.add(HomeOffer(
      cheapest: group.first,
      storeCount: group.length,
      allOffers: group,
    ));
  }

  // 할인율 높은 순으로 최종 정렬
  result.sort((a, b) =>
      b.cheapest.discountPercent.compareTo(a.cheapest.discountPercent));

  return result;
}