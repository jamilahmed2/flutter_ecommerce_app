import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

// Category Model
class Category {
  final String id;
  final String uuid;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int productCount;

  Category({
    required this.id,
    required this.uuid,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.productCount = 0,
  });

  factory Category.fromMap(Map<String, dynamic> map, String id) {
    return Category(
      id: id,
      uuid: map['uuid'] ?? const Uuid().v4(),
      name: map['name'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null 
        ? (map['createdAt'] as Timestamp).toDate() 
        : DateTime(2000),
      updatedAt: map['updatedAt'] == null
          ? null
          : (map['updatedAt'] as Timestamp).toDate(),
      productCount: map['productCount'] ?? 0,
    );
  }
  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      uuid: data['uuid'] ?? const Uuid().v4(),
      name: data['name'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      productCount: data['productCount'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'productCount': productCount,
    };
  }

  static Stream<List<Category>> getActiveCategories() {
    return FirebaseFirestore.instance
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Category(
          id: doc.id,
          uuid: data['uuid'] ?? const Uuid().v4(),
          name: data['name'] ?? '',
          imageUrl: data['imageUrl'],
          isActive: data['isActive'] ?? true,
          description: data['description'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
          productCount: data['productCount'] ?? 0,
        );
      }).toList();
    });
  }
}
