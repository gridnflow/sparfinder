import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/supermarket_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/offer_card.dart';
import '../../widgets/ad_banner.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _categories = [
    'Alle',
    'Milchprodukte',
    'Fleisch',
    'Obst & Gemüse',
    'Getränke',
    'Brot & Backwaren',
    'Fisch',
    'Eier',
    'Käse',
    'Frühstück',
  ];

  void _showZipDialog(BuildContext context, WidgetRef ref, String currentZip) {
    final controller = TextEditingController(text: currentZip);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Postleitzahl ändern'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'z.B. 10115',
            prefixIcon: Icon(Icons.location_on),
            counterText: '',
          ),
          onSubmitted: (v) {
            _saveZip(context, ref, v);
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveZip(context, ref, controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _saveZip(BuildContext context, WidgetRef ref, String zip) {
    final trimmed = zip.trim();
    if (trimmed.length != 5 || int.tryParse(trimmed) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte eine gültige 5-stellige PLZ eingeben'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    ref.read(zipCodeProvider.notifier).state = trimmed;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString('zipCode', trimmed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Angebote für PLZ $trimmed werden geladen...'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zipCode = ref.watch(zipCodeProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedSupermarket = ref.watch(selectedSupermarketProvider);
    final weeklyDeals = ref.watch(weeklyDealsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const AdBannerWidget(height: 60),
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppTheme.primaryGreen,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AngebotsFuchs 🦊',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showZipDialog(context, ref, zipCode),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'PLZ $zipCode',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, color: Colors.white54, size: 12),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/settings'),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: Column(
                children: [
                  // 상품 카테고리 필터
                  _CategoryFilter(
                    categories: _categories,
                    selected: selectedCategory ?? 'Alle',
                    onSelect: (cat) {
                      ref.read(selectedCategoryProvider.notifier).state =
                          cat == 'Alle' ? null : cat;
                    },
                  ),
                  // 슈퍼마켓 필터 (실제 데이터 기반 동적 목록)
                  ref.watch(availableSupermarketsProvider).when(
                    loading: () => const SizedBox(height: 46),
                    error: (e, s) => const SizedBox(height: 46),
                    data: (markets) => _SupermarketFilter(
                      supermarkets: markets,
                      selected: selectedSupermarket ?? 'Alle',
                      onSelect: (market) {
                        ref.read(selectedSupermarketProvider.notifier).state =
                            market == 'Alle' ? null : market;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 이번 주 특가 헤더
          weeklyDeals.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (deals) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Text(
                      selectedSupermarket != null
                          ? '$selectedSupermarket Angebote'
                          : 'Diese Woche im Angebot',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${deals.length} Produkte',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 딜 그리드
          weeklyDeals.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Fehler: $e'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(weeklyDealsProvider),
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            ),
            data: (deals) {
              if (deals.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('Keine Angebote gefunden'),
                  ),
                );
              }
              final savedOffers = ref.watch(savedOffersProvider);

              // 2열 카드 행 + 광고 행 혼합 리스트 구성
              // 카드 3행(6개)마다 광고 1개 삽입
              final List<Widget> rows = [];
              int cardRowCount = 0;
              for (int i = 0; i < deals.length; i += 2) {
                final left = deals[i];
                final right = i + 1 < deals.length ? deals[i + 1] : null;

                rows.add(_CardRow(
                  left: left,
                  right: right,
                  savedOffers: savedOffers,
                  onTap: (offer) => Navigator.of(context).pushNamed(
                    '/product',
                    arguments: offer,
                  ),
                  onSave: (id) =>
                      ref.read(savedOffersProvider.notifier).toggle(id),
                ));
                cardRowCount++;

                // 3행마다 광고 삽입 (마지막 행 제외)
                if (cardRowCount % 3 == 0 && i + 2 < deals.length) {
                  rows.add(const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: AdBannerWidget(
                      height: 60,
                      adUnitId: AdBannerWidget.feedBannerId,
                    ),
                  ));
                }
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(rows),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selected;
          return FilterChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) => onSelect(cat),
            selectedColor: AppTheme.primaryGreen,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

/// 카드 2개를 한 행으로 표시하는 위젯
class _CardRow extends StatelessWidget {
  final HomeOffer left;
  final HomeOffer? right;
  final List<String> savedOffers;
  final void Function(dynamic offer) onTap;
  final void Function(String id) onSave;

  const _CardRow({
    required this.left,
    required this.right,
    required this.savedOffers,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 8) / 2;
        final cardHeight = cardWidth / 0.57;
        return SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: cardWidth,
                child: OfferCard(
                  offer: left.cheapest,
                  storeCount: left.storeCount,
                  isSaved: savedOffers.contains(left.cheapest.id),
                  onTap: () => onTap(left.cheapest),
                  onSave: () => onSave(left.cheapest.id),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: cardWidth,
                child: right != null
                    ? OfferCard(
                        offer: right!.cheapest,
                        storeCount: right!.storeCount,
                        isSaved: savedOffers.contains(right!.cheapest.id),
                        onTap: () => onTap(right!.cheapest),
                        onSave: () => onSave(right!.cheapest.id),
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SupermarketFilter extends StatelessWidget {
  final List<String> supermarkets;
  final String selected;
  final ValueChanged<String> onSelect;

  const _SupermarketFilter({
    required this.supermarkets,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: supermarkets.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final market = supermarkets[index];
          final isSelected = market == selected;
          final info = market == 'Alle'
              ? null
              : SupermarketConstants.getInfo(market);
          final selectedColor = info != null
              ? Color(info.color)
              : AppTheme.primaryGreen;

          return FilterChip(
            label: Text(
              info != null ? '${info.emoji} $market' : market,
            ),
            selected: isSelected,
            onSelected: (_) => onSelect(market),
            selectedColor: selectedColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}