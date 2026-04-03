import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/supermarket_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/offer.dart';
import '../../widgets/offer_card.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/shimmer_loading.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
    clearOffersCache();
    ref.read(zipCodeProvider.notifier).state = trimmed;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString('zipCode', trimmed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Angebote für PLZ $trimmed werden geladen...'),
        backgroundColor: AppTheme.accentOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zipCode = ref.watch(zipCodeProvider);
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
            backgroundColor: AppTheme.accentOrange,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AngebotsFuchs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showZipDialog(context, ref, zipCode),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: Colors.white.withValues(alpha: 0.8), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'PLZ $zipCode',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit_rounded,
                          color: Colors.white.withValues(alpha: 0.6), size: 12),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined,
                    color: Colors.white.withValues(alpha: 0.9)),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/settings'),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: ref.watch(availableSupermarketsProvider).when(
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
            ),
          ),

          // 이번 주 특가 헤더
          weeklyDeals.when(
            loading: () => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: ShimmerLoading(
                  child: Row(
                    children: const [
                      ShimmerBone(width: 180, height: 18),
                      Spacer(),
                      ShimmerBone(width: 70, height: 13),
                    ],
                  ),
                ),
              ),
            ),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${deals.length} Produkte',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 딜 그리드
          weeklyDeals.when(
            loading: () => const HomeLoadingSkeleton(),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.wifi_off_rounded,
                            size: 40, color: Colors.red[300]),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Angebote konnten nicht geladen werden',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Prüfe deine Internetverbindung\nund versuche es erneut',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          clearOffersCache();
                          ref.invalidate(weeklyDealsProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erneut versuchen'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (deals) {
              if (deals.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 72, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'Keine Angebote gefunden',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ändere deine PLZ oder versuche es später erneut',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () => ref.invalidate(weeklyDealsProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Neu laden'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentOrange,
                            side: const BorderSide(color: AppTheme.accentOrange),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final savedOfferIds = ref.watch(savedOfferIdsProvider);

              // 2열 카드 행 + 광고 행 혼합 리스트 구성
              // 카드 3행(6개)마다 광고 1개 삽입
              final List<Widget> rows = [];
              int cardRowCount = 0;
              for (int i = 0; i < deals.length; i += 2) {
                final left = deals[i];
                final right = i + 1 < deals.length ? deals[i + 1] : null;

                // 광고 먼저 삽입 (첫 행 제외, 3행마다)
                if (cardRowCount > 0 && cardRowCount % 3 == 0) {
                  rows.add(const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: AdBannerWidget(
                      height: 60,
                      adUnitId: AdBannerWidget.feedBannerId,
                    ),
                  ));
                }

                rows.add(_CardRow(
                  key: ValueKey(left.cheapest.id),
                  left: left,
                  right: right,
                  savedOfferIds: savedOfferIds,
                  onTap: (offer) => Navigator.of(context).pushNamed(
                    '/product',
                    arguments: offer,
                  ),
                  onSave: (offer) =>
                      ref.read(savedOffersProvider.notifier).toggle(offer),
                ));
                cardRowCount++;
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

/// 카드 2개를 한 행으로 표시하는 위젯
class _CardRow extends StatelessWidget {
  final HomeOffer left;
  final HomeOffer? right;
  final Set<String> savedOfferIds;
  final void Function(Offer offer) onTap;
  final void Function(Offer offer) onSave;

  const _CardRow({
    super.key,
    required this.left,
    required this.right,
    required this.savedOfferIds,
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
                  isSaved: savedOfferIds.contains(left.cheapest.id),
                  onTap: () => onTap(left.cheapest),
                  onSave: () => onSave(left.cheapest),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: cardWidth,
                child: right != null
                    ? OfferCard(
                        offer: right!.cheapest,
                        storeCount: right!.storeCount,
                        isSaved: savedOfferIds.contains(right!.cheapest.id),
                        onTap: () => onTap(right!.cheapest),
                        onSave: () => onSave(right!.cheapest),
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
              : AppTheme.accentOrange;

          return FilterChip(
            label: Text(
              info != null ? '${info.emoji} $market' : market,
              style: TextStyle(
                color: isSelected ? selectedColor : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelect(market),
            selectedColor: Colors.white,
            backgroundColor: Colors.white,
            showCheckmark: false,
            side: BorderSide(
              color: isSelected ? selectedColor : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }
}