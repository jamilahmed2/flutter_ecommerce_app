import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String shippingAddress;
  final String paymentMethod;
  final String contactNumber;
  final String? trackingId;
  final bool soldCountUpdated;
  final bool stockReduced; // Added to track if stock was reduced

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.contactNumber,
    this.trackingId,
    required this.soldCountUpdated,
    required this.stockReduced, // Added
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'contactNumber': contactNumber,
      'trackingId': trackingId,
      'soldCountUpdated': soldCountUpdated,
      'stockReduced': stockReduced, // Added
    };
  }

  static Order fromMap(Map<String, dynamic> map, String orderId) {
    return Order(
      id: orderId,
      userId: map['userId'],
      items: (map['items'] as List)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      deliveryFee: (map['deliveryFee'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      shippingAddress: map['shippingAddress'],
      paymentMethod: map['paymentMethod'],
      contactNumber: map['contactNumber'],
      trackingId: map['trackingId'],
      soldCountUpdated: map['soldCountUpdated'] as bool? ?? false,
      stockReduced: map['stockReduced'] as bool? ?? false, // Added with default
    );
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('orders');

  static Future<String> createOrder({
    required String userId,
    required List<OrderItem> items,
    required double subtotal,
    required double deliveryFee,
    required String shippingAddress,
    required String paymentMethod,
    required String contactNumber,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final productsRef = firestore.collection('products');
    final ordersRef = firestore.collection('orders');

    // Calculate product quantities
    final productQuantities = _calculateProductQuantities(items);

    // Start transaction
    return firestore.runTransaction<String>((transaction) async {
      // 1. Verify stock and prepare updates
      final Map<String, int> stockUpdates = {};

      for (final productId in productQuantities.keys) {
        final doc = await transaction.get(productsRef.doc(productId));
        if (!doc.exists) {
          throw Exception('Product $productId not found');
        }

        final currentStock = (doc.data()!['stock'] as num).toInt();
        final orderedQty = productQuantities[productId]!;

        if (currentStock < orderedQty) {
          throw Exception('Insufficient stock for product $productId');
        }

        stockUpdates[productId] = currentStock - orderedQty;
      }

      // 2. Create order document
      final orderData = {
        'userId': userId,
        'items': items.map((item) => item.toMap()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': subtotal + deliveryFee,
        'status': OrderStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'contactNumber': contactNumber,
        'soldCountUpdated': false,
        'stockReduced': true, // Mark stock as reduced
      };

      final orderRef = ordersRef.doc();
      transaction.set(orderRef, orderData);

      // 3. Update product stocks
      for (final productId in stockUpdates.keys) {
        transaction.update(
            productsRef.doc(productId), {'stock': stockUpdates[productId]});
      }

      return orderRef.id;
    });
  }

  // Helper to calculate total quantities per product
  static Map<String, int> _calculateProductQuantities(List<OrderItem> items) {
    final quantities = <String, int>{};
    for (final item in items) {
      quantities[item.productId] =
          (quantities[item.productId] ?? 0) + item.quantity;
    }
    return quantities;
  }

  Future<void> updateStatus(OrderStatus newStatus) async {
    final orderRef = collection.doc(id);
    final batch = FirebaseFirestore.instance.batch();
    final productsRef = FirebaseFirestore.instance.collection('products');

    // Common update data
    final updateData = {
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Handle delivered status
    if (newStatus == OrderStatus.delivered) {
      // Case 1: First-time delivery
      if (!soldCountUpdated && !stockReduced) {
        for (final item in mergedItems) {
          batch.update(productsRef.doc(item.productId), {
            'soldCount': FieldValue.increment(item.quantity),
            'stock': FieldValue.increment(-item.quantity),
          });
        }
        batch.update(orderRef, {
          ...updateData,
          'soldCountUpdated': true,
          'stockReduced': true,
        });
      }
      // Case 2: Re-delivery after cancellation
      else if (!stockReduced) {
        for (final item in mergedItems) {
          batch.update(productsRef.doc(item.productId), {
            'soldCount': FieldValue.increment(item.quantity),
            'stock': FieldValue.increment(-item.quantity),
          });
        }
        batch.update(orderRef, {
          ...updateData,
          'soldCountUpdated': true,
          'stockReduced': true,
        });
      }
      // Case 3: Already delivered - just update status
      else {
        batch.update(orderRef, updateData);
      }
    }
    // Handle cancellation
    else if (newStatus == OrderStatus.cancelled &&
        status != OrderStatus.cancelled) {
      // Case 1: Cancelling a delivered order
      if (soldCountUpdated) {
        for (final item in mergedItems) {
          batch.update(productsRef.doc(item.productId), {
            'soldCount': FieldValue.increment(-item.quantity),
            'stock': FieldValue.increment(item.quantity),
          });
        }
        batch.update(orderRef, {
          ...updateData,
          'soldCountUpdated': false,
          'stockReduced': false,
        });
      }
      // Case 2: Cancelling a non-delivered order (stock was reduced at creation)
      else if (stockReduced) {
        for (final item in mergedItems) {
          batch.update(productsRef.doc(item.productId), {
            'stock': FieldValue.increment(item.quantity),
          });
        }
        batch.update(orderRef, {
          ...updateData,
          'stockReduced': false,
        });
      }
      // Case 3: No stock to restore (shouldn't happen normally)
      else {
        batch.update(orderRef, updateData);
      }
    }
    // Regular status update
    else {
      batch.update(orderRef, updateData);
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('🔥 Error updating order status: $e');
      rethrow;
    }
  }

  static Stream<List<Order>> getActiveOrders(String userId) {
    return collection
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          OrderStatus.pending.name,
          OrderStatus.confirmed.name,
          OrderStatus.processing.name,
          OrderStatus.shipped.name,
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('🔥 Firestore error in getActiveOrders:\n$error');
        })
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Order.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  List<OrderItem> get mergedItems {
    final Map<String, OrderItem> merged = {};

    for (var item in items) {
      if (merged.containsKey(item.productId)) {
        final existing = merged[item.productId]!;
        merged[item.productId] = OrderItem(
          productId: item.productId,
          name: item.name,
          quantity: existing.quantity + item.quantity,
          price: item.price,
          image: item.image,
        );
      } else {
        merged[item.productId] = item;
      }
    }

    return merged.values.toList();
  }
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String image;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    try {
      return OrderItem(
        productId: data['productId'] as String? ?? '',
        name: data['name'] as String? ?? 'Unknown Item',
        quantity: (data['quantity'] as num?)?.toInt() ?? 1,
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        image: data['imageUrl'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('🔥 Error parsing order item: $e\nData: $data');
      return OrderItem(
        productId: '',
        name: 'Error Item',
        quantity: 1,
        price: 0.0,
        image: '',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': image,
    };
  }
}
