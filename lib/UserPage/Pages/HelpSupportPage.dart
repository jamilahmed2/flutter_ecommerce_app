import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_ecommerce_app/UserPage/NavbarComponents/UserDrawer.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  Map<String, dynamic>? _contactDetails;

  @override
  void initState() {
    super.initState();
    _fetchContactDetails();
  }

  Future<void> _fetchContactDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('contact_details')
        .get();
    setState(() {
      _contactDetails = doc.data();
    });
  }

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I place an order?',
      'answer':
          'You can place an order by browsing our products, adding items to your cart, and proceeding to checkout. Select your delivery address and payment method to complete the order.',
    },
    {
      'question': 'What are your delivery areas?',
      'answer':
          'We currently deliver to all major areas in the city. Enter your address during checkout to check if delivery is available in your area.',
    },
    {
      'question': 'How can I track my order?',
      'answer':
          'Once your order is confirmed, you\'ll receive a tracking ID. You can use this ID in the "Track Order" section to monitor your delivery status.',
    },
    // Add more FAQs as needed
  ];

  final List<Map<String, dynamic>> _contactOptions = [
    {
      'title': 'Customer Support',
      'icon': Icons.headset_mic,
      'description': 'Available 24/7',
      'action': 'Call Now',
      'value': '+92 300 1234567',
    },
    {
      'title': 'WhatsApp',
      'icon': FontAwesomeIcons.whatsapp,
      'description': 'Chat with us',
      'action': 'Open Chat',
      'value': '+92 300 1234567',
    },
    {
      'title': 'Email Support',
      'icon': Icons.email_outlined,
      'description': 'Get email assistance',
      'action': 'Send Email',
      'value': 'support@nawabricetrader.com',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final details = _contactDetails ?? {};
    final List<Widget> contactTiles = [];

    if ((details['whatsapp'] ?? '').toString().isNotEmpty) {
      contactTiles.add(
        ListTile(
          leading: const Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
          title: const Text('WhatsApp'),
          subtitle: Text(details['whatsapp']),
          onTap: () => _launchWhatsApp(details['whatsapp']),
        ),
      );
    }
    if ((details['instagram'] ?? '').toString().isNotEmpty) {
      contactTiles.add(
        ListTile(
          leading: const Icon(FontAwesomeIcons.instagram, color: Colors.purple),
          title: const Text('Instagram'),
          subtitle: Text(details['instagram']),
          onTap: () => _launchInstagram(details['instagram']),
        ),
      );
    }
    if ((details['facebook'] ?? '').toString().isNotEmpty) {
      contactTiles.add(
        ListTile(
          leading: const Icon(FontAwesomeIcons.facebook, color: Colors.blue),
          title: const Text('Facebook'),
          subtitle: Text(details['facebook']),
          onTap: () => _launchFacebook(details['facebook']),
        ),
      );
    }
    if ((details['email'] ?? '').toString().isNotEmpty) {
      contactTiles.add(
        ListTile(
          leading: const Icon(FontAwesomeIcons.envelope, color: Colors.red),
          title: const Text('Email'),
          subtitle: Text(details['email']),
          onTap: () => _launchEmail(details['email']),
        ),
      );
    }
    if ((details['phone'] ?? '').toString().isNotEmpty) {
      contactTiles.add(
        ListTile(
          leading: const Icon(FontAwesomeIcons.phone, color: Colors.black),
          title: const Text('Phone'),
          subtitle: Text(details['phone']),
          onTap: () => _launchPhone(details['phone']),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      drawer: UserDrawer(),
      body: (contactTiles.isEmpty)
          ? _buildFAQSection()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...contactTiles,
                const SizedBox(height: 24),
                _buildFAQSection(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 8),
          Text(
            'Find answers or contact our support team',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ).animate().fadeIn(duration: 600.ms).slideX(),
        ],
      ),
    );
  }

  Widget _buildContactOptions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _contactOptions.length,
            itemBuilder: (context, index) {
              return _buildContactCard(_contactOptions[index], index);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Or reach us via social media',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('WhatsApp'),
                subtitle: Text(_contactDetails?['whatsapp'] ?? ''),
                onTap: () {
                  if (_contactDetails?['whatsapp'] != null &&
                      _contactDetails!['whatsapp'].toString().isNotEmpty) {
                    _launchWhatsApp(_contactDetails!['whatsapp']);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.facebook, color: Colors.blue),
                title: const Text('Facebook'),
                subtitle: Text(_contactDetails?['facebook'] ?? ''),
                onTap: () {
                  if (_contactDetails?['facebook'] != null &&
                      _contactDetails!['facebook'].toString().isNotEmpty) {
                    _launchFacebook(_contactDetails!['facebook']);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.purple),
                title: const Text('Instagram'),
                subtitle: Text(_contactDetails?['instagram'] ?? ''),
                onTap: () {
                  if (_contactDetails?['instagram'] != null &&
                      _contactDetails!['instagram'].toString().isNotEmpty) {
                    _launchInstagram(_contactDetails!['instagram']);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.red),
                title: const Text('Email'),
                subtitle: Text(_contactDetails?['email'] ?? ''),
                onTap: () {
                  if (_contactDetails?['email'] != null &&
                      _contactDetails!['email'].toString().isNotEmpty) {
                    _launchEmail(_contactDetails!['email']);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.black),
                title: const Text('Phone'),
                subtitle: Text(_contactDetails?['phone'] ?? ''),
                onTap: () {
                  if (_contactDetails?['phone'] != null &&
                      _contactDetails!['phone'].toString().isNotEmpty) {
                    _launchPhone(_contactDetails!['phone']);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> option, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(option['icon'], color: Colors.black, size: 32),
        title: Text(
          option['title'],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          option['description'],
          style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.6)),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // Implement contact actions
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Contact',
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.2);
  }

  Widget _buildFAQSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _faqs.length,
            itemBuilder: (context, index) {
              return _buildFAQCard(_faqs[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(Map<String, dynamic> faq, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          faq['question'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              faq['answer'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.2);
  }

  Future<void> _launchWhatsApp(String number) async {
    final url = Uri.parse(
      'https://wa.me/${number.replaceAll(RegExp(r'[^0-9]'), '')}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchFacebook(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchInstagram(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
