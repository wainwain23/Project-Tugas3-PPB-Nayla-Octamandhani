

int _i(dynamic v, [int def = 0]) => v is num ? v.toInt() : def;
double _d(dynamic v) => v is num ? v.toDouble() : 0.0;

class Dimensions {
  final double width, height, depth;
  Dimensions({required this.width, required this.height, required this.depth});

  factory Dimensions.fromJson(Map<String, dynamic> j) => Dimensions(
        width: _d(j['width']),
        height: _d(j['height']),
        depth: _d(j['depth']),
      );
}

class Review {
  final int rating;
  final String comment, date, reviewerName, reviewerEmail;
  Review({
    required this.rating,
    required this.comment,
    required this.date,
    required this.reviewerName,
    required this.reviewerEmail,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        rating: _i(j['rating']),
        comment: j['comment'] ?? '',
        date: j['date'] ?? '',
        reviewerName: j['reviewerName'] ?? '',
        reviewerEmail: j['reviewerEmail'] ?? '',
      );
}

class Meta {
  final String createdAt, updatedAt, barcode, qrCode;
  Meta({
    required this.createdAt,
    required this.updatedAt,
    required this.barcode,
    required this.qrCode,
  });

  factory Meta.fromJson(Map<String, dynamic> j) => Meta(
        createdAt: j['createdAt'] ?? '',
        updatedAt: j['updatedAt'] ?? '',
        barcode: j['barcode'] ?? '',
        qrCode: j['qrCode'] ?? '',
      );
}

// Dari GET /products/categories -> {slug, name, url}
class Category {
  final String slug, name, url;
  Category({required this.slug, required this.name, required this.url});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        slug: j['slug'] ?? '',
        name: j['name'] ?? '',
        url: j['url'] ?? '',
      );
}

class Product {
  final int id;
  final String title; // bawaan: Essence Mascara Lash Princess
  final String description;
  final String category; // bawaan: beauty, smartphones, furniture, dll
  final double price; // bawaan: 9.99, 19.99, 199.99
  final double discountPercentage;
  final double rating; // bawaan: 4.94
  final int stock;
  final List<String> tags;
  final String brand; // bawaan: Essence, Apple, Samsung
  final String sku;
  final int weight;
  final Dimensions dimensions;
  final String warrantyInformation;
  final String shippingInformation;
  final String availabilityStatus;
  final List<Review> reviews;
  final String returnPolicy;
  final int minimumOrderQuantity;
  final Meta meta;
  final String thumbnail; // bawaan: https://cdn.dummyjson.com/products/images/...
  final List<String> images;
  final bool isDeleted;
  final String? deletedOn;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    this.discountPercentage = 0,
    this.rating = 0,
    this.stock = 0,
    this.tags = const [],
    this.brand = '',
    this.sku = '',
    this.weight = 0,
    Dimensions? dimensions,
    this.warrantyInformation = '',
    this.shippingInformation = '',
    this.availabilityStatus = '',
    this.reviews = const [],
    this.returnPolicy = '',
    this.minimumOrderQuantity = 1,
    Meta? meta,
    this.thumbnail = '',
    this.images = const [],
    this.isDeleted = false,
    this.deletedOn,
  })  : dimensions = dimensions ?? Dimensions(width: 0, height: 0, depth: 0),
        meta = meta ??
            Meta(createdAt: '', updatedAt: '', barcode: '', qrCode: '');

  // Harga setelah diskon
  double get finalPrice => price * (1 - discountPercentage / 100);

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _i(json['id']),
      title: json['title'] ?? '', // contoh bawaan: iPhone 5s
      description: json['description'] ?? '',
      category: json['category'] ?? '', // contoh bawaan: smartphones
      price: _d(json['price']),
      discountPercentage: _d(json['discountPercentage']),
      rating: _d(json['rating']),
      stock: _i(json['stock']),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      brand: json['brand'] ?? '', // bawaan: Apple, Samsung
      sku: json['sku'] ?? '',
      weight: _i(json['weight']),
      dimensions: Dimensions.fromJson(json['dimensions'] ?? {}),
      warrantyInformation: json['warrantyInformation'] ?? '',
      shippingInformation: json['shippingInformation'] ?? '',
      availabilityStatus: json['availabilityStatus'] ?? '',
      reviews:
          (json['reviews'] as List?)?.map((e) => Review.fromJson(e)).toList() ??
              [],
      returnPolicy: json['returnPolicy'] ?? '',
      minimumOrderQuantity: _i(json['minimumOrderQuantity'], 1),
      meta: Meta.fromJson(json['meta'] ?? {}),
      thumbnail: json['thumbnail'] ?? '', // bawaan CDN DummyJSON
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isDeleted: json['isDeleted'] ?? false,
      deletedOn: json['deletedOn'],
    );
  }

  // Dipakai untuk POST /products/add dan PUT /products/{id}
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'brand': brand,
        'stock': stock,
        'thumbnail': thumbnail,
      };

  // Salinan objek dengan sebagian field diganti (objek bersifat immutable)
  Product copyWith({
    String? title,
    double? price,
    int? stock,
    String? category,
    String? brand,
    String? description,
  }) {
    return Product(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      discountPercentage: discountPercentage,
      rating: rating,
      stock: stock ?? this.stock,
      tags: tags,
      brand: brand ?? this.brand,
      sku: sku,
      weight: weight,
      dimensions: dimensions,
      warrantyInformation: warrantyInformation,
      shippingInformation: shippingInformation,
      availabilityStatus: availabilityStatus,
      reviews: reviews,
      returnPolicy: returnPolicy,
      minimumOrderQuantity: minimumOrderQuantity,
      meta: meta,
      thumbnail: thumbnail,
      images: images,
      isDeleted: isDeleted,
      deletedOn: deletedOn,
    );
  }
}

class ProductsResponse {
  final List<Product> products; // bawaan 194 produk
  final int total; // bawaan: 194
  final int skip;
  final int limit; // bawaan: 30

  ProductsResponse({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    final List list = (json['products'] as List?) ?? [];
    return ProductsResponse(
      products: list.map((e) => Product.fromJson(e)).toList(),
      total: json['total'] ?? list.length,
      skip: json['skip'] ?? 0,
      limit: json['limit'] ?? 30,
    );
  }
}
