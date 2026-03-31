import 'package:flutter/material.dart';
import '../../domain/entities/offer.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/constants/supermarket_constants.dart';
import '../../core/theme/app_theme.dart';

class PriceComparisonRow extends StatelessWidget {
  final Offer offer;
  final bool isCheapest;
  final int rank;

  const PriceComparisonRow({
    super.key,
    required this.offer,
    required this.rank,
    this.isCheapest = false,
  });

  @override
  Widget build(BuildContext context) {
    final info = SupermarketConstants.getInfo(offer.supermarketName);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCheapest
            ? AppTheme.primaryGreen.withValues(alpha: 0.06)
            : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: isCheapest
            ? Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4), width: 1.5)
            : Border.all(color: AppTheme.divider),
        boxShadow: isCheapest ? AppTheme.cardShadow : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Rank badge
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: isCheapest ? AppTheme.primaryGradient : null,
              color: isCheapest ? null : const Color(0xFFF0F1F3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCheapest
                  ? const Icon(Icons.emoji_events_rounded,
                      color: Colors.white, size: 16)
                  : Text(
                      '$rank',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Supermarket + product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(info.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        offer.supermarketName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isCheapest
                              ? AppTheme.primaryGreen
                              : Color(info.color),
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (offer.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _categoryColor(offer.category!)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _categoryShort(offer.category!),
                          style: TextStyle(
                            fontSize: 9,
                            color: _categoryColor(offer.category!),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  offer.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (offer.unit != null)
                  Text(
                    offer.unit!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                PriceFormatter.format(offer.price),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isCheapest
                      ? AppTheme.primaryGreen
                      : AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (offer.originalPrice != null)
                Text(
                  PriceFormatter.format(offer.originalPrice!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppTheme.textTertiary,
                  ),
                ),
            ],
          ),
          if (isCheapest) ...[
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.bestDealGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded,
                  color: AppTheme.bestDealGold, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('milch') || cat.contains('käse') || cat.contains('joghurt')) return const Color(0xFF3B82F6);
    if (cat.contains('fleisch') || cat.contains('wurst') || cat.contains('fisch')) return const Color(0xFFEF4444);
    if (cat.contains('obst') || cat.contains('gemüse')) return const Color(0xFF22C55E);
    if (cat.contains('getränk') || cat.contains('bier') || cat.contains('wein')) return const Color(0xFF6366F1);
    if (cat.contains('brot') || cat.contains('back')) return const Color(0xFFF59E0B);
    if (cat.contains('tiefkühl')) return const Color(0xFF06B6D4);
    if (cat.contains('süß') || cat.contains('schoko') || cat.contains('chips')) return const Color(0xFFEC4899);
    return const Color(0xFF6B7280);
  }

  String _categoryShort(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('milch')) return 'Milch';
    if (cat.contains('käse')) return 'Käse';
    if (cat.contains('joghurt')) return 'Joghurt';
    if (cat.contains('fleisch')) return 'Fleisch';
    if (cat.contains('wurst') || cat.contains('schinken')) return 'Wurst';
    if (cat.contains('fisch') || cat.contains('lachs')) return 'Fisch';
    if (cat.contains('obst')) return 'Obst';
    if (cat.contains('gemüse')) return 'Gemüse';
    if (cat.contains('getränk')) return 'Getränke';
    if (cat.contains('bier')) return 'Bier';
    if (cat.contains('wein')) return 'Wein';
    if (cat.contains('brot') || cat.contains('back')) return 'Brot';
    if (cat.contains('tiefkühl')) return 'TK';
    if (cat.contains('schoko')) return 'Süßes';
    if (cat.contains('eier')) return 'Eier';
    if (cat.contains('kaffee')) return 'Kaffee';
    return category.length > 8 ? '${category.substring(0, 8)}…' : category;
  }
}
