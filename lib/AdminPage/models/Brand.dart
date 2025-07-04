import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Brand {
  final String id;
  final String uuid;
  final String name;
  final String? description;
  final String? website;
  final String? logoUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive; // Added isActive field

  Brand({
    required this.id,
    required this.uuid,
    required this.name,
    this.description,
    this.website,
    this.logoUrl,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    required this.isActive, // Added to constructor
  });

  /// Factory constructor to create a Brand from a Firestore document
  factory Brand.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Brand(
      id: doc.id,
      uuid: data['uuid'] ?? const Uuid().v4(),
      name: data['name'] ?? '',
      description: data['description'],
      website: data['website'],
      logoUrl: data['logoUrl'],
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true, // Added isActive field
    );
  }

  /// Converts a Brand instance to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'name': name,
      'description': description,
      'website': website,
      'logoUrl': logoUrl,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive, // Added isActive field
    };
  }

  /// Get stream of active brands
  static Stream<List<Brand>> getActiveBrands() {
    return FirebaseFirestore.instance
        .collection('brands')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Brand.fromDocument(doc))
            .toList());
  }
}