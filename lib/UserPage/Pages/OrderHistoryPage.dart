// All necessary imports
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_ecommerce_app/UserPage/NavbarComponents/UserDrawer.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view order history')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Order History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: UserDrawer(),
      body: StreamBuilder<List<Order>>(
        stream: Order.getOrderHistory(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('🔥 StreamBuilder Error: ${snapshot.error}');
            return Center(child: Text('Error loading orders'));
          }

          final orders = snapshot.data ?? [];

          return orders.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(orders[index], index);
                  },
                );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Orders Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start shopping to create your order history',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Browse Products',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildOrderHeader(order),
          const Divider(),
          ...order.items.map((item) => _buildOrderItem(item)).toList(),
          const Divider(),
          _buildOrderFooter(order),
        ],
      ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.2),
    );
  }

  Widget _buildOrderHeader(Order order) {
    final statusColor = _getStatusColor(order.status);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order ${order.orderId}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.date.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status.name.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: ${item.quantity}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.price.toString(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderFooter(Order order) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                order.amount.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Order model
class Order {
  final String orderId;
  final DateTime date;
  final OrderStatus status;
  final double amount;
  final List<OrderItem> items;

  Order({
    required this.orderId,
    required this.date,
    required this.status,
    required this.amount,
    required this.items,
  });

  factory Order.fromMap(Map<String, dynamic> data, String id) {
    try {
      final items = ((data['items'] as List?) ?? [])
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList();

      return Order(
        orderId: id,
        date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: OrderStatus.values.firstWhere(
          (e) =>
              e.name.toLowerCase() ==
              (data['status'] as String?)?.toLowerCase(),
          orElse: () => OrderStatus.delivered,
        ),
        amount: (data['total'] as num?)?.toDouble() ?? 0.0,
        items: items,
      );
    } catch (e) {
      debugPrint('🔥 Error parsing order data: $e\nData: $data');
      return Order(
        orderId: id,
        date: DateTime.now(),
        status: OrderStatus.delivered,
        amount: 0.0,
        items: [],
      );
    }
  }

  static CollectionReference<Order> get collection => FirebaseFirestore.instance
      .collection('orders')
      .withConverter<Order>(
        fromFirestore: (snapshot, _) =>
            Order.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (order, _) => {
          'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
          'createdAt': Timestamp.fromDate(order.date),
          'status': order.status.name.toLowerCase(),
          'total': order.amount,
          'items': order.items.map((item) => item.toMap()).toList(),
        },
      );

  static Stream<List<Order>> getOrderHistory(String userId) {
    return collection
        .where('userId', isEqualTo: userId)
        .where(
          'status',
          whereIn: [
            OrderStatus.delivered.name.toLowerCase(),
            OrderStatus.cancelled.name.toLowerCase(),
          ],
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('🔥 Firestore Stream Error in getOrderHistory:\n$error');
        })
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}

// Order item model
class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final String image;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    try {
      return OrderItem(
        name: data['name'] as String? ?? 'Unknown Item',
        quantity: (data['quantity'] as num?)?.toInt() ?? 1,
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        image: data['imageUrl'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('🔥 Error parsing order item: $e\nData: $data');
      return OrderItem(name: 'Error Item', quantity: 1, price: 0.0, image: '');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': image,
    };
  }
}

// Add more statuses as needed
enum OrderStatus { delivered, cancelled }
