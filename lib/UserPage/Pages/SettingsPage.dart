import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_ecommerce_app/UserPage/Pages/ProfilePage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settingsSections = [
      {
        'title': 'Account',
        'settings': [
          {
            'title': 'Profile Information',
            'icon': Icons.person_outline,
            'onTap': (BuildContext context) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          },
          {
            'title': 'Change Password',
            'icon': Icons.lock_outline,
            'onTap': () {
              // TODO: Implement change password functionality
            },
          },
          {
            'title': 'Delivery Addresses',
            'icon': Icons.location_on_outlined,
            'onTap': () {
              // TODO: Implement delivery addresses functionality
            },
          },
        ],
      },
      {
        'title': 'Preferences',
        'settings': [
          {
            'title': 'Notifications',
            'icon': Icons.notifications_outlined,
            'isSwitch': true,
            'value': _notificationsEnabled,
            'onChanged': (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          },
          {
            'title': 'Dark Mode',
            'icon': Icons.dark_mode_outlined,
            'isSwitch': true,
            'value': _darkMode,
            'onChanged': (bool value) {
              setState(() {
                _darkMode = value;
              });
            },
          },
          {
            'title': 'Language',
            'icon': Icons.language_outlined,
            'value': _selectedLanguage,
            'isDropdown': true,
            'options': ['English', 'Urdu'],
            'onChanged': (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedLanguage = newValue;
                });
              }
            },
          },
        ],
      },
      {
        'title': 'Privacy & Security',
        'settings': [
          {
            'title': 'Privacy Policy',
            'icon': Icons.privacy_tip_outlined,
            'onTap': () {
              // TODO: Implement privacy policy functionality
            },
          },
          {
            'title': 'Terms of Service',
            'icon': Icons.description_outlined,
            'onTap': () {
              // TODO: Implement terms of service functionality
            },
          },
        ],
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: settingsSections.length,
        itemBuilder: (context, sectionIndex) {
          final section = settingsSections[sectionIndex];
          return _buildSection(section, sectionIndex);
        },
      ),
    );
  }

  Widget _buildSection(Map<String, dynamic> section, int sectionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            section['title'],
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ).animate().fadeIn(delay: (100 * sectionIndex).ms),
        ),
        Container(
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: section['settings'].length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final setting = section['settings'][index];
              return _buildSettingTile(
                setting,
                index,
              ).animate().fadeIn(delay: (150 * index).ms).slideX(begin: 0.2);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSettingTile(Map<String, dynamic> setting, int index) {
    return ListTile(
      leading: Icon(setting['icon'] as IconData, color: Colors.black),
      title: Text(
        setting['title'],
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800]),
      ),
      trailing: setting['isSwitch'] == true
          ? Switch(
              value: setting['value'] as bool,
              onChanged: setting['onChanged'] as Function(bool)?,
              activeColor: Colors.black,
            )
          : setting['isDropdown'] == true
          ? DropdownButton<String>(
              value: setting['value'] as String,
              underline: const SizedBox(),
              items: (setting['options'] as List<String>)
                  .map(
                    (String option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    ),
                  )
                  .toList(),
              onChanged: setting['onChanged'] as Function(String?)?,
            )
          : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: setting['onTap'] != null ? () => setting['onTap']() : null,
    );
  }
}
