import 'package:flutter_test/flutter_test.dart';
import 'package:sparfinder/core/constants/supermarket_constants.dart';

void main() {
  group('SupermarketConstants', () {
    group('isKnownSupermarket', () {
      test('recognizes exact match', () {
        expect(SupermarketConstants.isKnownSupermarket('aldi'), isTrue);
        expect(SupermarketConstants.isKnownSupermarket('lidl'), isTrue);
        expect(SupermarketConstants.isKnownSupermarket('rewe'), isTrue);
      });

      test('recognizes case-insensitive names', () {
        expect(SupermarketConstants.isKnownSupermarket('ALDI'), isTrue);
        expect(SupermarketConstants.isKnownSupermarket('Lidl'), isTrue);
        expect(SupermarketConstants.isKnownSupermarket('REWE'), isTrue);
      });

      test('recognizes names with spaces', () {
        expect(SupermarketConstants.isKnownSupermarket('ALDI Süd'), isTrue);
        expect(SupermarketConstants.isKnownSupermarket('ALDI Nord'), isTrue);
      });

      test('recognizes variant names', () {
        expect(
            SupermarketConstants.isKnownSupermarket('Netto Marken-Discount'),
            isTrue);
        expect(SupermarketConstants.isKnownSupermarket('REWE City'), isTrue);
      });

      test('rejects unknown supermarket', () {
        expect(SupermarketConstants.isKnownSupermarket('Walmart'), isFalse);
        expect(SupermarketConstants.isKnownSupermarket(''), isFalse);
      });
    });

    group('getInfo', () {
      test('returns correct info for known supermarket', () {
        final info = SupermarketConstants.getInfo('rewe');
        expect(info.name, 'REWE');
        expect(info.emoji, '🔴');
      });

      test('returns fallback for unknown supermarket', () {
        final info = SupermarketConstants.getInfo('Walmart');
        expect(info.name, 'Walmart');
        expect(info.emoji, '🛒');
        expect(info.color, 0xFF888888);
      });

      test('matches case-insensitive with spaces removed', () {
        final info = SupermarketConstants.getInfo('ALDI Süd');
        expect(info.name, 'ALDI Süd');
      });
    });
  });
}
