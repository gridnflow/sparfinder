import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparfinder/core/providers/app_providers.dart';
import 'package:sparfinder/domain/entities/offer.dart';

Offer _offer(String id, {String name = 'Milch', double price = 1.0}) {
  return Offer(
    id: id,
    productName: name,
    price: price,
    supermarketName: 'ALDI',
  );
}

void main() {
  group('SavedOffersNotifier', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('starts with empty list', () {
      final notifier = SavedOffersNotifier(prefs);
      expect(notifier.state, isEmpty);
    });

    test('toggle adds an offer', () {
      final notifier = SavedOffersNotifier(prefs);
      final offer = _offer('1');

      notifier.toggle(offer);

      expect(notifier.state, hasLength(1));
      expect(notifier.state.first.id, '1');
    });

    test('toggle removes an already-saved offer', () {
      final notifier = SavedOffersNotifier(prefs);
      final offer = _offer('1');

      notifier.toggle(offer);
      notifier.toggle(offer);

      expect(notifier.state, isEmpty);
    });

    test('toggle persists IDs to SharedPreferences', () {
      final notifier = SavedOffersNotifier(prefs);

      notifier.toggle(_offer('1'));
      notifier.toggle(_offer('2'));

      expect(prefs.getStringList('saved_offers'), ['1', '2']);
    });

    test('toggle removes from SharedPreferences', () {
      final notifier = SavedOffersNotifier(prefs);

      notifier.toggle(_offer('1'));
      notifier.toggle(_offer('2'));
      notifier.toggle(_offer('1'));

      expect(prefs.getStringList('saved_offers'), ['2']);
    });

    test('isSaved returns true for saved offer', () {
      final notifier = SavedOffersNotifier(prefs);

      notifier.toggle(_offer('1'));

      expect(notifier.isSaved('1'), isTrue);
      expect(notifier.isSaved('2'), isFalse);
    });

    test('isSaved returns false after removing', () {
      final notifier = SavedOffersNotifier(prefs);

      notifier.toggle(_offer('1'));
      notifier.toggle(_offer('1'));

      expect(notifier.isSaved('1'), isFalse);
    });

    test('multiple offers can be saved', () {
      final notifier = SavedOffersNotifier(prefs);

      notifier.toggle(_offer('1', name: 'Milch'));
      notifier.toggle(_offer('2', name: 'Brot'));
      notifier.toggle(_offer('3', name: 'Butter'));

      expect(notifier.state, hasLength(3));
      expect(notifier.state.map((o) => o.id), ['1', '2', '3']);
    });

    test('toggle identifies offer by id, not by reference', () {
      final notifier = SavedOffersNotifier(prefs);

      // Add with one price
      notifier.toggle(_offer('1', price: 1.0));
      // Remove with different price but same id
      notifier.toggle(_offer('1', price: 2.0));

      expect(notifier.state, isEmpty);
    });
  });
}
