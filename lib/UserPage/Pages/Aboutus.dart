import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_ecommerce_app/UserPage/NavbarComponents/UserBottomNavbar.dart';
import 'package:flutter_ecommerce_app/UserPage/NavbarComponents/UserDrawer.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/CartPage.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/NotificationsPage.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  // Premium Color Scheme
  final Color primaryColor = Colors.black; // White (main background)
  final Color secondaryColor = const Color(
    0xFFF5F5F5,
  ); // Light grey for cards/sections
  final Color accentColor = const Color(
    0xFF2196F3,
  ); // Simple blue (e.g. for highlights or buttons)
  final Color darkColor =
      Colors.black; // Soft grey for dividers or subtle borders

  final Color backgroundColor = const Color(
    0xFFF5F5F5,
  ); // Light grey background
  final Color textColor = const Color(0xFF212121); // Dark text
  final Color lightTextColor = const Color(0xFF757575); // Light text
  int _currentIndex = 0;
  int _currentCarouselIndex = 0;

  // Move home content to a separate widget
  final List<Widget> _pages = [];
  // Premium Features Data
  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.verified_user_rounded,
      'title': 'Quality Certified',
      'desc': 'All products undergo rigorous quality checks by our experts',
      'color': Colors.blueAccent,
      'gradient': [Colors.blueAccent, Colors.lightBlueAccent],
    },
    {
      'icon': Icons.local_shipping_rounded,
      'title': 'Fast Delivery',
      'desc': 'Same day delivery with our premium logistics network',
      'color': Colors.green,
      'gradient': [Colors.green, Colors.greenAccent],
    },
    {
      'icon': Icons.star_rate_rounded,
      'title': 'Premium Selection',
      'desc': 'Curated selection of the finest groceries worldwide',
      'color': Colors.amber,
      'gradient': [Colors.amber, Colors.amberAccent],
    },
    {
      'icon': Icons.support_agent_rounded,
      'title': '24/7 Support',
      'desc': 'Dedicated customer care team always ready to help',
      'color': Colors.purple,
      'gradient': [Colors.purple, Colors.deepPurpleAccent],
    },
  ];

  // Premium Team Members Data
  final List<Map<String, dynamic>> _teamMembers = [
    {
      'image':
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'name': 'Mohammed Nawab',
      'position': 'Founder & CEO',
      'social': {
        'linkedin': 'https://linkedin.com',
        'twitter': 'https://twitter.com',
      },
      'bio':
          'With over 25 years in the grocery industry, Mohammed has built Nawab Rice into a household name.',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'name': 'Fatima Khan',
      'position': 'Quality Manager',
      'social': {
        'linkedin': 'https://linkedin.com',
        'twitter': 'https://twitter.com',
      },
      'bio':
          'Fatima ensures every product meets our stringent quality standards before reaching your home.',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1551836022-d5d88e9218df?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'name': 'Rajesh Patel',
      'position': 'Operations Head',
      'social': {
        'linkedin': 'https://linkedin.com',
        'twitter': 'https://twitter.com',
      },
      'bio':
          'Rajesh oversees our nationwide supply chain to ensure seamless operations.',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1580489944761-15a19d654956?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'name': 'Priya Sharma',
      'position': 'Customer Experience',
      'social': {
        'linkedin': 'https://linkedin.com',
        'twitter': 'https://twitter.com',
      },
      'bio':
          'Priya leads our customer service team to deliver exceptional shopping experiences.',
    },
  ];

  // Premium Testimonials Data
  final List<Map<String, dynamic>> _testimonials = [
    {
      'image':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'name': 'Ayesha Siddiqui',
      'role': 'Loyal Customer',
      'quote':
          'Nawab Rice has transformed my grocery shopping experience. The quality is unmatched!',
      'rating': 5,
    },
    {
      'image':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'name': 'Rahul Mehta',
      'role': 'Restaurant Owner',
      'quote':
          'As a professional chef, I trust only Nawab Rice for premium ingredients. Consistent quality for years.',
      'rating': 5,
    },
    {
      'image':
          'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'name': 'Neha Kapoor',
      'role': 'Home Chef',
      'quote':
          'Their delivery is lightning fast, and the products always arrive in perfect condition.',
      'rating': 4,
    },
  ];

  // Launch URLs
  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width < 1000;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      drawer: UserDrawer(),
      bottomNavigationBar: UserBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Hero Section
            _buildPremiumHeroSection(size, isMobile),

            // Premium About Section
            _buildPremiumAboutSection(isMobile, isTablet),

            // Premium Stats Section
            // _buildPremiumStatsSection(isMobile),

            // Premium Features Section
            _buildPremiumFeaturesSection(isMobile, isTablet),

            // Premium Team Section
            _buildPremiumTeamSection(isMobile, isTablet),

            // Premium Testimonials Section
            _buildPremiumTestimonialsSection(isMobile, isTablet),

            // Premium Contact Section
            _buildPremiumContactSection(isMobile, isTablet),

            // Premium Footer
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_currentIndex == 0) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: AnimatedTextKit(
          animatedTexts: [
            TyperAnimatedText(
              'Nawab Rice Trader',
              textStyle: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              speed: const Duration(milliseconds: 100),
            ),
          ],
          isRepeatingAnimation: false,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: () {
              setState(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              });
            },
          ),
        ],
      );
    } else {
      return AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'About Us',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      );
    }
  }

  Widget _buildPremiumHeroSection(Size size, bool isMobile) {
    return SizedBox(
      height: isMobile ? size.height * 0.7 : size.height * 0.8,
      child: Stack(
        children: [
          // Premium Background Image with Parallax Effect
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl:
                  'https://images.unsplash.com/photo-1606787366850-de6330128bfc?ixlib=rb-4.0.3&auto=format&fit=crop&w=1600&q=80',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),

          // Premium Gradient Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Premium Content
          Positioned(
            bottom: isMobile ? 60 : 100,
            left: isMobile ? 24 : 80,
            right: isMobile ? 24 : 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nawab Rice Trader',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: isMobile ? 42 : 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),

                const SizedBox(height: 12),

                Text(
                  'Premium Groceries Since 1995',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 18 : 24,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w300,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),

                const SizedBox(height: 30),

                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 28 : 36,
                          vertical: isMobile ? 14 : 18,
                        ),
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                      child: Text(
                        'Explore Products',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 16 : 18,
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),

                    const SizedBox(width: 16),

                    OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 24 : 32,
                              vertical: isMobile ? 14 : 18,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Our Story',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 16 : 18,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.2),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAboutSection(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 24
            : isTablet
            ? 40
            : 120,
        vertical: isMobile ? 60 : 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OUR HERITAGE',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 3,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 20),

          Text(
            'A Legacy of Quality and Trust',
            style: GoogleFonts.playfairDisplay(
              fontSize: isMobile ? 36 : 48,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: Colors.black,
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 30),

          isMobile
              ? Column(
                  children: [
                    _buildPremiumAboutText(isMobile),
                    const SizedBox(height: 30),
                    _buildPremiumAboutImage(isMobile),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildPremiumAboutText(isMobile),
                          const SizedBox(height: 40),
                          _buildPremiumMilestones(),
                        ],
                      ),
                    ),
                    SizedBox(width: isTablet ? 40 : 60),
                    Expanded(child: _buildPremiumAboutImage(isMobile)),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildPremiumAboutText(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Founded in 1995 as a small family-run rice shop in the heart of the city, Nawab Rice Trader has grown into one of the most trusted grocery brands in the region.',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            color: textColor,
            height: 1.8,
          ),
        ).animate().fadeIn(delay: 500.ms),

        const SizedBox(height: 20),

        Text(
          'What began as a humble storefront with just three varieties of rice has blossomed into a premium grocery destination offering over 500 carefully curated products. Our commitment to quality, authenticity, and customer satisfaction has remained unchanged through our journey.',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            color: textColor,
            height: 1.8,
          ),
        ).animate().fadeIn(delay: 600.ms),

        const SizedBox(height: 20),

        Text(
          'Today, we serve thousands of happy customers across the country, delivering the same exceptional quality that earned us our reputation decades ago.',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            color: textColor,
            height: 1.8,
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }

  Widget _buildPremiumAboutImage(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl:
                'https://images.unsplash.com/photo-1550583724-b2692b85b150?ixlib=rb-4.0.3&auto=format&fit=crop&w=1600&q=80',
            height: isMobile ? 300 : 500,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                'Our first store in 1995, where quality became our tradition',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildPremiumMilestones() {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _buildMilestoneItem('1995', 'Founded as a small rice shop'),
        _buildMilestoneItem('2005', 'Expanded to full grocery range'),
        _buildMilestoneItem('2015', 'Launched e-commerce platform'),
        _buildMilestoneItem('2023', 'Serving 10,000+ customers'),
      ],
    );
  }

  Widget _buildMilestoneItem(String year, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                year,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              Text(
                text,
                style: GoogleFonts.poppins(fontSize: 14, color: lightTextColor),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 900.ms);
  }

  // Widget _buildPremiumStatsSection(bool isMobile) {
  //   return Container(
  //     padding: EdgeInsets.symmetric(vertical: isMobile ? 50 : 70),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [darkColor, primaryColor],
  //       ),
  //     ),
  //     child: isMobile
  //         ? Row(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         _buildPremiumStatItem('2023', '   Founded In', isMobile),
  //         const SizedBox(height: 30),
  //         _buildPremiumStatItem('500+', '   Bookings Handled', isMobile),
  //         const SizedBox(height: 30),
  //         _buildPremiumStatItem('100+', '   Satisfied Users', isMobile),
  //       ],
  //     )
  //         : Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //       children: [
  //         _buildPremiumStatItem('2023', 'Founded In', isMobile),
  //         _buildPremiumStatItem('500+', 'Bookings Handled', isMobile),
  //         _buildPremiumStatItem('100+', 'Satisfied Users', isMobile),
  //       ],
  //     ),
  //   ).animate().fadeIn(delay: 400.ms);
  // }

  Widget _buildPremiumStatItem(String value, String label, bool isMobile) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: isMobile ? 48 : 60,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumFeaturesSection(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 24
            : isTablet
            ? 40
            : 120,
        vertical: isMobile ? 60 : 80,
      ),
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'WHY CHOOSE US',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: 3,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              'Our Unmatched Advantages',
              style: GoogleFonts.playfairDisplay(
                fontSize: isMobile ? 30 : 46,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: Colors.black,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: SizedBox(
              width: isMobile ? double.infinity : 600,
              child: Text(
                'We go beyond just selling groceries - we deliver an experience built on trust, quality, and exceptional service.',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 16 : 18,
                  color: lightTextColor,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          SizedBox(height: isMobile ? 40 : 60),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile
                  ? 1
                  : isTablet
                  ? 2
                  : 4,
              childAspectRatio: isMobile ? 1.5 : 1,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              mainAxisExtent: isMobile ? null : 260,
            ),
            itemCount: _features.length,
            itemBuilder: (context, index) {
              final feature = _features[index];
              return _buildPremiumFeatureCard(
                icon: feature['icon'],
                title: feature['title'],
                desc: feature['desc'],
                gradient: feature['gradient'],
              ).animate().fadeIn(delay: (150 * index).ms);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Gradient Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 30, color: Colors.white),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    desc,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.6,
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

  Widget _buildPremiumTeamSection(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 24
            : isTablet
            ? 40
            : 120,
        vertical: isMobile ? 60 : 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'OUR TEAM',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: 3,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              'Meet The Experts Behind Our Success',
              style: GoogleFonts.playfairDisplay(
                fontSize: isMobile ? 32 : 48,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: Colors.black,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: SizedBox(
              width: isMobile ? double.infinity : 600,
              child: Text(
                'Our team of dedicated professionals combines decades of experience with a passion for quality to serve you better.',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 16 : 18,
                  color: lightTextColor,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          SizedBox(height: isMobile ? 40 : 60),

          isMobile
              ? Column(
                  children: _teamMembers
                      .map(
                        (member) => Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: _buildPremiumTeamMemberCard(
                            image: member['image'],
                            name: member['name'],
                            position: member['position'],
                            bio: member['bio'],
                            isMobile: isMobile,
                          ),
                        ),
                      )
                      .toList(),
                )
              : SizedBox(
                  height: isTablet ? 450 : 500,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _teamMembers.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(width: isTablet ? 20 : 30),
                    itemBuilder: (context, index) {
                      final member = _teamMembers[index];
                      return _buildPremiumTeamMemberCard(
                        image: member['image'],
                        name: member['name'],
                        position: member['position'],
                        bio: member['bio'],
                        isMobile: isMobile,
                      ).animate().fadeIn(delay: (200 * index).ms);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPremiumTeamMemberCard({
    required String image,
    required String name,
    required String position,
    required String bio,
    required bool isMobile,
  }) {
    return SizedBox(
      width: isMobile ? double.infinity : 320,
      child: Column(
        children: [
          // Profile Image
          Container(
            height: isMobile ? 350 : 280,
            width: isMobile ? double.infinity : 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: image,
                    height: double.infinity,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),

                  // Gradient Overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Position Tag
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        position,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Name
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: darkColor,
            ),
          ),

          const SizedBox(height: 8),

          // Bio
          Text(
            bio,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: lightTextColor,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Social Links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTeamSocialIcon(FontAwesomeIcons.linkedinIn),
              const SizedBox(width: 15),
              _buildTeamSocialIcon(FontAwesomeIcons.twitter),
              const SizedBox(width: 15),
              _buildTeamSocialIcon(FontAwesomeIcons.instagram),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSocialIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: FaIcon(icon, size: 16, color: primaryColor)),
    );
  }

  Widget _buildPremiumTestimonialsSection(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 60 : 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkColor, primaryColor],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile
                  ? 24
                  : isTablet
                  ? 40
                  : 120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'TESTIMONIALS',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: Text(
                    'What Our Customers Say',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: isMobile ? 32 : 48,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: SizedBox(
                    width: isMobile ? double.infinity : 600,
                    child: Text(
                      'Don\'t just take our word for it - hear from our valued customers about their experiences with Nawab Rice Trader.',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 16 : 18,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isMobile ? 40 : 60),

          SizedBox(
            height: isMobile ? 400 : 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? 24
                    : isTablet
                    ? 40
                    : 120,
              ),
              itemCount: _testimonials.length,
              itemBuilder: (context, index) {
                final testimonial = _testimonials[index];
                return Padding(
                  padding: EdgeInsets.only(right: isMobile ? 20 : 30),
                  child: _buildPremiumTestimonialCard(
                    image: testimonial['image'],
                    name: testimonial['name'],
                    role: testimonial['role'],
                    quote: testimonial['quote'],
                    rating: testimonial['rating'],
                    isMobile: isMobile,
                  ).animate().fadeIn(delay: (200 * index).ms),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTestimonialCard({
    required String image,
    required String name,
    required String role,
    required String quote,
    required int rating,
    required bool isMobile,
  }) {
    return Container(
      width: isMobile ? 280 : 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Stars
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Testimonial Text
            Text(
              quote,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textColor,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 30),

            // Customer Info
            Row(
              children: [
                // Customer Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                // Customer Name and Role
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      role,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: lightTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumContactSection(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 24
            : isTablet
            ? 40
            : 120,
        vertical: isMobile ? 60 : 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'GET IN TOUCH',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 3,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              'We\'d Love to Hear From You',
              style: GoogleFonts.playfairDisplay(
                fontSize: isMobile ? 32 : 48,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: darkColor,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: SizedBox(
              width: isMobile ? double.infinity : 600,
              child: Text(
                'Have questions about our products or services? Our team is always ready to assist you.',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 16 : 18,
                  color: lightTextColor,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          SizedBox(height: isMobile ? 40 : 60),

          isMobile
              ? Column(
                  children: [
                    _buildPremiumContactForm(isMobile),
                    const SizedBox(height: 40),
                    _buildPremiumContactInfo(isMobile),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPremiumContactForm(isMobile)),
                    SizedBox(width: isTablet ? 40 : 60),
                    Expanded(child: _buildPremiumContactInfo(isMobile)),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildPremiumContactForm(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Send Us a Message',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: darkColor,
            ),
          ),

          const SizedBox(height: 30),

          TextField(
            decoration: InputDecoration(
              labelText: 'Your Name',
              labelStyle: GoogleFonts.poppins(color: lightTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: GoogleFonts.poppins(color: lightTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Your Message',
              labelStyle: GoogleFonts.poppins(color: lightTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 5,
              ),
              child: Text(
                'Send Message',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumContactInfo(bool isMobile) {
    return Column(
      children: [
        _buildPremiumContactItem(
          icon: Icons.location_on_rounded,
          title: 'Our Location',
          subtitle: 'R-40 Sector-2,  \Near MD Mart, Baba More,North Karachi',
          onTap: () => _launchUrl(
            'https://www.google.com/maps/search/?api=1&query=Nawab+Rice+Trader',
          ),
        ),

        const SizedBox(height: 20),

        _buildPremiumContactItem(
          icon: Icons.phone_rounded,
          title: 'Phone Number',
          subtitle: '0312 2493 657\n0315 8719 506 (Support)',
          onTap: () => _launchUrl('tel:03122493657'),
        ),

        const SizedBox(height: 20),

        _buildPremiumContactItem(
          icon: Icons.email_rounded,
          title: 'Email Address',
          subtitle: 'contact@nawabricetrader.com\nsupport@nawabricetrader.com',
          onTap: () => _launchUrl('mailto:contact@nawabricetrader.com'),
        ),

        const SizedBox(height: 30),

        Text(
          'Business Hours',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkColor,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Monday - Thursday & Saturday: 11:00 AM - 11:00 PM\Friday: 11:00 AM - 2:00 PM\nSunday: Closed',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: lightTextColor,
            height: 1.8,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildContactSocialIcon(FontAwesomeIcons.facebookF),
            const SizedBox(width: 15),
            _buildContactSocialIcon(FontAwesomeIcons.instagram),
            const SizedBox(width: 15),
            _buildContactSocialIcon(FontAwesomeIcons.twitter),
            const SizedBox(width: 15),
            _buildContactSocialIcon(FontAwesomeIcons.whatsapp),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: primaryColor),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: lightTextColor,
                      height: 1.5,
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

  Widget _buildContactSocialIcon(IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(child: FaIcon(icon, size: 20, color: primaryColor)),
      ),
    );
  }

  Widget _buildPremiumFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkColor, primaryColor],
        ),
      ),
      child: Column(
        children: [
          // Logo and Tagline
          Column(
            children: [
              // Logo
              Container(
                height: 70,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Nawab Rice',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tagline
              Text(
                'Premium Groceries Delivered to Your Doorstep',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Quick Links
          Wrap(
            spacing: 30,
            runSpacing: 15,
            children: [
              _buildFooterLink('Home'),
              _buildFooterLink('About Us'),
              _buildFooterLink('Products'),
              _buildFooterLink('Quality'),
              _buildFooterLink('Delivery'),
              _buildFooterLink('Contact'),
            ],
          ),

          const SizedBox(height: 40),

          // Social Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFooterSocialIcon(FontAwesomeIcons.facebookF),
              const SizedBox(width: 20),
              _buildFooterSocialIcon(FontAwesomeIcons.instagram),
              const SizedBox(width: 20),
              _buildFooterSocialIcon(FontAwesomeIcons.twitter),
              const SizedBox(width: 20),
              _buildFooterSocialIcon(FontAwesomeIcons.youtube),
              const SizedBox(width: 20),
              _buildFooterSocialIcon(FontAwesomeIcons.whatsapp),
            ],
          ),

          const SizedBox(height: 40),

          // Copyright
          Text(
            '© 2023 Nawab Rice Trader. All Rights Reserved.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 10),

          // Legal Links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Privacy Policy',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),

              Container(
                width: 1,
                height: 12,
                color: Colors.white.withOpacity(0.4),
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),

              TextButton(
                onPressed: () {},
                child: Text(
                  'Terms of Service',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),

              Container(
                width: 1,
                height: 12,
                color: Colors.white.withOpacity(0.4),
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),

              TextButton(
                onPressed: () {},
                child: Text(
                  'Shipping Policy',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFooterSocialIcon(IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Center(child: FaIcon(icon, size: 18, color: Colors.white)),
      ),
    );
  }
}
