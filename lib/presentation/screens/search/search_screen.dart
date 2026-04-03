import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/price_formatter.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/price_comparison_row.dart';
import '../../widgets/shimmer_loading.dart';
import 'search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  static const _suggestions = [
    'Milch', 'Butter', 'Eier', 'Brot', 'Käse',
    'Hähnchen', 'Lachs', 'Bananen', 'Cola', 'Joghurt',
  ];

  @override
  void initState() {
    super.initState();
    // Rebuild when text changes so clear button appears/disappears reactively
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String query) {
    ref.read(searchQueryProvider.notifier).state = query.trim();
    if (query.trim().isNotEmpty) _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preisvergleich'),
        backgroundColor: AppTheme.accentOrange,
      ),
      bottomNavigationBar: const AdBannerWidget(
        adUnitId: AdBannerWidget.searchBannerId,
      ),
      body: Column(
        children: [
          // 검색바
          Container(
            color: AppTheme.accentOrange,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value.trim();
              },
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Produkt suchen (z.B. Milch, Brot...)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          Expanded(
            child: query.isEmpty
                ? _buildSuggestions()
                : results.when(
                    loading: () => const SearchLoadingSkeleton(),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.search_off_rounded,
                                  size: 36, color: Colors.orange[400]),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Suche fehlgeschlagen',
                              style: TextStyle(
                                fontSize: 17,
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
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  ref.invalidate(searchResultsProvider),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Erneut suchen'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.accentOrange,
                                side: const BorderSide(
                                    color: AppTheme.accentOrange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (offers) => offers.isEmpty
                        ? _buildNoResults(query)
                        : _buildResults(offers),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Beliebte Suchen',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) {
              final color = _suggestionColor(s);
              return ActionChip(
                label: Text(
                  s,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                avatar: Icon(_suggestionIcon(s), size: 16, color: color),
                onPressed: () {
                  _controller.text = s;
                  _search(s);
                },
                backgroundColor: color.withValues(alpha: 0.1),
                side: BorderSide(color: color.withValues(alpha: 0.3)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _suggestionColor(String keyword) {
    final k = keyword.toLowerCase();
    if (k == 'milch' || k == 'butter' || k == 'käse' || k == 'joghurt') return Colors.blue;
    if (k == 'eier') return Colors.amber[700]!;
    if (k == 'brot') return Colors.orange[700]!;
    if (k == 'hähnchen') return Colors.red[600]!;
    if (k == 'lachs') return Colors.pink[600]!;
    if (k == 'bananen') return Colors.green[600]!;
    if (k == 'cola') return Colors.brown[600]!;
    return Colors.grey[600]!;
  }

  IconData _suggestionIcon(String keyword) {
    final k = keyword.toLowerCase();
    if (k == 'milch' || k == 'butter' || k == 'käse' || k == 'joghurt') return Icons.egg_outlined;
    if (k == 'eier') return Icons.egg;
    if (k == 'brot') return Icons.bakery_dining;
    if (k == 'hähnchen' || k == 'lachs') return Icons.restaurant;
    if (k == 'bananen') return Icons.eco;
    if (k == 'cola') return Icons.local_drink;
    return Icons.search;
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Keine Angebote für "$query"',
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Versuche einen anderen Suchbegriff',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List offers) {
    final cheapest = offers.first;
    final mostExpensive = offers.last;
    final savings = mostExpensive.price - cheapest.price;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 요약 배너
        if (offers.length > 1)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
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
                const Icon(Icons.savings, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bis zu sparen:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      PriceFormatter.format(savings),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'bei ${cheapest.supermarketName} kaufen',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // 결과 헤더
        Text(
          '${offers.length} Märkte haben "${ref.watch(searchQueryProvider)}" im Angebot',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // 가�� 비교 리스트
        ...offers.asMap().entries.map((entry) {
          final index = entry.key;
          final offer = entry.value;
          return GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(
              '/product',
              arguments: offer,
            ),
            child: PriceComparisonRow(
              offer: offer,
              rank: index + 1,
              isCheapest: index == 0,
            ),
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }
}
