import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/Product.dart';
import '../../UserPage/models/Order.dart' as user_order;
import 'package:flutter_ecommerce_app/services/notification_service.dart';

class OrderManagement extends StatefulWidget {
  const OrderManagement({super.key});

  @override
  State<OrderManagement> createState() => _OrderManagementState();
}

class _OrderManagementState extends State<OrderManagement> {
  String _statusFilter = 'All';
  String _sortBy = 'createdAt';
  bool _sortDescending = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Order Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<user_order.Order>>(
              stream: _getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) =>
                      _buildOrderCard(orders[index], index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search orders...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items:
                      [
                        'All',
                        ...user_order.OrderStatus.values.map((s) => s.name),
                      ].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() => _statusFilter = value!);
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _sortBy,
                items: ['createdAt', 'total', 'status'].map((field) {
                  return DropdownMenuItem(value: field, child: Text(field));
                }).toList(),
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                },
              ),
              IconButton(
                icon: Icon(
                  _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                ),
                onPressed: () {
                  setState(() => _sortDescending = !_sortDescending);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(user_order.Order order, int index) {
    return Card(
      color: Colors.grey[100],
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order #${order.id.substring(0, 8)}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            _buildStatusChip(order.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM d, yyyy h:mm a').format(order.createdAt),
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            Text(
              'Total: PKR ${order.total.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.mergedItems.map((item) => _buildOrderItem(item)),
                const Divider(),
                _buildOrderDetails(order),
                const SizedBox(height: 16),
                _buildStatusUpdateButtons(order),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX();
  }

  Widget _buildStatusChip(user_order.OrderStatus status) {
    Color color;
    switch (status) {
      case user_order.OrderStatus.pending:
        color = Colors.orange;
        break;
      case user_order.OrderStatus.confirmed:
        color = Colors.blue;
        break;
      case user_order.OrderStatus.processing:
        color = Colors.purple;
        break;
      case user_order.OrderStatus.shipped:
        color = Colors.indigo;
        break;
      case user_order.OrderStatus.delivered:
        color = Colors.green;
        break;
      case user_order.OrderStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOrderItem(user_order.OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.inventory_2, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${item.quantity}x @ PKR ${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'PKR ${(item.price * item.quantity).toStringAsFixed(2)}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Stream<List<user_order.Order>> _getOrdersStream() {
    Query query = FirebaseFirestore.instance.collection('orders');

    if (_statusFilter != 'All') {
      query = query.where('status', isEqualTo: _statusFilter);
    }

    if (_searchQuery.isNotEmpty) {
      // Update search to match user_order model
      query = query
          .where('userId', isGreaterThanOrEqualTo: _searchQuery)
          .where('userId', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
    }

    return query
        .orderBy(_sortBy, descending: _sortDescending)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => user_order.Order.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Widget _buildOrderDetails(user_order.Order order) {
    return Column(
      children: [
        _buildDetailRow(
          'Subtotal:',
          'PKR ${order.subtotal.toStringAsFixed(2)}',
        ),
        _buildDetailRow(
          'Delivery:',
          'PKR ${order.deliveryFee.toStringAsFixed(2)}',
        ),
        _buildDetailRow('Total:', 'PKR ${order.total.toStringAsFixed(2)}'),
        const Divider(),
        _buildDetailRow('Address:', order.shippingAddress),
        _buildDetailRow('Contact:', order.contactNumber),
        _buildDetailRow('Payment:', order.paymentMethod),
        if (order.trackingId != null)
          _buildDetailRow('Tracking ID:', order.trackingId!),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateButtons(user_order.Order order) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: user_order.OrderStatus.values.map((status) {
        if (status == order.status) return const SizedBox.shrink();

        return ElevatedButton(
          onPressed: () => _updateOrderStatus(order, status),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getStatusColor(status),
            foregroundColor: Colors.white,
          ),
          child: Text(
            'Mark as ${status.name}',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(user_order.OrderStatus status) {
    switch (status) {
      case user_order.OrderStatus.pending:
        return Colors.orange;
      case user_order.OrderStatus.confirmed:
        return Colors.blue;
      case user_order.OrderStatus.processing:
        return Colors.purple;
      case user_order.OrderStatus.shipped:
        return Colors.indigo;
      case user_order.OrderStatus.delivered:
        return Colors.green;
      case user_order.OrderStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(
    user_order.Order order,
    user_order.OrderStatus newStatus,
  ) async {
    try {
      await order.updateStatus(newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to ${newStatus.name}')),
        );
      }

      await NotificationService().addUserNotification(
        userId:
            order.userId, // ✅ Make sure this field exists in the Order model
        type: 'order',
        title: 'Order Updated',
        message:
            'Your order #${order.id.substring(0, 8)} is now ${newStatus.name}',
        orderId: order.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
