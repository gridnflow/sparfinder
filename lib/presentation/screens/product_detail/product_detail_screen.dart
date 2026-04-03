import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/offer.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/constants/supermarket_constants.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/price_comparison_row.dart';
import '../../widgets/shimmer_loading.dart';
import '../search/search_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  final Offer offer;

  const ProductDetailScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedOfferIds = ref.watch(savedOfferIdsProvider);
    final isSaved = savedOfferIds.contains(offer.id);

    // 같은 상품 다른 마켓 결과 로드 (제품명으로 독립 검색)
    final allOffersAsync = ref.watch(
        productComparisonProvider(offer.productName));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 이미지 + AppBar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.surfaceWhite,
            iconTheme: const IconThemeData(color: AppTheme.accentOrange),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'offer_image_${offer.id}',
                child: offer.imageUrl != null
                    ? Container(
                        color: Colors.grey[100],
                        padding: const EdgeInsets.all(24),
                        child: CachedNetworkImage(
                          imageUrl: offer.imageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) =>
                              _imagePlaceholder(),
                        ),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
                onPressed: () =>
                    ref.read(savedOffersProvider.notifier).toggle(offer),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상품명 + 브랜드
                  if (offer.brand != null)
                    Text(
                      offer.brand!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Text(
                    offer.productName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (offer.unit != null)
                    Text(
                      offer.unit!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // 이번 마켓 가격 하이라이트
                  _CurrentOfferCard(offer: offer),

                  const SizedBox(height: 24),

                  // 유효기간
                  if (offer.validFrom != null || offer.validUntil != null)
                    _ValidityBar(
                        from: offer.validFrom, until: offer.validUntil),

                  const SizedBox(height: 24),

                  // 가격 비교 섹션
                  const Text(
                    'Preisvergleich',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  allOffersAsync.when(
                    loading: () => ShimmerLoading(
                      child: Column(
                        children: List.generate(
                          3,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFE0E0E0)),
                              ),
                              child: const Row(
                                children: [
                                  ShimmerBone(
                                      width: 28,
                                      height: 28,
                                      borderRadius: 14),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ShimmerBone(
                                            width: 120, height: 14),
                                        SizedBox(height: 4),
                                        ShimmerBone(
                                            width: 80, height: 12),
                                      ],
                                    ),
                                  ),
                                  ShimmerBone(width: 60, height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    error: (e, _) => Text(
                      'Keine weiteren Angebote verfügbar',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    data: (offers) {
                      if (offers.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Nur bei ${offer.supermarketName} im Angebot',
                            style: const TextStyle(
                                color: AppTheme.textSecondary),
                          ),
                        );
                      }
                      return Column(
                        children: offers.asMap().entries.map((entry) {
                          return PriceComparisonRow(
                            offer: entry.value,
                            rank: entry.key + 1,
                            isCheapest: entry.key == 0,
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // 광고 배너
                  const AdBannerWidget(
                    adUnitId: AdBannerWidget.detailBannerId,
                  ),

                  const SizedBox(height: 16),

                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => ref
                          .read(savedOffersProvider.notifier)
                          .toggle(offer),
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_add,
                      ),
                      label: Text(
                        isSaved
                            ? 'Gespeichert'
                            : 'Zur Einkaufsliste hinzufügen',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: isSaved
                            ? Colors.grey[200]
                            : AppTheme.accentOrange,
                        foregroundColor:
                            isSaved ? AppTheme.textPrimary : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.shopping_basket, size: 80, color: Colors.grey),
      ),
    );
  }
}

class _CurrentOfferCard extends StatelessWidget {
  final Offer offer;

  const _CurrentOfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final info = SupermarketConstants.getInfo(offer.supermarketName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentOrange, AppTheme.accentOrangeLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(info.emoji,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    offer.supermarketName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                PriceFormatter.format(offer.price),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (offer.originalPrice != null) ...[
                Text(
                  PriceFormatter.format(offer.originalPrice!),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.white60,
                  ),
                ),
                Text(
                  PriceFormatter.savedAmount(
                      offer.originalPrice!, offer.price),
                  style: const TextStyle(
                    color: AppTheme.bestDealGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          if (offer.hasDiscount)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                PriceFormatter.discountPercent(
                    offer.originalPrice!, offer.price),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ValidityBar extends StatelessWidget {
  final DateTime? from;
  final DateTime? until;

  const _ValidityBar({this.from, this.until});

  @override
  Widget build(BuildContext context) {
    String text = 'Gültig';
    if (from != null) {
      text +=
          ' ab ${from!.day}.${from!.month.toString().padLeft(2, '0')}.';
    }
    if (until != null) {
      text +=
          ' bis ${until!.day}.${until!.month.toString().padLeft(2, '0')}.${until!.year}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: Colors.amber[700]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.amber[800],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
