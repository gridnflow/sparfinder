import 'package:flutter_test/flutter_test.dart';
import 'package:sparfinder/core/utils/price_formatter.dart';

void main() {
  group('PriceFormatter', () {
    group('format', () {
      test('formats whole euro amount', () {
        expect(PriceFormatter.format(1.0), '€ 1,00');
      });

      test('formats price with cents', () {
        expect(PriceFormatter.format(1.99), '€ 1,99');
      });

      test('formats zero', () {
        expect(PriceFormatter.format(0.0), '€ 0,00');
      });

      test('formats single digit cents with leading zero', () {
        expect(PriceFormatter.format(2.05), '€ 2,05');
      });

      test('formats large price', () {
        expect(PriceFormatter.format(19.99), '€ 19,99');
      });

      test('handles floating point precision (0.1 + 0.2)', () {
        // 0.30000000000000004 should round to 30 cents
        expect(PriceFormatter.format(0.1 + 0.2), '€ 0,30');
      });
    });

    group('discountPercent', () {
      test('returns empty when original is 0', () {
        expect(PriceFormatter.discountPercent(0, 0.99), '');
      });

      test('returns empty when original is negative', () {
        expect(PriceFormatter.discountPercent(-1, 0.99), '');
      });

      test('calculates correct percentage', () {
        expect(PriceFormatter.discountPercent(2.0, 1.0), '- 50%');
      });

      test('rounds percentage', () {
        expect(PriceFormatter.discountPercent(3.0, 2.0), '- 33%');
      });

      test('handles 100% discount', () {
        expect(PriceFormatter.discountPercent(1.0, 0.0), '- 100%');
      });
    });

    group('savedAmount', () {
      test('formats savings correctly', () {
        expect(PriceFormatter.savedAmount(1.49, 0.99), 'Sie sparen € 0,50');
      });

      test('formats zero savings', () {
        expect(PriceFormatter.savedAmount(1.0, 1.0), 'Sie sparen € 0,00');
      });
    });
  });
}
