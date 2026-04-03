import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparfinder/domain/entities/offer.dart';
import 'package:sparfinder/presentation/widgets/offer_card.dart';

Offer _offer({
  String id = '1',
  String productName = 'Vollmilch',
  String? brand = 'Weihenstephan',
  double price = 1.09,
  double? originalPrice,
  String supermarketName = 'ALDI',
  String? imageUrl,
  String? category,
  String? unit,
  DateTime? validUntil,
}) {
  return Offer(
    id: id,
    productName: productName,
    brand: brand,
    price: price,
    originalPrice: originalPrice,
    supermarketName: supermarketName,
    imageUrl: imageUrl,
    category: category,
    unit: unit,
    validUntil: validUntil,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 200,
        height: 350,
        child: child,
      ),
    ),
  );
}

void main() {
  group('OfferCard', () {
    testWidgets('displays product name and price', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer()),
      ));

      expect(find.text('Weihenstephan Vollmilch'), findsOneWidget);
      expect(find.text('€ 1,09'), findsOneWidget);
    });

    testWidgets('displays supermarket name', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer(supermarketName: 'REWE')),
      ));

      expect(find.text('REWE'), findsOneWidget);
    });

    testWidgets('shows discount badge when hasDiscount', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(
          offer: _offer(price: 0.99, originalPrice: 1.49),
        ),
      ));

      // Discount percentage badge should be shown
      expect(find.text('- 34%'), findsOneWidget);
      // Original price struck through
      expect(find.text('€ 1,49'), findsOneWidget);
    });

    testWidgets('does not show discount badge when no discount', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer(originalPrice: null)),
      ));

      // No "- %" text should appear
      expect(find.textContaining('- '), findsNothing);
    });

    testWidgets('shows BEST DEAL badge when isCheapest', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer(), isCheapest: true),
      ));

      expect(find.text('BEST DEAL'), findsOneWidget);
    });

    testWidgets('does not show BEST DEAL badge by default', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer()),
      ));

      expect(find.text('BEST DEAL'), findsNothing);
    });

    testWidgets('shows filled bookmark when saved', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer(), isSaved: true),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
    });

    testWidgets('shows outline bookmark when not saved', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer(), isSaved: false),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer(), onTap: () => tapped = true),
      ));

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('calls onSave when bookmark is tapped', (tester) async {
      var saved = false;
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer(), onSave: () => saved = true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).last);
      expect(saved, isTrue);
    });

    testWidgets('shows store count badge when > 1', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer(), storeCount: 3),
      ));

      expect(find.text('3 Märkte'), findsOneWidget);
    });

    testWidgets('does not show store count when 1', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer(), storeCount: 1),
      ));

      expect(find.textContaining('Märkte'), findsNothing);
    });

    testWidgets('shows unit when present', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer(unit: '1 kg')),
      ));

      expect(find.text('1 kg'), findsOneWidget);
    });

    testWidgets('shows category tag when present', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer(category: 'Milch & Käse')),
      ));

      expect(find.text('Milch'), findsOneWidget);
    });

    testWidgets('shows valid until date', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(
          offer: _offer(
            validUntil: DateTime(2026, 4, 15),
          ),
        ),
      ));

      expect(find.text('bis 15.04.'), findsOneWidget);
    });

    testWidgets('renders without image (placeholder)', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer()),
      ));

      // Should show placeholder icon
      expect(find.byIcon(Icons.shopping_basket), findsOneWidget);
    });

    testWidgets('handles null brand gracefully', (tester) async {
      await tester.pumpWidget(_wrap(
        OfferCard(offer: _offer(brand: null)),
      ));

      // Should show just product name
      expect(find.text('Vollmilch'), findsOneWidget);
    });

    group('image loading', () {
      testWidgets('shows placeholder icon when imageUrl is null',
          (tester) async {
        await tester.pumpWidget(_wrap(
          OfferCard(offer: _offer(imageUrl: null)),
        ));

        // Placeholder should be shown — default icon for no category
        expect(find.byIcon(Icons.shopping_basket), findsOneWidget);
        // CachedNetworkImage should NOT be in the tree
        expect(find.byType(CachedNetworkImage), findsNothing);
      });

      testWidgets('shows placeholder icon when imageUrl is empty string',
          (tester) async {
        await tester.pumpWidget(_wrap(
          OfferCard(offer: _offer(imageUrl: '')),
        ));

        expect(find.byIcon(Icons.shopping_basket), findsOneWidget);
        expect(find.byType(CachedNetworkImage), findsNothing);
      });

      testWidgets('uses CachedNetworkImage when imageUrl is provided',
          (tester) async {
        await tester.pumpWidget(_wrap(
          OfferCard(
            offer: _offer(
              imageUrl:
                  'https://mg2de.b-cdn.net/api/v1/offers/123/images/default/0/medium.webp',
            ),
          ),
        ));

        expect(find.byType(CachedNetworkImage), findsOneWidget);
      });

      testWidgets(
          'shows category-specific placeholder icon for Milch category',
          (tester) async {
        await tester.pumpWidget(_wrap(
          OfferCard(offer: _offer(imageUrl: null, category: 'Milchprodukte')),
        ));

        expect(find.byIcon(Icons.egg_outlined), findsOneWidget);
      });

      testWidgets(
          'shows category-specific placeholder icon for Fleisch category',
          (tester) async {
        await tester.pumpWidget(_wrap(
          OfferCard(offer: _offer(imageUrl: null, category: 'Fleisch')),
        ));

        expect(find.byIcon(Icons.restaurant), findsOneWidget);
      });

      testWidgets(
          'shows category-specific placeholder icon for Obst & Gemüse',
          (tester) async {
        await tester.pumpWidget(_wrap(
          OfferCard(
              offer: _offer(imageUrl: null, category: 'Obst & Gemüse')),
        ));

        expect(find.byIcon(Icons.eco), findsOneWidget);
      });

      testWidgets(
          'shows category-specific placeholder icon for Getränke',
          (tester) async {
        await tester.pumpWidget(_wrap(
          OfferCard(offer: _offer(imageUrl: null, category: 'Getränke')),
        ));

        expect(find.byIcon(Icons.local_drink), findsOneWidget);
      });

      testWidgets(
          'shows category-specific placeholder icon for Brot',
          (tester) async {
        await tester.pumpWidget(_wrap(
          OfferCard(
              offer:
                  _offer(imageUrl: null, category: 'Brot & Backwaren')),
        ));

        expect(find.byIcon(Icons.bakery_dining), findsOneWidget);
      });

      testWidgets(
          'shows category-specific placeholder icon for Fisch',
          (tester) async {
        await tester.pumpWidget(_wrap(
          OfferCard(offer: _offer(imageUrl: null, category: 'Fisch')),
        ));

        expect(find.byIcon(Icons.set_meal), findsOneWidget);
      });

      testWidgets('placeholder container has expected background color',
          (tester) async {
        await tester.pumpWidget(_wrap(
          OfferCard(offer: _offer(imageUrl: null)),
        ));

        // The placeholder should render with the light gray background
        final container = find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == const Color(0xFFF8F9FA));
        expect(container, findsWidgets);
      });
    });
  });
}
