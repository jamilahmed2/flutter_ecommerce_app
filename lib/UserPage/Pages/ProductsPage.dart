import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_ecommerce_app/UserPage/NavbarComponents/UserDrawer.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/CartPage.dart';
import 'package:flutter_ecommerce_app/UserPage/models/Cart.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_ecommerce_app/AdminPage/models/Product.dart';

class ProductsPage extends StatefulWidget {
  final String? categoryId;
  final String? brandId;
  final String? productId;
  final ProductFilter? filter;
  final String? initialQuery;

  const ProductsPage({
    super.key,
    this.categoryId,
    this.brandId,
    this.productId,
    this.filter,
    this.initialQuery,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

enum ProductFilter { deals, featured, all }

class _ProductsPageState extends State<ProductsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedQuantity = 1;
  double _maxProductPrice = 10000;
  // Color theme
  final Color primaryColor = Colors.black;
  final Color backgroundColor = Colors.white;
  final Color textColor = Colors.black;
  final Color lightTextColor = Colors.grey;

  // State variables
  String _selectedCategoryId = '';
  String _sortBy = 'popular';
  bool _showFilters = false;
  double _priceRangeMin = 0;
  double _priceRangeMax = 1000;
  double _ratingFilter = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId ?? '';

    // Set initial search query if provided
    if (widget.initialQuery != null) {
      _searchQuery = widget.initialQuery!;
    }

    _initializePriceRange();
  }

  Future<void> _initializePriceRange() async {
    try {
      final productsQuery = _firestore
          .collection('products')
          .where('isActive', isEqualTo: true);
      final products = await productsQuery.get();

      if (products.docs.isNotEmpty) {
        double maxPrice = 0;
        for (var doc in products.docs) {
          final price = (doc.data()['price'] ?? 0).toDouble();
          if (price > maxPrice) maxPrice = price;
        }
        setState(() {
          _priceRangeMax = maxPrice;
          _maxProductPrice = maxPrice; // Store actual max price
        });
      }
    } catch (e) {
      debugPrint('Error initializing price range: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(isSmallScreen),
      drawer: const UserDrawer(),
      body: Column(
        children: [
          _buildCategoryList(),
          _buildSortingSection(),
          if (_showFilters) _buildFilterSection(),
          Expanded(
            child: _buildProductsGrid(screenWidth), // Pass screenWidth here
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isSmallScreen) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Our Products',
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 20 : 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: _showSearchDialog,
        ),
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.black),
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
      ],
    );
  }

  Widget _buildCategoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading categories'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = [
          {'id': '', 'name': 'All', 'icon': 'grid'},
          ...snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'name': data['name'],
              'icon': data['icon'] ?? 'category',
            };
          }).toList(),
        ];

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryItem(categories[index], index);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category, int index) {
    final isSelected = _selectedCategoryId == category['id'];
    final imageUrl = category['imageUrl'] ?? '';
    final hasImage = imageUrl.isNotEmpty;
    final iconName = category['icon'] ?? 'category';

    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = category['id']),
      child: Container(
        margin: EdgeInsets.only(left: index == 0 ? 0 : 8, right: 8),
        width: 80,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show image if available, otherwise show icon
            if (hasImage)
              // Category image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(iconName),
                        size: 24,
                        color: isSelected ? Colors.white : primaryColor,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(iconName),
                        size: 24,
                        color: isSelected ? Colors.white : primaryColor,
                      ),
                    ),
                  ),
                ),
              )
            else
              // Show icon only when no image is available
              Icon(
                _getCategoryIcon(iconName),
                color: isSelected ? Colors.white : primaryColor,
                size: 28,
              ),
            const SizedBox(height: 8),
            Text(
              category['name'],
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : primaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ).animate().fadeIn(delay: (50 * index).ms),
    );
  }

  IconData _getCategoryIcon(String icon) {
    switch (icon) {
      case 'grid':
        return Icons.grid_view_rounded;
      case 'rice':
        return Icons.rice_bowl;
      case 'oil':
        return Icons.local_drink;
      case 'spice':
        return Icons.kitchen;
      case 'snack':
        return Icons.fastfood;
      case 'beverage':
        return Icons.emoji_food_beverage;
      case 'flour':
        return Icons.grain;
      case 'pulse':
        return Icons.eco;
      case 'cereal':
        return Icons.breakfast_dining;
      default:
        return Icons.category;
    }
  }

  Widget _buildSortingSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getProductsStream(),
      builder: (context, snapshot) {
        final productsCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$productsCount Products',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: lightTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(
                    value: 'popular',
                    child: Text('Most Popular'),
                  ),
                  DropdownMenuItem(value: 'newest', child: Text('Newest')),
                  DropdownMenuItem(
                    value: 'price_low',
                    child: Text('Price: Low to High'),
                  ),
                  DropdownMenuItem(
                    value: 'price_high',
                    child: Text('Price: High to Low'),
                  ),
                  DropdownMenuItem(value: 'rating', child: Text('Top Rated')),
                ],
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
            ],
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getProductsStream() {
    Query query = _firestore
        .collection('products')
        .where('isActive', isEqualTo: true);

    if (_searchQuery.isNotEmpty) {
      query = query.where(
        'searchKeywords',
        arrayContains: _searchQuery.toLowerCase(),
      );
    }

    if (_selectedCategoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: _selectedCategoryId);
    }

    if (widget.brandId != null) {
      query = query.where('brandId', isEqualTo: widget.brandId);
    }

    return query.snapshots();
  }

  Widget _buildProductsGrid(double screenWidth) {
    final isSmallScreen = screenWidth < 600;
    final crossAxisCount = isSmallScreen
        ? 2
        : screenWidth > 1000
        ? 4
        : 3;
    final childAspectRatio = isSmallScreen ? 0.65 : 0.75;

    return StreamBuilder<QuerySnapshot>(
      stream: _getProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .where((product) {
              final price = (product['price'] ?? 0).toDouble();
              final rating = (product['rating'] ?? 0).toDouble();

              return price >= _priceRangeMin &&
                  price <= _priceRangeMax &&
                  rating >= _ratingFilter;
            })
            .toList();

        // Apply sorting
        _sortProducts(products);

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            mainAxisSpacing: isSmallScreen ? 8 : 16,
            crossAxisSpacing: isSmallScreen ? 8 : 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(
              products[index],
              isSmallScreen,
            ).animate().fadeIn(delay: (50 * index).ms);
          },
        );
      },
    );
  }

  void _sortProducts(List<Map<String, dynamic>> products) {
    switch (_sortBy) {
      case 'popular':
        products.sort(
          (a, b) => (b['reviewCount'] ?? 0).compareTo(a['reviewCount'] ?? 0),
        );
        break;
      case 'newest':
        products.sort(
          (a, b) => (b['createdAt'] as Timestamp).compareTo(
            a['createdAt'] as Timestamp,
          ),
        );
        break;
      case 'price_low':
        products.sort(
          (a, b) => (a['price'] as num).compareTo(b['price'] as num),
        );
        break;
      case 'price_high':
        products.sort(
          (a, b) => (b['price'] as num).compareTo(a['price'] as num),
        );
        break;
      case 'rating':
        products.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
        break;
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product, bool isSmallScreen) {
    // Use first image from images list if available
    final imageUrl = (product['images'] != null && product['images'].isNotEmpty)
        ? product['images'][0]
        : product['imageUrl'] ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showProductDetails(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Container(
                    height: isSmallScreen ? 120 : 150,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                      errorWidget: (context, url, error) =>
                          Center(child: Icon(Icons.error, color: Colors.grey)),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildWishlistIcon(product),
                ),
                if ((product['discountPrice'] ?? 0) < (product['price'] ?? 0))
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(((product['price'] - product['discountPrice']) / product['price']) * 100).toStringAsFixed(0)}% OFF',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unknown Product',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: isSmallScreen ? 14 : 16,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        (product['rating'] ?? 0.0).toString(),
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product['reviewCount'] ?? 0})',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: lightTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'PKR ${product['discountPrice'] ?? product['price']}',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if ((product['discountPrice'] ?? 0) <
                          (product['price'] ?? 0))
                        Text(
                          'PKR ${product['price']}',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 10 : 12,
                            decoration: TextDecoration.lineThrough,
                            color: lightTextColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _addToCart(product),
                      icon: Icon(
                        Icons.shopping_cart,
                        size: isSmallScreen ? 14 : 16,
                      ),
                      label: Text(
                        'Add To Cart',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 6 : 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Map<String, dynamic> product) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to add items to cart'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if product has enough stock
      final stock = product['stock'] as int? ?? 0;
      if (stock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product is out of stock'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Use the Cart model's addToCart method
      await CartItem.addToCart(
        userId: user.uid,
        productId: product['id'],
        quantity: _selectedQuantity,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${product['name']} to cart'),
          backgroundColor: primaryColor,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showProductDetails(Map<String, dynamic> product) {
    _selectedQuantity = 1;
    int _currentImageIndex = 0;
    final images = List<String>.from(product['images'] ?? []);
    if (images.isEmpty && product['imageUrl'] != null) {
      images.add(product['imageUrl']);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      product['name'] ?? 'Unknown Product',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cloudinary Image Carousel
                    if (images.isNotEmpty)
                      Column(
                        children: [
                          CarouselSlider(
                            options: CarouselOptions(
                              height: 250,
                              aspectRatio: 16 / 9,
                              viewportFraction: 1.0,
                              initialPage: 0,
                              enableInfiniteScroll: images.length > 1,
                              reverse: false,
                              autoPlay: images.length > 1,
                              autoPlayInterval: const Duration(seconds: 3),
                              autoPlayAnimationDuration: const Duration(
                                milliseconds: 800,
                              ),
                              autoPlayCurve: Curves.fastOutSlowIn,
                              enlargeCenterPage: true,
                              onPageChanged: (index, reason) {
                                setState(() => _currentImageIndex = index);
                              },
                              scrollDirection: Axis.horizontal,
                            ),
                            items: images.map((imageUrl) {
                              return Builder(
                                builder: (BuildContext context) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[200],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          if (images.length > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: images.asMap().entries.map((entry) {
                                return Container(
                                  width: 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryColor.withOpacity(
                                      _currentImageIndex == entry.key
                                          ? 0.9
                                          : 0.4,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      )
                    else
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    _buildWishlistButtonInDetails(product),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PKR ${product['discountPrice'] ?? product['price']}',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            if ((product['discountPrice'] ?? 0) <
                                (product['price'] ?? 0))
                              Text(
                                'PKR ${product['price']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                  color: lightTextColor,
                                ),
                              ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                if (_selectedQuantity > 1) {
                                  setState(() => _selectedQuantity--);
                                }
                              },
                            ),
                            Text(
                              _selectedQuantity.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                final stock = product['stock'] as int? ?? 0;
                                if (_selectedQuantity < stock) {
                                  setState(() => _selectedQuantity++);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Maximum stock reached'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product['description'] ?? 'No description available',
                      style: GoogleFonts.poppins(
                        color: lightTextColor,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          _addToCartWithQuantity(product, _selectedQuantity);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Add to Cart',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addToCartWithQuantity(
    Map<String, dynamic> product,
    int quantity,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to add items to cart'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final stock = product['stock'] as int? ?? 0;
      if (stock < quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough stock available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await CartItem.addToCart(
        userId: user.uid,
        productId: product['id'],
        quantity: quantity,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${quantity}x ${product['name']} to cart'),
          backgroundColor: primaryColor,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Search',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Price Range Filter
          Text(
            'Price Range',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(_priceRangeMin, _priceRangeMax),
            min: 0,
            max: _maxProductPrice, // Use actual max here
            divisions: 100,
            labels: RangeLabels(
              'PKR ${_priceRangeMin.toStringAsFixed(0)}',
              'PKR ${_priceRangeMax.toStringAsFixed(0)}',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _priceRangeMin = values.start;
                _priceRangeMax = values.end;
              });
            },
            activeColor: primaryColor,
            inactiveColor: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          // Rating Filter
          Text(
            'Minimum Rating',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _ratingFilter,
            min: 0,
            max: 5,
            divisions: 5,
            label: _ratingFilter.toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _ratingFilter = value;
              });
            },
            activeColor: primaryColor,
            inactiveColor: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          // Reset Filters Button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _priceRangeMin = 0;
                  _priceRangeMax = _maxProductPrice; // Reset to actual max
                  _ratingFilter = 0;
                });
              },
              icon: const Icon(Icons.refresh),
              label: Text('Reset Filters', style: GoogleFonts.poppins()),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistIcon(Map<String, dynamic> product) {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(product['id'])
          .snapshots(),
      builder: (context, snapshot) {
        final isInWishlist = snapshot.hasData && snapshot.data!.exists;

        return IconButton(
          icon: Icon(
            isInWishlist ? Icons.favorite : Icons.favorite_border,
            color: isInWishlist ? Colors.red : Colors.white,
          ),
          onPressed: () => _toggleWishlist(product, isInWishlist),
          padding: EdgeInsets.zero,
          iconSize: 24,
        );
      },
    );
  }

  void _toggleWishlist(Map<String, dynamic> product, bool isInWishlist) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add to wishlist'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final productId = product['id'] as String? ?? '';
    if (productId.isEmpty) return;

    try {
      // Pass complete product data to ensure all details are stored
      await Product.toggleWishlist(user.uid, productId, {
        'id': productId,
        ...product, // Spread all product data
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update wishlist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildWishlistButtonInDetails(Map<String, dynamic> product) {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(product['id'])
          .snapshots(),
      builder: (context, snapshot) {
        final isInWishlist = snapshot.hasData && snapshot.data!.exists;

        return IconButton(
          icon: Icon(
            isInWishlist ? Icons.favorite : Icons.favorite_border,
            color: isInWishlist ? Colors.red : Colors.grey,
            size: 32,
          ),
          onPressed: () => _toggleWishlist(product, isInWishlist),
        );
      },
    );
  }
}
