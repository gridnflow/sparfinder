import 'package:flutter_test/flutter_test.dart';
import 'package:sparfinder/domain/entities/offer.dart';
import 'package:sparfinder/domain/entities/price_comparison.dart';

Offer _offer(String id, double price, String market) {
  return Offer(
    id: id,
    productName: 'Milch',
    price: price,
    supermarketName: market,
  );
}

void main() {
  group('PriceComparison', () {
    test('fromOffers sorts by price ascending', () {
      final offers = [
        _offer('3', 1.49, 'REWE'),
        _offer('1', 0.89, 'ALDI'),
        _offer('2', 1.19, 'Lidl'),
      ];

      final comparison = PriceComparison.fromOffers(offers);

      expect(comparison.offers[0].price, 0.89);
      expect(comparison.offers[1].price, 1.19);
      expect(comparison.offers[2].price, 1.49);
    });

    test('cheapest returns lowest priced offer', () {
      final comparison = PriceComparison.fromOffers([
        _offer('1', 1.49, 'REWE'),
        _offer('2', 0.89, 'ALDI'),
      ]);

      expect(comparison.cheapest!.id, '2');
    });

    test('mostExpensive returns highest priced offer', () {
      final comparison = PriceComparison.fromOffers([
        _offer('1', 1.49, 'REWE'),
        _offer('2', 0.89, 'ALDI'),
      ]);

      expect(comparison.mostExpensive!.id, '1');
    });

    test('priceDifference calculates savings', () {
      final comparison = PriceComparison.fromOffers([
        _offer('1', 1.49, 'REWE'),
        _offer('2', 0.89, 'ALDI'),
      ]);

      expect(comparison.priceDifference, closeTo(0.60, 0.01));
    });

    test('empty list returns null cheapest/mostExpensive', () {
      final comparison = PriceComparison.fromOffers([]);

      expect(comparison.cheapest, isNull);
      expect(comparison.mostExpensive, isNull);
      expect(comparison.priceDifference, 0);
    });

    test('single offer has no price difference', () {
      final comparison = PriceComparison.fromOffers([
        _offer('1', 0.89, 'ALDI'),
      ]);

      expect(comparison.priceDifference, 0);
      expect(comparison.hasMultipleOffers, isFalse);
    });

    test('hasMultipleOffers is true when more than one offer', () {
      final comparison = PriceComparison.fromOffers([
        _offer('1', 0.89, 'ALDI'),
        _offer('2', 1.19, 'Lidl'),
      ]);

      expect(comparison.hasMultipleOffers, isTrue);
    });

    test('productName comes from first raw offer', () {
      final comparison = PriceComparison.fromOffers([
        _offer('1', 0.89, 'ALDI'),
      ]);

      expect(comparison.productName, 'Milch');
    });

    test('empty offers gives empty productName', () {
      final comparison = PriceComparison.fromOffers([]);
      expect(comparison.productName, '');
    });
  });
}
