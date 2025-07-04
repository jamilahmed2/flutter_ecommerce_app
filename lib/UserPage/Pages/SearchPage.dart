import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/ProductsPage.dart';
import 'package:flutter_ecommerce_app/AdminPage/models/Category.dart';
import 'package:flutter_ecommerce_app/AdminPage/models/Product.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> _recentSearches = [];
  bool _isLoading = true;
  List<Category> _popularCategories = [];
  List<Product> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadPopularCategories();
  }

  Future<void> _loadRecentSearches() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final searches = List<String>.from(data['recentSearches'] ?? []);
        setState(() {
          _recentSearches = searches;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPopularCategories() async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('productCount', descending: true)
          .limit(8)
          .get();

      final categories = snapshot.docs.map((doc) {
        return Category.fromFirestore(doc);
      }).toList();

      setState(() => _popularCategories = categories);
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _saveSearch(String query) async {
    if (query.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      // Add to beginning and remove duplicates
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      // Limit to 10 recent searches
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.sublist(0, 10);
      }
    });

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'recentSearches': _recentSearches,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving search: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    _saveSearch(query);

    try {
      final results = await Product.search(query).first;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      debugPrint('Error searching products: $e');
    }
  }

  void _navigateToProductsWithQuery(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsPage(initialQuery: query),
      ),
    );
  }

  void _clearRecentSearches() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _recentSearches = []);

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'recentSearches': [],
      });
    } catch (e) {
      debugPrint('Error clearing searches: $e');
    }
  }

  void _removeRecentSearch(String search) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _recentSearches.remove(search));

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'recentSearches': _recentSearches,
      });
    } catch (e) {
      debugPrint('Error removing search: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          style: GoogleFonts.poppins(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: GoogleFonts.poppins(color: Colors.black54),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () => _performSearch(_searchController.text.trim()),
            ),
          ),
          onSubmitted: (value) => _performSearch(value.trim()),
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {
                _isSearching = false;
                _searchResults = [];
              });
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSearching
          ? _buildSearchLoader()
          : _searchResults.isNotEmpty
          ? _buildSearchResults()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_recentSearches.isNotEmpty) _buildRecentSearches(),
                _buildPopularCategories(),
              ],
            ),
    );
  }

  Widget _buildSearchLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Searching...',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return _buildProductItem(product, index);
      },
    );
  }

  Widget _buildProductItem(Product product, int index) {
    final imageUrl = product.images.isNotEmpty ? product.images[0] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(width: 60, height: 60, color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image),
              ),
        title: Text(
          product.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          'PKR ${product.finalPrice.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductsPage(productId: product.id),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: (50 * index).ms);
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: _clearRecentSearches,
                child: Text(
                  'Clear All',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches
                .map(
                  (search) => InputChip(
                    label: Text(
                      search,
                      style: GoogleFonts.poppins(color: Colors.black87),
                    ),
                    onPressed: () {
                      _searchController.text = search;
                      _navigateToProductsWithQuery(search);
                    },
                    onDeleted: () => _removeRecentSearch(search),
                    backgroundColor: Colors.white,
                    deleteIconColor: Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.black12),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildPopularCategories() {
    if (_popularCategories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Categories',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: _popularCategories.length,
            itemBuilder: (context, index) {
              return _buildCategoryCard(_popularCategories[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category, int index) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductsPage(categoryId: category.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image display with error handling and default icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: category.imageUrl != null && category.imageUrl!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: category.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: Icon(
                            Icons.category,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.category,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${category.productCount} products',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.2);
  }
}
