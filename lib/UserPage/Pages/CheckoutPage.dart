import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ecommerce_app/AdminPage/models/Product.dart';
import 'package:flutter_ecommerce_app/UserPage/models/Cart.dart';
import 'package:flutter_ecommerce_app/UserPage/models/Order.dart' as shop_order;
import 'package:flutter_ecommerce_app/UserPage/models/Address.dart';

class CheckoutPage extends StatefulWidget {
  final double total;
  final List<CartItem> cartItems;
  final List<Product> products;

  const CheckoutPage({
    super.key,
    required this.total,
    required this.cartItems,
    required this.products,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedAddress;
  String _selectedPayment = 'Cash on Delivery';

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Address',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Phone is required' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Address is required' : null,
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'City is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saveAddress,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await Address.addAddress(
        userId: userId,
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        city: _cityController.text,
        isDefault: true,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding address: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to checkout')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<Address>>(
        stream: Address.getAddresses(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final addresses = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Address Section
              _buildSectionTitle('Delivery Address'),
              if (addresses.isEmpty)
                Center(
                  child: TextButton.icon(
                    onPressed: _showAddAddressDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Address'),
                  ),
                )
              else
                Column(
                  children: [
                    ...addresses.map((address) => _buildAddressCard(address)),
                    TextButton.icon(
                      onPressed: _showAddAddressDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Another Address'),
                    ),
                  ],
                ),

              const Divider(height: 32),

              // Payment Section
              _buildSectionTitle('Payment Method'),
              _buildPaymentMethod(),

              const SizedBox(height: 32),

              // Order Summary
              _buildSectionTitle('Order Summary'),
              _buildOrderSummary(),

              const SizedBox(height: 16),

              // Place Order Button
              ElevatedButton(
                onPressed: addresses.isEmpty ? null : _processOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Place Order',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedAddress == address.id
              ? Colors.black
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: RadioListTile(
        value: address.id,
        groupValue: _selectedAddress,
        activeColor: Colors.black,
        onChanged: (value) {
          setState(() => _selectedAddress = value.toString());
        },
        title: Text(
          address.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              address.address,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            ),
            Text(
              address.phone,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildPaymentMethod() {
    final paymentMethods = [
      {
        'name': 'Cash on Delivery',
        'icon': Icons.money,
        'description': 'Pay when you receive your order',
      },
      {
        'name': 'Credit/Debit Card',
        'icon': Icons.credit_card,
        'description': 'Pay securely with your card',
      },
      {
        'name': 'Bank Transfer',
        'icon': Icons.account_balance,
        'description': 'Pay via bank transfer',
      },
    ];

    return Column(
      children: [
        ...paymentMethods.map((method) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _selectedPayment == method['name']
                    ? Colors.black
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: RadioListTile(
              value: method['name'],
              groupValue: _selectedPayment,
              activeColor: Colors.black,
              onChanged: (value) {
                setState(() => _selectedPayment = value.toString());
              },
              title: Row(
                children: [
                  Icon(method['icon'] as IconData, color: Colors.black),
                  const SizedBox(width: 12),
                  Text(
                    method['name'] as String,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                method['description'] as String,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              ),
            ),
          ).animate().fadeIn().slideX();
        }),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(
          'Delivery Address',
          _selectedAddress != null
              ? 'Address details here' // TODO: Fetch address details
              : 'No address selected',
          Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          'Payment Method',
          _selectedPayment,
          Icons.payment_outlined,
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          'Total Amount',
          'PKR ${widget.total}',
          Icons.receipt_outlined,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String content, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.black),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY();
  }

  Future<void> _processOrder() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get selected address
      final addressSnapshot = await Address.getUserAddresses(
        userId,
      ).doc(_selectedAddress).get();
      final address = Address.fromMap(
        addressSnapshot.data() as Map<String, dynamic>,
        addressSnapshot.id,
      );

      // Create order items
      final orderItems = widget.cartItems.map((cartItem) {
        final product = widget.products.firstWhere(
          (p) => p.id == cartItem.productId,
        );
        return shop_order.OrderItem(
          productId: product.id,
          name: product.name,
          price: product.finalPrice,
          quantity: cartItem.quantity,
          image: product.images.isNotEmpty ? product.images.first : '',
        );
      }).toList();

      // Create order
      final orderId = await shop_order.Order.createOrder(
        userId: userId,
        items: orderItems,
        subtotal: widget.total - 100,
        deliveryFee: 100,
        shippingAddress: '${address.address}, ${address.city}',
        paymentMethod: _selectedPayment,
        contactNumber: address.phone,
      );

      // Clear cart
      await Future.wait(
        widget.cartItems.map(
          (item) => CartItem.removeFromCart(userId: userId, itemId: item.id),
        ),
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showOrderSuccess(orderId);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating order: $e')));
      }
    }
  }

  void _showOrderSuccess(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Order Placed Successfully!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: $orderId',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context)
                ..pop() // Close dialog
                ..pop() // Close checkout page
                ..pop(); // Close cart page
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }
}
