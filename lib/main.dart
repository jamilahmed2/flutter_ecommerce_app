import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:flutter_ecommerce_app/AdminPage/Dashboard/AdminDashboard.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/Auth/LoginPage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/Auth/RegisterPage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/Auth/VerifyEmailPage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/HomePage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/ProductsPage.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configure Firebase settings
  await FirebaseAuth.instance.setLanguageCode('en');
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nawab Rice Trader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: const AuthWrapper(),
      // Named routes for better navigation management
      routes: {
        '/login': (context) => const LoginRouteGuard(),
        '/home': (context) => const HomePage(),
        '/products': (context) => const ProductsPage(),
        '/admin': (context) => const AdminRouteGuard(),
        '/verify': (context) => const VerifyEmailPage(),
        '/register': (context) => const RegisterRouteGuard(),
      },
    );
  }
}

// NEW: Route guard for admin dashboard
class AdminRouteGuard extends StatelessWidget {
  const AdminRouteGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAdminAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const AdminDashboard();
        }

        // Redirect to home if not admin
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/home');
        });
        return const LoadingScreen();
      },
    );
  }

  Future<bool> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return AuthService.isAdmin(user.uid);
  }
}

// NEW: Route guard for login page
class LoginRouteGuard extends StatelessWidget {
  const LoginRouteGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldShowLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const LoginPage();
        }

        // Redirect to home if user is logged in
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/home');
        });
        return const LoadingScreen();
      },
    );
  }

  Future<bool> _shouldShowLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    // Only show login page if user is not logged in
    return user == null;
  }
}

// NEW: Route guard for register page
class RegisterRouteGuard extends StatelessWidget {
  const RegisterRouteGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldShowRegister(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const RegisterPage();
        }

        // Redirect to home if user is logged in
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/home');
        });
        return const LoadingScreen();
      },
    );
  }

  Future<bool> _shouldShowRegister() async {
    final user = FirebaseAuth.instance.currentUser;
    // Only show register page if user is not logged in
    return user == null;
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Cache for admin status to avoid repeated Firestore calls
  final Map<String, bool> _adminCache = {};

  // Keep track of current user to detect user changes
  String? _currentUserId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        final user = snapshot.data;

        // If user changed (including logout), clear cache
        if (_currentUserId != user?.uid) {
          _adminCache.clear();
          _currentUserId = user?.uid;
        }

        // If user is not logged in, show HomePage
        if (user == null) {
          return const HomePage();
        }

        // Check if email is verified first
        if (!user.emailVerified) {
          return const VerifyEmailPage();
        }

        // ALL LOGGED IN USERS GO TO HOMEPAGE
        return const HomePage();
      },
    );
  }

  @override
  void dispose() {
    // Clear cache when widget is disposed
    _adminCache.clear();
    super.dispose();
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading...',
              style: GoogleFonts.poppins(color: Colors.black54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// Optional: Create an AuthService for centralized auth management
class AuthService {
  static final Map<String, bool> _adminCache = {};

  // Clear cache when user logs out
  static void clearCache() {
    _adminCache.clear();
  }

  // Get admin status with caching
  static Future<bool> isAdmin(String userId) async {
    if (_adminCache.containsKey(userId)) {
      return _adminCache[userId]!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .get();

      final isAdmin = doc.exists;
      _adminCache[userId] = isAdmin;
      return isAdmin;
    } catch (e) {
      // On error, assume not admin
      _adminCache[userId] = false;
      return false;
    }
  }

  // Logout with proper cleanup
  static Future<void> logout() async {
    try {
      // Clear Firestore cache
      await FirebaseFirestore.instance.clearPersistence();

      // Clear our admin cache
      clearCache();

      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Even if cache clearing fails, ensure user is signed out
      clearCache();
      await FirebaseAuth.instance.signOut();
      rethrow;
    }
  }
}
