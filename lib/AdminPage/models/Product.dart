import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Product {
  final String id;
  final String uuid;
  final String name;
  final double price;
  final String? description;
  final String categoryId;
  final String brandId;
  final int stock;
  final double? discountPrice;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> images; // Changed from imageUrls to images for consistency
  final Map<String, dynamic>? specifications;
  final double? rating;
  final int reviewCount;
  final List<String>? searchKeywords;
  final String? unit;
  final double? weight;
  final String? sku;
  final Map<String, dynamic>? variants;
  final bool isFeatured;
  final int soldCount;

  Product({
    required this.id,
    required this.uuid,
    required this.name,
    required this.price,
    this.description,
    required this.categoryId,
    required this.brandId,
    required this.stock,
    this.discountPrice,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.images = const [], // Default to empty list
    this.specifications,
    this.rating,
    this.reviewCount = 0,
    this.searchKeywords,
    this.unit,
    this.weight,
    this.sku,
    this.variants,
    this.isFeatured = false,
    this.soldCount = 0,
  });

  // Get primary image URL (first image or null if no images)
  String? get primaryImageUrl => images.isNotEmpty ? images.first : null;

  // Get secondary images (all images except the first one)
  List<String> get secondaryImages =>
      images.length > 1 ? images.sublist(1) : [];

  // Check if product has images
  bool get hasImages => images.isNotEmpty;

  // Generate search keywords from product name
  List<String> generateSearchKeywords() {
    final keywords = <String>[];
    final words = name.toLowerCase().split(' ');

    for (var word in words) {
      for (var i = 1; i <= word.length; i++) {
        keywords.add(word.substring(0, i));
      }
    }
    return keywords;
  }

  // Calculate discount percentage
  double? get discountPercentage {
    if (discountPrice != null && discountPrice! < price) {
      return ((price - discountPrice!) / price * 100).roundToDouble();
    }
    return null;
  }

  bool get isInStock => stock > 0;
  double get finalPrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  Product copyWith({
    String? id,
    String? uuid,
    String? name,
    double? price,
    String? description,
    String? categoryId,
    String? brandId,
    int? stock,
    double? discountPrice,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? images,
    Map<String, dynamic>? specifications,
    double? rating,
    int? reviewCount,
    List<String>? searchKeywords,
    String? unit,
    double? weight,
    String? sku,
    Map<String, dynamic>? variants,
    bool? isFeatured,
    int? soldCount,
  }) {
    return Product(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      stock: stock ?? this.stock,
      discountPrice: discountPrice ?? this.discountPrice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
      specifications: specifications ?? this.specifications,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      unit: unit ?? this.unit,
      weight: weight ?? this.weight,
      sku: sku ?? this.sku,
      variants: variants ?? this.variants,
      isFeatured: isFeatured ?? this.isFeatured,
      soldCount: soldCount ?? this.soldCount,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      uuid: map['uuid'] ?? const Uuid().v4(),
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'],
      categoryId: map['categoryId'] ?? '',
      brandId: map['brandId'] ?? '',
      stock: map['stock'] ?? 0,
      discountPrice: map['discountPrice']?.toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] == null
          ? null
          : (map['updatedAt'] as Timestamp).toDate(),
      images: List<String>.from(map['images'] ?? []),
      specifications: map['specifications'],
      rating: map['rating']?.toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      searchKeywords: List<String>.from(map['searchKeywords'] ?? []),
      unit: map['unit'],
      weight: map['weight']?.toDouble(),
      sku: map['sku'],
      variants: map['variants'],
      isFeatured: map['isFeatured'] ?? false,
      soldCount: map['soldCount'] ?? 0,
    );
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      uuid: data['uuid'] ?? const Uuid().v4(),
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'],
      categoryId: data['categoryId'] ?? '',
      brandId: data['brandId'] ?? '',
      stock: data['stock'] ?? 0,
      discountPrice: data['discountPrice']?.toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      images: List<String>.from(data['images'] ?? []),
      specifications: data['specifications'],
      rating: data['rating']?.toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
      unit: data['unit'],
      weight: data['weight']?.toDouble(),
      sku: data['sku'],
      variants: data['variants'],
      isFeatured: data['isFeatured'] ?? false,
      soldCount: data['soldCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'name': name,
      'price': price,
      'description': description,
      'categoryId': categoryId,
      'brandId': brandId,
      'stock': stock,
      'discountPrice': discountPrice,
      'isActive': isActive,
      'createdAt': id.isEmpty ? FieldValue.serverTimestamp() : createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
      'images': images,
      'specifications': specifications,
      'rating': rating,
      'reviewCount': reviewCount,
      'searchKeywords': searchKeywords ?? generateSearchKeywords(),
      'unit': unit,
      'weight': weight,
      'sku': sku,
      'variants': variants,
      'isFeatured': isFeatured,
      'soldCount': soldCount,
    };
  }

  // Firebase helper methods
  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('products');

  static Future<Product> getById(String id) async {
    final doc = await collection.doc(id).get();
    if (!doc.exists) throw Exception('Product not found');
    return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  static Stream<List<Product>> getActiveProducts() {
    return collection.where('isActive', isEqualTo: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  static Stream<List<Product>> getFeaturedProducts() {
    return collection
        .where('isFeatured', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  static Stream<List<Product>> getByCategoryId(String categoryId) {
    return collection
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  static Stream<List<Product>> getByBrandId(String brandId) {
    return collection
        .where('brandId', isEqualTo: brandId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  static Stream<List<Product>> search(String query) {
    return collection
        .where('searchKeywords', arrayContains: query.toLowerCase())
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  static Stream<List<Product>> getProductsWithImages() {
    return collection.where('isActive', isEqualTo: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((product) => product.hasImages)
            .toList());
  }

  static Stream<List<Product>> getProductsInStockRange(int min, int max) {
    return collection
        .where('isActive', isEqualTo: true)
        .where('stock', isGreaterThanOrEqualTo: min)
        .where('stock', isLessThanOrEqualTo: max)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  static Stream<List<Product>> getProductsInPriceRange(double min, double max) {
    return collection
        .where('isActive', isEqualTo: true)
        .where('price', isGreaterThanOrEqualTo: min)
        .where('price', isLessThanOrEqualTo: max)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> save() async {
    final data = toMap();
    final firestore = FirebaseFirestore.instance;

    await firestore.runTransaction((transaction) async {
      if (id.isEmpty) {
        // New product
        final productRef = collection.doc();
        transaction.set(productRef, data);

        // Increment category product count
        if (categoryId.isNotEmpty) {
          final categoryRef =
              firestore.collection('categories').doc(categoryId);
          transaction.update(categoryRef, {
            'productCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Existing product
        final productRef = collection.doc(id);
        final productSnapshot = await transaction.get(productRef);

        if (productSnapshot.exists) {
          final oldData = productSnapshot.data() as Map<String, dynamic>;
          final oldCategoryId = oldData['categoryId'] ?? '';

          // Handle category change
          if (oldCategoryId != categoryId) {
            // Decrement old category count
            if (oldCategoryId.isNotEmpty) {
              final oldCategoryRef =
                  firestore.collection('categories').doc(oldCategoryId);
              transaction.update(oldCategoryRef, {
                'productCount': FieldValue.increment(-1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }

            // Increment new category count
            if (categoryId.isNotEmpty) {
              final newCategoryRef =
                  firestore.collection('categories').doc(categoryId);
              transaction.update(newCategoryRef, {
                'productCount': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }

          // Update product document
          transaction.update(productRef, data);
        } else {
          throw Exception('Product not found');
        }
      }
    });
  }

  Future<void> delete() async {
    final productRef = collection.doc(id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Get latest product data
      final productSnapshot = await transaction.get(productRef);
      if (!productSnapshot.exists) return;

      final productData = productSnapshot.data() as Map<String, dynamic>;
      final currentCategoryId = productData['categoryId'] as String? ?? '';

      // Delete product
      transaction.delete(productRef);

      // Update category if exists
      if (currentCategoryId.isNotEmpty) {
        final categoryRef = FirebaseFirestore.instance
            .collection('categories')
            .doc(currentCategoryId);
        final categorySnapshot = await transaction.get(categoryRef);

        if (categorySnapshot.exists) {
          transaction.update(categoryRef, {
            'productCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  Future<void> toggleActive() async {
    await collection.doc(id).update({
      'isActive': !isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStock(int quantity) async {
    await collection.doc(id).update({
      'stock': FieldValue.increment(quantity),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRating(double newRating, int newReviewCount) async {
    await collection.doc(id).update({
      'rating': newRating,
      'reviewCount': newReviewCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementSoldCount(int quantity) async {
    await FirebaseFirestore.instance.collection('products').doc(id).update({
      'soldCount': FieldValue.increment(quantity),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Image management methods
  Future<void> addImage(String imageUrl) async {
    final updatedImages = [...images, imageUrl];
    await collection.doc(id).update({
      'images': updatedImages,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeImage(String imageUrl) async {
    final updatedImages = images.where((url) => url != imageUrl).toList();
    await collection.doc(id).update({
      'images': updatedImages,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateImages(List<String> newImages) async {
    await collection.doc(id).update({
      'images': newImages,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reorderImages(List<String> reorderedImages) async {
    await collection.doc(id).update({
      'images': reorderedImages,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> toggleWishlist(String userId, String productId,
      [Map<String, dynamic>? productData]) async {
    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(productId);

    final doc = await wishlistRef.get();
    if (doc.exists) {
      await wishlistRef.delete();
    } else {
      // Get complete product data
      Map<String, dynamic> data = productData ?? {};
      if (data.isEmpty) {
        final productDoc = await collection.doc(productId).get();
        if (!productDoc.exists) return;
        data = productDoc.data() as Map<String, dynamic>;
      }

      // Store comprehensive product details
      await wishlistRef.set({
        'id': productId,
        'productId': productId,
        'addedAt': FieldValue.serverTimestamp(),
        'name': data['name']?.toString() ?? '',
        'price': data['price'],
        'discountPrice': data['discountPrice'],
        'stock': data['stock'],
        'images': data['images'] ?? [],
        'imageUrl': (data['images'] != null && data['images'].isNotEmpty)
            ? data['images'][0]
            : data['imageUrl'] ?? '',
        'rating': data['rating'],
        'reviewCount': data['reviewCount'],
        'categoryId': data['categoryId'],
        'brandId': data['brandId'],
        'description': data['description'] ?? '',
        'isActive': data['isActive'] ?? true,
      });
    }
  }

  static Stream<QuerySnapshot> getUserWishlist(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .snapshots();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uuid == other.uuid;

  @override
  int get hashCode => id.hashCode ^ uuid.hashCode;

  @override
  String toString() => 'Product(id: $id, name: $name, price: $price)';
}
