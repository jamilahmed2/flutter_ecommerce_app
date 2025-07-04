import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/Aboutus.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/Auth/LoginPage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/Auth/RegisterPage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/Brand.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/CategoriesPage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/HelpSupportPage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/HomePage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/OffersPage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/OrderHistoryPage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/OrdersPage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/ProductsPage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/SettingsPage.dart';
import 'package:flutter_ecommerce_app/AdminPage/Dashboard/AdminDashboard.dart';

import 'package:flutter_ecommerce_app/main.dart';

class UserDrawer extends StatefulWidget {
  const UserDrawer({super.key});

  @override
  State<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> {
  bool _isAdmin = false;
  bool _adminCheckComplete = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isAdmin = await AuthService.isAdmin(user.uid);
      setState(() {
        _isAdmin = isAdmin;
        _adminCheckComplete = true;
      });
    } else {
      setState(() {
        _adminCheckComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(user, isLoggedIn),

          // Navigation section
          _buildSectionTitle('NAVIGATION'),

          _buildDrawerItem(
            icon: Icons.home,
            title: 'Home',
            onTap: () => _navigateAndClose(context, const HomePage()),
          ),

          // Admin dashboard for admin users
          if (_adminCheckComplete && _isAdmin)
            _buildDrawerItem(
              icon: Icons.dashboard,
              title: 'Admin Dashboard',
              onTap: () => _navigate(context, const AdminDashboard()),
            ),

          _buildDrawerItem(
            icon: Icons.shopping_cart,
            title: 'Products',
            onTap: () => _navigate(context, const ProductsPage()),
          ),
          _buildDrawerItem(
            icon: Icons.category,
            title: 'Categories',
            onTap: () => _navigate(context, const CategoriesPage()),
          ),
          _buildDrawerItem(
            icon: Icons.branding_watermark,
            title: 'Brands',
            onTap: () => _navigate(context, const BrandPage()),
          ),
          _buildDrawerItem(
            icon: Icons.local_offer,
            title: 'Offers',
            onTap: () => _navigate(context, const OffersPage()),
          ),
          _buildDrawerItem(
            icon: Icons.info,
            title: 'About Us',
            onTap: () => _navigate(context, const AboutUsPage()),
          ),

          // Orders section
          if (isLoggedIn) ...[
            _buildSectionTitle('ORDERS'),
            _buildDrawerItem(
              icon: Icons.shopping_bag_outlined,
              title: 'My Orders',
              onTap: () => _navigate(context, const OrdersPage()),
            ),
            _buildDrawerItem(
              icon: Icons.history,
              title: 'Order History',
              onTap: () => _navigate(context, const OrderHistoryPage()),
            ),
          ],

          // Account section
          _buildSectionTitle('ACCOUNT'),
          _buildDrawerItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => _navigate(context, const HelpSupportPage()),
          ),

          if (isLoggedIn)
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () => _navigate(context, const SettingsPage()),
            ),

          // Authentication section
          _buildSectionTitle(isLoggedIn ? 'ACTIONS' : 'AUTHENTICATION'),
          if (isLoggedIn)
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () => _handleLogout(context),
            )
          else ...[
            _buildDrawerItem(
              icon: Icons.login,
              title: 'Login',
              onTap: () => _navigate(context, const LoginPage()),
            ),
            _buildDrawerItem(
              icon: Icons.person_add,
              title: 'Register',
              onTap: () => _navigate(context, const RegisterPage()),
            ),
          ],

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Nawab Rice Trader v1.0',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(User? user, bool isLoggedIn) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Icon(Icons.person, size: 40, color: Colors.grey[700])
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLoggedIn
                          ? '${user?.displayName ?? user?.email?.split('@')[0] ?? 'User'}'
                          : 'Welcome Guest',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoggedIn
                          ? user?.email ?? 'Premium Member'
                          : 'Sign in for full access',
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.grey[700],
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.grey[800], size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minLeadingWidth: 0,
        horizontalTitleGap: 8,
        dense: true,
        onTap: onTap,
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _navigateAndClose(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => page),
      (route) => false,
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error logging out: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
