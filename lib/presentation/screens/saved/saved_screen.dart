import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/constants/supermarket_constants.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedOffers = ref.watch(savedOffersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einkaufsliste'),
        backgroundColor: AppTheme.accentOrange,
        actions: [
          if (savedOffers.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Liste leeren?'),
                    content: const Text(
                        'Alle gespeicherten Produkte werden entfernt.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Abbrechen'),
                      ),
                      TextButton(
                        onPressed: () {
                          for (final offer in List.from(savedOffers)) {
                            ref
                                .read(savedOffersProvider.notifier)
                                .toggle(offer);
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('Leeren',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Alle entfernen',
                  style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: savedOffers.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedOffers.length,
              itemBuilder: (context, index) {
                final offer = savedOffers[index];
                final info =
                    SupermarketConstants.getInfo(offer.supermarketName);
                return Dismissible(
                  key: ValueKey(offer.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  onDismissed: (_) =>
                      ref.read(savedOffersProvider.notifier).toggle(offer),
                  child: Card(
                    child: ListTile(
                      onTap: () => Navigator.of(context).pushNamed(
                        '/product',
                        arguments: offer,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: offer.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: offer.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Container(
                                    color: AppTheme.accentOrange
                                        .withValues(alpha: 0.1),
                                    child: const Icon(Icons.shopping_basket,
                                        color: AppTheme.accentOrange,
                                        size: 24),
                                  ),
                                )
                              : Container(
                                  color: AppTheme.accentOrange
                                      .withValues(alpha: 0.1),
                                  child: const Icon(Icons.shopping_basket,
                                      color: AppTheme.accentOrange, size: 24),
                                ),
                        ),
                      ),
                      title: Text(
                        offer.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Row(
                        children: [
                          Text(info.emoji,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '${offer.supermarketName} · ${PriceFormatter.format(offer.price)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () => ref
                            .read(savedOffersProvider.notifier)
                            .toggle(offer),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bookmark_border,
                  size: 48, color: AppTheme.accentOrange.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Deine Einkaufsliste ist leer',
              style: TextStyle(
                fontSize: 20,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Speichere Angebote, die dich interessieren,\nindem du auf das Lesezeichen-Symbol tippst',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark_border,
                    size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Icon(Icons.bookmark,
                    size: 18, color: AppTheme.accentOrange),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
