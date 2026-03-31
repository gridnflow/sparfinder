import 'package:flutter_test/flutter_test.dart';
import 'package:sparfinder/domain/entities/offer.dart';

Offer _makeOffer({
  String id = '1',
  String productName = 'Milch',
  String? brand,
  double price = 1.09,
  double? originalPrice,
  String supermarketName = 'ALDI',
  DateTime? validFrom,
  DateTime? validUntil,
}) {
  return Offer(
    id: id,
    productName: productName,
    brand: brand,
    price: price,
    originalPrice: originalPrice,
    supermarketName: supermarketName,
    validFrom: validFrom,
    validUntil: validUntil,
  );
}

void main() {
  group('Offer', () {
    group('displayName', () {
      test('returns productName when brand is null', () {
        final offer = _makeOffer(brand: null);
        expect(offer.displayName, 'Milch');
      });

      test('returns productName when brand is empty', () {
        final offer = _makeOffer(brand: '');
        expect(offer.displayName, 'Milch');
      });

      test('returns "brand productName" when brand is set', () {
        final offer = _makeOffer(brand: 'Weihenstephan');
        expect(offer.displayName, 'Weihenstephan Milch');
      });
    });

    group('hasDiscount', () {
      test('false when originalPrice is null', () {
        final offer = _makeOffer(originalPrice: null);
        expect(offer.hasDiscount, isFalse);
      });

      test('false when originalPrice equals price', () {
        final offer = _makeOffer(price: 1.09, originalPrice: 1.09);
        expect(offer.hasDiscount, isFalse);
      });

      test('false when originalPrice is less than price', () {
        final offer = _makeOffer(price: 1.09, originalPrice: 0.99);
        expect(offer.hasDiscount, isFalse);
      });

      test('true when originalPrice is greater than price', () {
        final offer = _makeOffer(price: 0.99, originalPrice: 1.49);
        expect(offer.hasDiscount, isTrue);
      });
    });

    group('discountPercent', () {
      test('returns 0 when originalPrice is null', () {
        final offer = _makeOffer(originalPrice: null);
        expect(offer.discountPercent, 0);
      });

      test('returns 0 when originalPrice is 0', () {
        final offer = _makeOffer(price: 1.0, originalPrice: 0);
        expect(offer.discountPercent, 0);
      });

      test('returns 0 when originalPrice is negative', () {
        final offer = _makeOffer(price: 1.0, originalPrice: -1.0);
        expect(offer.discountPercent, 0);
      });

      test('calculates correct discount percentage', () {
        final offer = _makeOffer(price: 0.75, originalPrice: 1.50);
        expect(offer.discountPercent, 50.0);
      });

      test('handles small discounts', () {
        final offer = _makeOffer(price: 0.99, originalPrice: 1.0);
        expect(offer.discountPercent, closeTo(1.0, 0.1));
      });
    });

    group('isValid', () {
      test('true when no dates set', () {
        final offer = _makeOffer();
        expect(offer.isValid, isTrue);
      });

      test('false when validFrom is in the future', () {
        final offer = _makeOffer(
          validFrom: DateTime.now().add(const Duration(days: 1)),
        );
        expect(offer.isValid, isFalse);
      });

      test('false when validUntil is in the past', () {
        final offer = _makeOffer(
          validUntil: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(offer.isValid, isFalse);
      });

      test('true when within valid range', () {
        final offer = _makeOffer(
          validFrom: DateTime.now().subtract(const Duration(days: 1)),
          validUntil: DateTime.now().add(const Duration(days: 1)),
        );
        expect(offer.isValid, isTrue);
      });
    });

    group('equality', () {
      test('two offers with same id are equal', () {
        final a = _makeOffer(id: '1', price: 1.0);
        final b = _makeOffer(id: '1', price: 2.0);
        expect(a, equals(b));
      });

      test('two offers with different ids are not equal', () {
        final a = _makeOffer(id: '1');
        final b = _makeOffer(id: '2');
        expect(a, isNot(equals(b)));
      });

      test('hashCode is based on id', () {
        final a = _makeOffer(id: '1', price: 1.0);
        final b = _makeOffer(id: '1', price: 2.0);
        expect(a.hashCode, equals(b.hashCode));
      });
    });
  });
}
