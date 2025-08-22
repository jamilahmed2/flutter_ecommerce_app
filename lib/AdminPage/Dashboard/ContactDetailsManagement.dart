import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_ecommerce_app/UserPage/models/Contact.dart';

class ContactDetailsManagement extends StatefulWidget {
  const ContactDetailsManagement({super.key});
  @override
  State<ContactDetailsManagement> createState() =>
      _ContactDetailsManagementState();
}

class _ContactDetailsManagementState extends State<ContactDetailsManagement> {
  final _formKey = GlobalKey<FormState>();
  final _whatsappController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  TimeOfDay? _businessFrom;
  TimeOfDay? _businessTo;

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
    final data = doc.data();
    if (data != null) {
      _whatsappController.text = data['whatsapp'] ?? '';
      _instagramController.text = data['instagram'] ?? '';
      _facebookController.text = data['facebook'] ?? '';
      _emailController.text = data['email'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _addressController.text = data['address'] ?? '';
      final businessHours = data['businessHours'] ?? '';
      if (businessHours.contains('-')) {
        final parts = businessHours.split('-');
        _businessFrom = _parseTimeOfDay(parts[0].trim());
        _businessTo = _parseTimeOfDay(parts[1].trim());
      }
      setState(() {});
    }
  }

  TimeOfDay? _parseTimeOfDay(String time) {
    try {
      final format = RegExp(
        r'(\d{1,2}):(\d{2})\s*([AP]M)',
        caseSensitive: false,
      );
      final match = format.firstMatch(time.trim());
      if (match == null) return null;
      int hour = int.parse(match.group(1)!);
      final int minute = int.parse(match.group(2)!);
      final String period = match.group(3)!.toUpperCase();

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveContactDetails() async {
    setState(() => _isLoading = true);

    final docRef = FirebaseFirestore.instance
        .collection('settings')
        .doc('contact_details');
    final doc = await docRef.get();
    final uuid = const Uuid();

    final businessHoursString = (_businessFrom != null && _businessTo != null)
        ? '${_businessFrom!.format(context)} - ${_businessTo!.format(context)}'
        : '';

    await docRef.set({
      'uuid': doc.exists ? (doc.data()?['uuid'] ?? uuid.v4()) : uuid.v4(),
      'whatsapp': _whatsappController.text.trim(),
      'instagram': _instagramController.text.trim(),
      'facebook': _facebookController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'businessHours': businessHoursString,
    });

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Contact details updated!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Contact Details Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.edit, color: Colors.white),
        tooltip: 'Edit Contact Details',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: _buildContactForm(),
            ),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('settings')
              .doc('contact_details')
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }
            final data = snapshot.data?.data() as Map<String, dynamic>?;

            if (data == null || data.isEmpty) {
              return Center(
                child: Text(
                  'No contact details set yet.\nTap the edit button to add.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              );
            }

            return Card(
              color: Colors.grey[100],
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Contact Details',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    const Divider(height: 32, thickness: 1),
                    _buildContactDetailRow(
                      FontAwesomeIcons.whatsapp,
                      'WhatsApp',
                      data['whatsapp'],
                    ),
                    _buildContactDetailRow(
                      FontAwesomeIcons.instagram,
                      'Instagram',
                      data['instagram'],
                    ),
                    _buildContactDetailRow(
                      FontAwesomeIcons.facebook,
                      'Facebook',
                      data['facebook'],
                    ),
                    _buildContactDetailRow(
                      FontAwesomeIcons.envelope,
                      'Email',
                      data['email'],
                    ),
                    _buildContactDetailRow(
                      FontAwesomeIcons.phone,
                      'Phone',
                      data['phone'],
                    ),
                    _buildContactDetailRow(
                      Icons.location_on,
                      'Address',
                      data['address'],
                    ),
                    _buildContactDetailRow(
                      Icons.access_time,
                      'Business Hours',
                      data['businessHours'],
                    ),
                    Expanded(child: _buildContactMessagesSection()),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContactMessagesSection() {
    return FutureBuilder<List<ContactModel>>(
      future: ContactService().getAllContacts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final contacts = snapshot.data ?? [];
        if (contacts.isEmpty) {
          return Center(
            child: Text(
              'No contact messages yet.',
              style: GoogleFonts.poppins(color: Colors.black54),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contacts.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final c = contacts[i];
            return ListTile(
              leading: const Icon(Icons.email, color: Colors.black),
              title: Text(
                '${c.name} (${c.email})',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.phone != null && c.phone!.isNotEmpty)
                    Text(
                      'Phone: ${c.phone}',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  Text(
                    'Subject: ${c.subject}',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  Text(
                    'Message: ${c.message}',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  Text(
                    'Date: ${c.createdAt}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Message'),
                      content: const Text(
                        'Are you sure you want to delete this message?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ContactService().deleteContact(c.id!);
                    setState(() {}); // Refresh list
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContactDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              (value == null || value.isEmpty) ? '-' : value,
              style: GoogleFonts.poppins(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Text(
                'Edit Contact Details',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildContactField(
              FontAwesomeIcons.whatsapp,
              'WhatsApp Number',
              _whatsappController,
            ),
            const SizedBox(height: 12),
            _buildContactField(
              FontAwesomeIcons.instagram,
              'Instagram Link',
              _instagramController,
            ),
            const SizedBox(height: 12),
            _buildContactField(
              FontAwesomeIcons.facebook,
              'Facebook Link',
              _facebookController,
            ),
            const SizedBox(height: 12),
            _buildContactField(
              FontAwesomeIcons.envelope,
              'Support Email',
              _emailController,
            ),
            const SizedBox(height: 12),
            _buildContactField(
              FontAwesomeIcons.phone,
              'Support Phone',
              _phoneController,
            ),
            const SizedBox(height: 12),
            _buildContactField(
              FontAwesomeIcons.mapMarkerAlt,
              'Address',
              _addressController,
            ),
            const SizedBox(height: 12),
            Text(
              'Business Hours',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime:
                            _businessFrom ?? TimeOfDay(hour: 9, minute: 0),
                      );
                      if (picked != null)
                        setState(() => _businessFrom = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _businessFrom != null
                            ? _businessFrom!.format(context)
                            : 'From',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime:
                            _businessTo ?? TimeOfDay(hour: 18, minute: 0),
                      );
                      if (picked != null) setState(() => _businessTo = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _businessTo != null
                            ? _businessTo!.format(context)
                            : 'To',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      await _saveContactDetails();
                      setState(() => _isLoading = false);
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildContactField(
    IconData icon,
    String label,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black54),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      // No validator: all fields optional
    );
  }
}
