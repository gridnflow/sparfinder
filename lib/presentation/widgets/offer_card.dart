import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/offer.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/constants/supermarket_constants.dart';
import '../../core/theme/app_theme.dart';
import 'shimmer_loading.dart';

class OfferCard extends StatelessWidget {
  final Offer offer;
  final bool isCheapest;
  final bool isSaved;
  final int storeCount;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  const OfferCard({
    super.key,
    required this.offer,
    this.isCheapest = false,
    this.isSaved = false,
    this.storeCount = 1,
    this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final info = SupermarketConstants.getInfo(offer.supermarketName);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              Stack(
                children: [
                  Hero(
                    tag: 'offer_image_${offer.id}',
                    child: _buildImage(),
                  ),
                  if (isCheapest)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppTheme.dealGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentOrange
                                  .withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department,
                                color: Colors.white, size: 12),
                            SizedBox(width: 3),
                            Text(
                              'BEST DEAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (offer.hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.dealRed,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.dealRed.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          PriceFormatter.discountPercent(
                              offer.originalPrice!, offer.price),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Info area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Supermarket + category
                      Row(
                        children: [
                          Text(info.emoji,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              offer.supermarketName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(info.color),
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
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
                      const SizedBox(height: 6),
                      // Product name
                      Text(
                        offer.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (offer.unit != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          offer.unit!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Price + bookmark
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                PriceFormatter.format(offer.price),
                                style: TextStyle(
                                  fontSize: 17,
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
                                    fontSize: 11,
                                    color: AppTheme.textTertiary,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: AppTheme.textTertiary,
                                  ),
                                ),
                            ],
                          ),
                          GestureDetector(
                            onTap: onSave,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                      scale: animation, child: child),
                              child: Container(
                                key: ValueKey(isSaved),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSaved
                                      ? AppTheme.primaryGreen
                                          .withValues(alpha: 0.1)
                                      : AppTheme.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isSaved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  color: isSaved
                                      ? AppTheme.primaryGreen
                                      : AppTheme.textTertiary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Multi-store badge
                      if (storeCount > 1) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.infoBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.compare_arrows_rounded,
                                  size: 11, color: AppTheme.infoBlue),
                              const SizedBox(width: 4),
                              Text(
                                '$storeCount Märkte',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.infoBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Expiry date
                      if (offer.validUntil != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: _isExpiringSoon(offer.validUntil!)
                                  ? AppTheme.accentOrange
                                  : AppTheme.textTertiary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'bis ${_formatDate(offer.validUntil!)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: _isExpiringSoon(offer.validUntil!)
                                    ? AppTheme.accentOrange
                                    : AppTheme.textTertiary,
                                fontWeight: _isExpiringSoon(offer.validUntil!)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = offer.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        height: 130,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          border: Border(
            bottom: BorderSide(
              color: AppTheme.divider.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => const ShimmerLoading(
            child: ShimmerBone(height: 106, borderRadius: 0),
          ),
          fadeInDuration: const Duration(milliseconds: 200),
          errorWidget: (context, url, error) => Center(
            child: Icon(
              _categoryIcon(),
              size: 40,
              color: AppTheme.textTertiary,
            ),
          ),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(color: AppTheme.divider, width: 1),
        ),
      ),
      child: Center(
        child: Icon(
          _categoryIcon(),
          size: 40,
          color: AppTheme.textTertiary,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.';
  }

  bool _isExpiringSoon(DateTime date) {
    return date.difference(DateTime.now()).inDays <= 2;
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

  IconData _categoryIcon() {
    final cat = offer.category?.toLowerCase() ?? '';
    if (cat.contains('milch') || cat.contains('käse')) return Icons.egg_outlined;
    if (cat.contains('fleisch') || cat.contains('wurst')) return Icons.restaurant;
    if (cat.contains('obst') || cat.contains('gemüse')) return Icons.eco;
    if (cat.contains('getränk') || cat.contains('drink')) return Icons.local_drink;
    if (cat.contains('brot') || cat.contains('back')) return Icons.bakery_dining;
    if (cat.contains('fisch')) return Icons.set_meal;
    return Icons.shopping_basket;
  }
}
