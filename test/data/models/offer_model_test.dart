import 'package:flutter_test/flutter_test.dart';
import 'package:sparfinder/data/models/offer_model.dart';

void main() {
  group('OfferModel.fromMarktguru', () {
    group('imageUrl construction', () {
      test('builds CDN image URL from offer id', () {
        final json = _minimalJson(id: 12345);
        final model = OfferModel.fromMarktguru(json);

        expect(
          model.imageUrl,
          'https://mg2de.b-cdn.net/api/v1/offers/12345/images/default/0/medium.webp',
        );
      });

      test('uses string id in CDN URL', () {
        final json = _minimalJson(id: 99);
        final model = OfferModel.fromMarktguru(json);

        expect(model.imageUrl, contains('/offers/99/'));
      });

      test('generates fallback id when json id is null', () {
        final json = _minimalJson();
        json.remove('id');
        final model = OfferModel.fromMarktguru(json);

        // Should still produce a valid CDN URL with a timestamp-based id
        expect(model.imageUrl, isNotNull);
        expect(
          model.imageUrl,
          matches(RegExp(
              r'^https://mg2de\.b-cdn\.net/api/v1/offers/\d+/images/default/0/medium\.webp$')),
        );
      });

      test('imageUrl is always non-null from API response', () {
        final json = _minimalJson(id: 1);
        final model = OfferModel.fromMarktguru(json);

        expect(model.imageUrl, isNotNull);
        expect(model.imageUrl!.isNotEmpty, isTrue);
      });
    });

    group('price parsing', () {
      test('parses price from json', () {
        final model = OfferModel.fromMarktguru(_minimalJson(price: 2.49));
        expect(model.price, 2.49);
      });

      test('defaults price to 0 when null', () {
        final json = _minimalJson();
        json.remove('price');
        final model = OfferModel.fromMarktguru(json);
        expect(model.price, 0.0);
      });

      test('sets originalPrice when oldPrice > price', () {
        final json = _minimalJson(price: 1.0);
        json['oldPrice'] = 2.0;
        final model = OfferModel.fromMarktguru(json);
        expect(model.originalPrice, 2.0);
      });

      test('originalPrice is null when oldPrice <= price', () {
        final json = _minimalJson(price: 2.0);
        json['oldPrice'] = 1.0;
        final model = OfferModel.fromMarktguru(json);
        expect(model.originalPrice, isNull);
      });

      test('originalPrice is null when oldPrice equals price', () {
        final json = _minimalJson(price: 1.5);
        json['oldPrice'] = 1.5;
        final model = OfferModel.fromMarktguru(json);
        expect(model.originalPrice, isNull);
      });
    });

    group('supermarket name parsing', () {
      test('extracts supermarket from advertisers array', () {
        final json = _minimalJson();
        json['advertisers'] = [
          {'name': 'REWE'}
        ];
        final model = OfferModel.fromMarktguru(json);
        expect(model.supermarketName, 'REWE');
      });

      test('defaults to Unbekannt when advertisers is empty', () {
        final json = _minimalJson();
        json['advertisers'] = [];
        final model = OfferModel.fromMarktguru(json);
        expect(model.supermarketName, 'Unbekannt');
      });

      test('defaults to Unbekannt when advertisers is null', () {
        final json = _minimalJson();
        json.remove('advertisers');
        final model = OfferModel.fromMarktguru(json);
        expect(model.supermarketName, 'Unbekannt');
      });
    });

    group('product name parsing', () {
      test('uses product.name when available', () {
        final json = _minimalJson();
        json['product'] = {'name': 'Vollmilch 3,5%'};
        json['description'] = 'Some description';
        final model = OfferModel.fromMarktguru(json);
        expect(model.productName, 'Vollmilch 3,5%');
      });

      test('falls back to description when product.name is null', () {
        final json = _minimalJson();
        json['product'] = {'name': null};
        json['description'] = 'Frische Milch';
        final model = OfferModel.fromMarktguru(json);
        expect(model.productName, 'Frische Milch');
      });

      test('falls back to empty string when both are null', () {
        final json = _minimalJson();
        final model = OfferModel.fromMarktguru(json);
        expect(model.productName, '');
      });
    });

    group('brand parsing', () {
      test('extracts brand name', () {
        final json = _minimalJson();
        json['brand'] = {'name': 'Weihenstephan'};
        final model = OfferModel.fromMarktguru(json);
        expect(model.brand, 'Weihenstephan');
      });

      test('brand is null when not present', () {
        final json = _minimalJson();
        final model = OfferModel.fromMarktguru(json);
        expect(model.brand, isNull);
      });
    });

    group('category parsing', () {
      test('extracts first category name', () {
        final json = _minimalJson();
        json['categories'] = [
          {'name': 'Milchprodukte'},
          {'name': 'Getränke'},
        ];
        final model = OfferModel.fromMarktguru(json);
        expect(model.category, 'Milchprodukte');
      });

      test('category is null when categories is empty', () {
        final json = _minimalJson();
        json['categories'] = [];
        final model = OfferModel.fromMarktguru(json);
        expect(model.category, isNull);
      });
    });

    group('unit parsing', () {
      test('combines volume and unit shortName', () {
        final json = _minimalJson();
        json['volume'] = 250;
        json['unit'] = {'shortName': 'g'};
        final model = OfferModel.fromMarktguru(json);
        expect(model.unit, '250 g');
      });

      test('uses integer format for whole numbers', () {
        final json = _minimalJson();
        json['volume'] = 1.0;
        json['unit'] = {'shortName': 'l'};
        final model = OfferModel.fromMarktguru(json);
        expect(model.unit, '1 l');
      });

      test('unit is null when volume is missing', () {
        final json = _minimalJson();
        json['unit'] = {'shortName': 'g'};
        final model = OfferModel.fromMarktguru(json);
        expect(model.unit, isNull);
      });

      test('unit is null when unit map is missing', () {
        final json = _minimalJson();
        json['volume'] = 500;
        final model = OfferModel.fromMarktguru(json);
        expect(model.unit, isNull);
      });
    });

    group('validity dates parsing', () {
      test('parses validFrom and validUntil from validityDates', () {
        final json = _minimalJson();
        json['validityDates'] = [
          {
            'from': '2026-03-01T00:00:00Z',
            'to': '2026-03-15T12:00:00Z',
          }
        ];
        final model = OfferModel.fromMarktguru(json);
        expect(model.validFrom, isNotNull);
        expect(model.validUntil, isNotNull);
        expect(model.validFrom!.year, 2026);
        expect(model.validUntil!.year, 2026);
      });

      test('dates are null when validityDates is empty', () {
        final json = _minimalJson();
        json['validityDates'] = [];
        final model = OfferModel.fromMarktguru(json);
        expect(model.validFrom, isNull);
        expect(model.validUntil, isNull);
      });
    });

    group('toDomain', () {
      test('converts to Offer entity preserving imageUrl', () {
        final model = OfferModel.fromMarktguru(_minimalJson(id: 42));
        final offer = model.toDomain();

        expect(offer.imageUrl, model.imageUrl);
        expect(offer.imageUrl, contains('/offers/42/'));
      });

      test('converts all fields correctly', () {
        final json = _minimalJson(id: 1, price: 1.99);
        json['oldPrice'] = 2.99;
        json['advertisers'] = [
          {'name': 'LIDL'}
        ];
        json['brand'] = {'name': 'Milbona'};
        json['product'] = {'name': 'Vollmilch'};
        json['volume'] = 1;
        json['unit'] = {'shortName': 'l'};

        final model = OfferModel.fromMarktguru(json);
        final offer = model.toDomain();

        expect(offer.id, '1');
        expect(offer.productName, 'Vollmilch');
        expect(offer.brand, 'Milbona');
        expect(offer.price, 1.99);
        expect(offer.originalPrice, 2.99);
        expect(offer.supermarketName, 'LIDL');
        expect(offer.imageUrl, isNotNull);
        expect(offer.unit, '1 l');
      });
    });
  });
}

/// Creates a minimal valid JSON map for OfferModel.fromMarktguru.
Map<String, dynamic> _minimalJson({
  int? id,
  double? price,
}) {
  final json = <String, dynamic>{};
  if (id != null) json['id'] = id;
  if (price != null) json['price'] = price;
  return json;
}
