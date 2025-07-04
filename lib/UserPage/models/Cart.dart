import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
class CartItem {
  final String id;
  final String productId;
  final String userId;
  final int quantity;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.productId,
    required this.userId,
    required this.quantity,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'quantity': quantity,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  static CartItem fromMap(Map<String, dynamic> map, String id) {
    return CartItem(
      id: id,
      productId: map['productId'],
      userId: map['userId'],
      quantity: map['quantity'],
      addedAt: (map['addedAt'] as Timestamp).toDate(),
    );
  }

  static CollectionReference getCollection(String userId) {
    // Ensure we're using the correct path that matches security rules
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart');
  }

 static Stream<List<CartItem>> getUserCart(String userId) {
  try {
    return getCollection(userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                return CartItem.fromMap(
                  doc.data() as Map<String, dynamic>, 
                  doc.id
                );
              } catch (e) {
                debugPrint('Error parsing cart item ${doc.id}: $e');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<CartItem>()
            .toList())
        .handleError((error) {
          debugPrint('Error fetching cart: $error');
          return <CartItem>[];
        });
  } catch (e) {
    debugPrint('Error setting up cart stream: $e');
    return Stream.value([]);
  }
}

  static Future<void> addToCart({
  required String userId,
  required String productId,
  required int quantity,
}) async {
  try {
    // First ensure the user document exists
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({}, SetOptions(merge: true));

    final cartRef = getCollection(userId);
    final existingItem = await cartRef
        .where('productId', isEqualTo: productId)
        .get();

    if (existingItem.docs.isNotEmpty) {
      final currentQuantity = existingItem.docs.first.get('quantity') as int;
      await cartRef.doc(existingItem.docs.first.id).update({
        'quantity': currentQuantity + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await cartRef.add({
        'productId': productId,
        'userId': userId,
        'quantity': quantity,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  } catch (e) {
    debugPrint('Error adding to cart: $e');
    throw Exception('Failed to add to cart: $e');
  }
}

  static Future<void> updateQuantity({
    required String userId,
    required String itemId,
    required int quantity,
  }) async {
    try {
      await getCollection(userId).doc(itemId).update({
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      throw Exception('Failed to update quantity: $e');
    }
  }

  static Future<void> removeFromCart({
    required String userId,
    required String itemId,
  }) async {
    try {
      await getCollection(userId).doc(itemId).delete();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      throw Exception('Failed to remove item: $e');
    }
  }
}
