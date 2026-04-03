import '../../domain/entities/offer.dart';

class OfferModel {
  final String id;
  final String productName;
  final String? brand;
  final double price;
  final double? originalPrice;
  final String supermarketName;
  final String? imageUrl;
  final String? category;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? unit;
  final String? description;

  const OfferModel({
    required this.id,
    required this.productName,
    this.brand,
    required this.price,
    this.originalPrice,
    required this.supermarketName,
    this.imageUrl,
    this.category,
    this.validFrom,
    this.validUntil,
    this.unit,
    this.description,
  });

  /// 실제 marktguru API v1 응답 구조 파싱
  /// 응답 예시:
  /// id, price, oldPrice, volume, brand.name, advertisers[0].name,
  /// categories[0].name, product.name, unit.shortName,
  /// validityDates[0].{from,to}, description
  factory OfferModel.fromMarktguru(Map<String, dynamic> json) {
    // 가격
    final price = (json['price'] as num?)?.toDouble() ?? 0;
    final oldPrice = (json['oldPrice'] as num?)?.toDouble();
    final originalPrice = (oldPrice != null && oldPrice > price) ? oldPrice : null;

    // 슈퍼마켓 이름 (advertisers 배열 첫 번째)
    final advertisers = json['advertisers'] as List<dynamic>?;
    final supermarket = advertisers?.isNotEmpty == true
        ? (advertisers!.first as Map<String, dynamic>)['name'] as String? ?? 'Unbekannt'
        : 'Unbekannt';

    // 브랜드
    final brand = (json['brand'] as Map<String, dynamic>?)?['name'] as String?;

    // 카테고리
    final categories = json['categories'] as List<dynamic>?;
    final category = categories?.isNotEmpty == true
        ? (categories!.first as Map<String, dynamic>)['name'] as String?
        : null;

    // 상품명: product.name 우선, 없으면 description 사용
    final product = json['product'] as Map<String, dynamic>?;
    final productName = product?['name'] as String? ??
        json['description'] as String? ?? '';

    // 단위: volume + unit.shortName 조합 (예: "250 g", "1 l")
    final volume = json['volume'] as num?;
    final unitMap = json['unit'] as Map<String, dynamic>?;
    final unitShort = unitMap?['shortName'] as String?;
    String? unit;
    if (volume != null && unitShort != null) {
      final vol = volume == volume.toInt() ? volume.toInt() : volume;
      unit = '$vol $unitShort';
    }

    // 유효기간 (validityDates 배열 첫 번째)
    DateTime? validFrom;
    DateTime? validUntil;
    final validityDates = json['validityDates'] as List<dynamic>?;
    if (validityDates?.isNotEmpty == true) {
      final first = validityDates!.first as Map<String, dynamic>;
      final fromStr = first['from'] as String?;
      final toStr = first['to'] as String?;
      if (fromStr != null) validFrom = DateTime.tryParse(fromStr)?.toLocal();
      if (toStr != null) validUntil = DateTime.tryParse(toStr)?.toLocal();
    }

    final offerId = json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    // 이미지 URL: CDN 패턴으로 생성 (API의 images 필드는 Map이라 URL 없음)
    final imageUrl = 'https://mg2de.b-cdn.net/api/v1/offers/$offerId/images/default/0/medium.webp';

    return OfferModel(
      id: offerId,
      productName: productName,
      brand: brand,
      price: price,
      originalPrice: originalPrice,
      supermarketName: supermarket,
      imageUrl: imageUrl,
      category: category,
      validFrom: validFrom,
      validUntil: validUntil,
      unit: unit,
      description: json['description'] as String?,
    );
  }

  Offer toDomain() {
    return Offer(
      id: id,
      productName: productName,
      brand: brand,
      price: price,
      originalPrice: originalPrice,
      supermarketName: supermarketName,
      imageUrl: imageUrl,
      category: category,
      validFrom: validFrom,
      validUntil: validUntil,
      unit: unit,
      description: description,
    );
  }

  /// Mock 데이터 생성 (API 미연결 시 테스트용)
  static List<OfferModel> generateMockData(String query) {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));

    return [
      OfferModel(
        id: '1',
        productName: query.isEmpty ? 'Vollmilch 3,5%' : query,
        brand: 'Landfein',
        price: 0.79,
        originalPrice: 1.09,
        supermarketName: 'ALDI Süd',
        imageUrl: null,
        category: 'Milchprodukte',
        validFrom: now,
        validUntil: weekEnd,
        unit: '1 l',
      ),
      OfferModel(
        id: '2',
        productName: query.isEmpty ? 'Vollmilch 3,5%' : query,
        brand: 'REWE Bio',
        price: 0.99,
        originalPrice: 1.29,
        supermarketName: 'REWE',
        imageUrl: null,
        category: 'Milchprodukte',
        validFrom: now,
        validUntil: weekEnd,
        unit: '1 l',
      ),
      OfferModel(
        id: '3',
        productName: query.isEmpty ? 'Vollmilch 3,5%' : query,
        brand: 'Milbona',
        price: 0.89,
        originalPrice: null,
        supermarketName: 'LIDL',
        imageUrl: null,
        category: 'Milchprodukte',
        validFrom: now,
        validUntil: weekEnd,
        unit: '1 l',
      ),
      OfferModel(
        id: '4',
        productName: query.isEmpty ? 'Vollmilch 3,5%' : query,
        brand: 'K-Classic',
        price: 1.05,
        originalPrice: 1.35,
        supermarketName: 'Kaufland',
        imageUrl: null,
        category: 'Milchprodukte',
        validFrom: now,
        validUntil: weekEnd,
        unit: '1 l',
      ),
      OfferModel(
        id: '5',
        productName: query.isEmpty ? 'Vollmilch 3,5%' : query,
        brand: 'Penny',
        price: 0.85,
        originalPrice: 1.15,
        supermarketName: 'Penny',
        imageUrl: null,
        category: 'Milchprodukte',
        validFrom: now,
        validUntil: weekEnd,
        unit: '1 l',
      ),
    ];
  }

  static List<OfferModel> generateWeeklyMockDeals() {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));

    // 같은 제품을 여러 마켓이 판매하는 케이스 포함
    return [
      // Butter: ALDI(최저) < LIDL < REWE
      OfferModel(id: 'w1', productName: 'Butter', brand: 'Landfein', price: 1.49, originalPrice: 2.29, supermarketName: 'ALDI Süd', category: 'Milchprodukte', validFrom: now, validUntil: weekEnd, unit: '250 g'),
      OfferModel(id: 'w1b', productName: 'Butter', brand: 'Milbona', price: 1.69, originalPrice: 2.29, supermarketName: 'LIDL', category: 'Milchprodukte', validFrom: now, validUntil: weekEnd, unit: '250 g'),
      OfferModel(id: 'w1c', productName: 'Butter', brand: 'REWE Bio', price: 1.89, originalPrice: 2.49, supermarketName: 'REWE', category: 'Milchprodukte', validFrom: now, validUntil: weekEnd, unit: '250 g'),

      // Eier: 단독
      OfferModel(id: 'w2', productName: 'Eier Freilandhaltung', brand: null, price: 1.99, originalPrice: 2.79, supermarketName: 'LIDL', category: 'Eier', validFrom: now, validUntil: weekEnd, unit: '10 Stück'),

      // Hähnchenbrust: REWE(최저) < Kaufland
      OfferModel(id: 'w3', productName: 'Hähnchenbrust', brand: null, price: 3.49, originalPrice: 5.99, supermarketName: 'REWE', category: 'Fleisch', validFrom: now, validUntil: weekEnd, unit: '500 g'),
      OfferModel(id: 'w3b', productName: 'Hähnchenbrust', brand: null, price: 3.99, originalPrice: 5.99, supermarketName: 'Kaufland', category: 'Fleisch', validFrom: now, validUntil: weekEnd, unit: '500 g'),

      // Gouda: 단독
      OfferModel(id: 'w4', productName: 'Gouda Scheiben', brand: 'Milkana', price: 1.79, originalPrice: 2.49, supermarketName: 'Kaufland', category: 'Käse', validFrom: now, validUntil: weekEnd, unit: '400 g'),

      // Bananen: ALDI(최저) < Penny < Netto
      OfferModel(id: 'w5', productName: 'Bananen', brand: null, price: 1.09, originalPrice: 1.79, supermarketName: 'ALDI Süd', category: 'Obst & Gemüse', validFrom: now, validUntil: weekEnd, unit: '1 kg'),
      OfferModel(id: 'w5b', productName: 'Bananen', brand: null, price: 1.29, originalPrice: 1.79, supermarketName: 'Penny', category: 'Obst & Gemüse', validFrom: now, validUntil: weekEnd, unit: '1 kg'),
      OfferModel(id: 'w5c', productName: 'Bananen', brand: null, price: 1.49, originalPrice: 1.99, supermarketName: 'Netto', category: 'Obst & Gemüse', validFrom: now, validUntil: weekEnd, unit: '1 kg'),

      // Toastbrot: 단독
      OfferModel(id: 'w6', productName: 'Toastbrot', brand: 'Lieken Urkorn', price: 0.99, originalPrice: 1.49, supermarketName: 'ALDI Nord', category: 'Brot & Backwaren', validFrom: now, validUntil: weekEnd, unit: '500 g'),

      // Cola: LIDL(최저) < Kaufland
      OfferModel(id: 'w7', productName: 'Coca-Cola', brand: 'Coca-Cola', price: 0.79, originalPrice: 1.29, supermarketName: 'LIDL', category: 'Getränke', validFrom: now, validUntil: weekEnd, unit: '1,5 l'),
      OfferModel(id: 'w7b', productName: 'Coca-Cola', brand: 'Coca-Cola', price: 0.99, originalPrice: 1.29, supermarketName: 'Kaufland', category: 'Getränke', validFrom: now, validUntil: weekEnd, unit: '1,5 l'),

      // Joghurt: 단독
      OfferModel(id: 'w8', productName: 'Joghurt', brand: 'Activia', price: 2.49, originalPrice: 3.29, supermarketName: 'REWE', category: 'Milchprodukte', validFrom: now, validUntil: weekEnd, unit: '4x125 g'),

      // Lachs: Kaufland(최저) < REWE
      OfferModel(id: 'w9', productName: 'Lachs', brand: null, price: 4.99, originalPrice: 7.99, supermarketName: 'Kaufland', category: 'Fisch', validFrom: now, validUntil: weekEnd, unit: '400 g'),
      OfferModel(id: 'w9b', productName: 'Lachs', brand: null, price: 5.49, originalPrice: 7.99, supermarketName: 'REWE', category: 'Fisch', validFrom: now, validUntil: weekEnd, unit: '400 g'),

      // Apfel: 단독
      OfferModel(id: 'w10', productName: 'Apfel Gala', brand: null, price: 1.49, originalPrice: 1.99, supermarketName: 'Netto', category: 'Obst & Gemüse', validFrom: now, validUntil: weekEnd, unit: '1 kg'),

      // Sonnenblumenöl: 단독
      OfferModel(id: 'w11', productName: 'Öl Sonnenblumenöl', brand: 'Brat-Fix', price: 1.29, originalPrice: 2.19, supermarketName: 'ALDI Süd', category: 'Öl & Essig', validFrom: now, validUntil: weekEnd, unit: '1 l'),

      // Müsli: 단독
      OfferModel(id: 'w12', productName: 'Müsli', brand: 'Dr. Oetker', price: 1.99, originalPrice: 2.99, supermarketName: 'REWE', category: 'Frühstück', validFrom: now, validUntil: weekEnd, unit: '500 g'),
    ];
  }
}

// Flutter의 UniqueKey를 사용하기 위한 임시 구현
class UniqueKey {
  @override
  String toString() => DateTime.now().millisecondsSinceEpoch.toString();
}
