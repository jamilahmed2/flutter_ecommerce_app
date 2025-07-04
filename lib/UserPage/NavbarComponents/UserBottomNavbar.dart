import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/Auth/LoginPage.dart';
import 'package:flutter_ecommerce_app/AdminPage/Dashboard/AdminDashboard.dart';
import 'package:flutter_ecommerce_app/main.dart';

class UserBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int cartItemCount;
  final int wishlistItemCount;

  const UserBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartItemCount = 0,
    this.wishlistItemCount = 0,
  });

  @override
  State<UserBottomNavBar> createState() => _UserBottomNavBarState();
}

class _UserBottomNavBarState extends State<UserBottomNavBar> {
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

  void _handleNavigation(int index, BuildContext context) {
    // Handle profile/admin navigation (index 4)
    if (index == 4) {
      _handleProfileNavigation(context);
      return;
    }

    // For other navigation items, check if login is required
    if (_requiresAuth(index)) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showLoginDialog(context, _getFeatureName(index));
        return;
      }
    }

    // Proceed with normal navigation
    widget.onTap(index);
  }

  void _handleProfileNavigation(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // User not logged in - show login dialog
      _showLoginDialog(context, 'Profile');
    } else if (!user.emailVerified) {
      // User logged in but email not verified
      _showEmailVerificationDialog(context);
    } else if (_isAdmin) {
      // User is admin - navigate to admin dashboard
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
      );
    } else {
      // Regular user - proceed to profile
      widget.onTap(4);
    }
  }

  bool _requiresAuth(int index) {
    // Define which navigation items require authentication
    switch (index) {
      case 2: // Cart
      case 3: // Wishlist
        return true;
      default:
        return false;
    }
  }

  String _getFeatureName(int index) {
    switch (index) {
      case 2:
        return 'Cart';
      case 3:
        return 'Wishlist';
      default:
        return 'Feature';
    }
  }

  void _showLoginDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.login, size: 24, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              'Login Required',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'Please login to access your $featureName',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Login',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmailVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.email_outlined, size: 24, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              'Email Verification',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please verify your email address to access your profile.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your inbox for a verification email.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Later',
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser
                    ?.sendEmailVerification();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Verification email sent!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.grey[800],
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error sending email: ${e.toString()}',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Resend Email',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartIcon(bool isLoggedIn) {
    return Stack(
      children: [
        const Icon(Icons.shopping_cart_outlined, size: 26),
        if (widget.cartItemCount > 0 || !isLoggedIn)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: !isLoggedIn ? Colors.red : Colors.black,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  !isLoggedIn
                      ? '!'
                      : widget.cartItemCount > 9
                      ? '9+'
                      : widget.cartItemCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWishlistIcon(bool isLoggedIn) {
    return Stack(
      children: [
        const Icon(Icons.favorite_outline, size: 26),
        if (widget.wishlistItemCount > 0 || !isLoggedIn)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: !isLoggedIn ? Colors.red : Colors.black,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  !isLoggedIn
                      ? '!'
                      : widget.wishlistItemCount > 9
                      ? '9+'
                      : widget.wishlistItemCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileIcon(User? user, bool isLoggedIn) {
    if (isLoggedIn && _isAdmin) {
      return const Icon(Icons.dashboard, size: 26);
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: isLoggedIn ? Colors.grey[100] : Colors.transparent,
          backgroundImage: isLoggedIn && user?.photoURL != null
              ? NetworkImage(user!.photoURL!)
              : null,
          child: isLoggedIn && user?.photoURL == null
              ? const Icon(Icons.person_outline, size: 20, color: Colors.black)
              : !isLoggedIn
              ? const Icon(Icons.person_outline, size: 26, color: Colors.grey)
              : null,
        ),
        if (isLoggedIn)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: user?.emailVerified == true
                    ? Colors.green
                    : Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  String _getProfileLabel(bool isLoggedIn) {
    if (isLoggedIn && _isAdmin) return 'Admin';
    return isLoggedIn ? 'Profile' : 'Login';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isLoggedIn = user != null;

        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
            border: const Border(
              top: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: BottomNavigationBar(
              currentIndex: widget.currentIndex,
              onTap: (index) => _handleNavigation(index, context),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.grey[700],
              selectedLabelStyle: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              elevation: 8,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 26),
                  activeIcon: Icon(Icons.home, size: 26),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined, size: 26),
                  activeIcon: Icon(Icons.search, size: 26),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: _buildCartIcon(isLoggedIn),
                  label: 'Cart',
                ),
                BottomNavigationBarItem(
                  icon: _buildWishlistIcon(isLoggedIn),
                  label: 'Wishlist',
                ),
                BottomNavigationBarItem(
                  icon: _buildProfileIcon(user, isLoggedIn),
                  label: _getProfileLabel(isLoggedIn),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
