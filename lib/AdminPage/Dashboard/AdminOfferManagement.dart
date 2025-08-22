import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ecommerce_app/services/cloudinary_service.dart';
import 'package:flutter_ecommerce_app/services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AdminOfferManagement extends StatefulWidget {
  const AdminOfferManagement({super.key});
  @override
  State<AdminOfferManagement> createState() => _AdminOfferManagementState();
}

class _AdminOfferManagementState extends State<AdminOfferManagement> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  final _minPurchaseController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime? _validUntil;
  File? _selectedImage;
  String? _editingOfferId;
  String? _editingImageUrl;
  bool _isActive = true;
  bool _isLoading = false;
  bool _showForm = false;

  // Enhanced error logging function
  void _logError(String operation, dynamic error, [StackTrace? stackTrace]) {
    final errorMessage = 'AdminOfferManagement - $operation: $error';

    // Print to terminal/console
    // // print('❌ ERROR: $errorMessage');
    // if (stackTrace != null) {
    //   // print('📍 Stack trace: $stackTrace');
    // }

    // Use developer.log for better debugging
    developer.log(
      errorMessage,
      name: 'AdminOfferManagement',
      error: error,
      stackTrace: stackTrace,
    );

    // In debug mode, also use debugPrint
    // if (kDebugMode) {
    //   debug// print('🔍 DEBUG: $errorMessage');
    // }
  }

  // Enhanced success logging function
  void _logSuccess(String operation, [String? details]) {
    final successMessage =
        'AdminOfferManagement - $operation${details != null ? ': $details' : ''}';
    // print('✅ SUCCESS: $successMessage');

    // if (kDebugMode) {
    //   debugPrint('✅ DEBUG SUCCESS: $successMessage');
    // }
  }

  void _resetForm() {
    try {
      _formKey.currentState?.reset();
      _titleController.clear();
      _descController.clear();
      _codeController.clear();
      _discountController.clear();
      _minPurchaseController.clear();
      _categoryController.clear();
      setState(() {
        _selectedImage = null;
        _editingOfferId = null;
        _editingImageUrl = null;
        _isActive = true;
        _validUntil = DateTime.now();
      });
      _logSuccess('Form reset');
    } catch (e, stackTrace) {
      _logError('Form reset', e, stackTrace);
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      _validUntil = DateTime.now();
      _autoInactivateExpiredOffers();
      _logSuccess('Widget initialized');
    } catch (e, stackTrace) {
      _logError('Widget initialization', e, stackTrace);
    }
  }

  Future<void> _pickImage() async {
    try {
      // print('📸 Starting image picker...');
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() => _selectedImage = File(image.path));
        _logSuccess('Image picked', 'Path: ${image.path}');
      } else {
        // print('ℹ️ No image selected');
      }
    } catch (e, stackTrace) {
      _logError('Image picking', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _pickDate() async {
    try {
      // print('📅 Starting date picker...');
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: _validUntil ?? now,
        firstDate: now,
        lastDate: DateTime(now.year + 5),
      );

      if (picked != null) {
        setState(() => _validUntil = picked);
        _logSuccess(
          'Date picked',
          'Selected: ${DateFormat('yyyy-MM-dd').format(picked)}',
        );
      } else {
        // print('ℹ️ No date selected');
      }
    } catch (e, stackTrace) {
      _logError('Date picking', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick date: $e')));
      }
    }
  }

  Future<void> _saveOffer() async {
    try {
      // print('💾 Starting offer save process...');

      if (!_formKey.currentState!.validate()) {
        // print('⚠️ Form validation failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields.')),
        );
        return;
      }

      setState(() => _isLoading = true);
      // print('🔄 Loading state set to true');

      String? imageUrl = _editingImageUrl;
      if (_selectedImage != null) {
        // print('📤 Uploading image to Cloudinary...');
        try {
          imageUrl = await CloudinaryService.uploadImage(_selectedImage!);
          _logSuccess('Image uploaded', 'URL: $imageUrl');
        } catch (e, stackTrace) {
          _logError('Image upload', e, stackTrace);
          throw Exception('Failed to upload image: $e');
        }
      }

      final uuid = const Uuid();
      final offerData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'code': _codeController.text.trim(),
        'discount': _discountController.text.trim(),
        'minPurchase': _minPurchaseController.text.trim(),
        'category': _categoryController.text.trim(),
        'validUntil': _validUntil != null
            ? Timestamp.fromDate(_validUntil!)
            : null,
        'imageUrl': imageUrl,
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // print('📝 Offer data prepared: ${offerData.keys.toList()}');

      if (_editingOfferId == null) {
        // Create new offer
        // print('➕ Creating new offer...');
        final docRef = await FirebaseFirestore.instance
            .collection('offers')
            .add({
              ...offerData,
              'uuid': uuid.v4(),
              'createdAt': FieldValue.serverTimestamp(),
            });

        _logSuccess('Offer created', 'Document ID: ${docRef.id}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offer added successfully!')),
          );
        }

        if (_editingOfferId == null) {
          await NotificationService().addGlobalNotification(
            type: 'promo',
            title: 'New Offer Available',
            message: '${_titleController.text} - ${_descController.text}',
            offerId: docRef.id,
          );
        }
      } else {
        // Update existing offer
        // print('✏️ Updating existing offer: $_editingOfferId');
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(_editingOfferId)
            .update(offerData);
        _logSuccess('Offer updated', 'Document ID: $_editingOfferId');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offer updated successfully!')),
          );
        }
      }

      _resetForm();
      if (mounted) {
        setState(() => _showForm = false);
      }
    } catch (e, stackTrace) {
      _logError('Offer save', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving offer: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        // print('🔄 Loading state set to false');
      }
    }
  }

  Future<void> _deleteOffer(String offerId) async {
    try {
      // print('🗑️ Deleting offer: $offerId');

      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this offer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (shouldDelete == true) {
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(offerId)
            .delete();
        _logSuccess('Offer deleted', 'Document ID: $offerId');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offer deleted successfully')),
          );
        }

        if (_editingOfferId == offerId) {
          _resetForm();
        }
      } else {
        // print('ℹ️ Delete cancelled by user');
      }
    } catch (e, stackTrace) {
      _logError('Offer deletion', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  void _editOffer(DocumentSnapshot doc) {
    try {
      // print('✏️ Editing offer: ${doc.id}');
      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        _editingOfferId = doc.id;
        _titleController.text = data['title'] ?? '';
        _descController.text = data['description'] ?? '';
        _codeController.text = data['code'] ?? '';
        _discountController.text = data['discount'] ?? '';
        _minPurchaseController.text = data['minPurchase'] ?? '';
        _categoryController.text = data['category'] ?? '';
        _editingImageUrl = data['imageUrl'];
        _isActive = data['isActive'] ?? true;
        _selectedImage = null;
        _showForm = true;

        if (data['validUntil'] is Timestamp) {
          _validUntil = (data['validUntil'] as Timestamp).toDate();
        } else {
          _validUntil = DateTime.now();
        }
      });

      _logSuccess('Offer editing setup', 'Document ID: ${doc.id}');
    } catch (e, stackTrace) {
      _logError('Offer editing setup', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to setup edit: $e')));
      }
    }
  }

  Future<void> _autoInactivateExpiredOffers() async {
    try {
      // print('🔄 Checking for expired offers...');
      final now = DateTime.now();

      final expiredOffers = await FirebaseFirestore.instance
          .collection('offers')
          .where('validUntil', isLessThan: now)
          .where('isActive', isEqualTo: true)
          .get();

      // print('📊 Found ${expiredOffers.docs.length} expired offers');

      for (var doc in expiredOffers.docs) {
        try {
          await doc.reference.update({'isActive': false});
          // print('✅ Inactivated expired offer: ${doc.id}');
        } catch (e, stackTrace) {
          _logError('Inactivating single offer ${doc.id}', e, stackTrace);
        }
      }

      if (expiredOffers.docs.isNotEmpty) {
        _logSuccess(
          'Expired offers inactivated',
          'Count: ${expiredOffers.docs.length}',
        );
      }
    } catch (e, stackTrace) {
      _logError('Auto-inactivating expired offers', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking expired offers: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Manage Offers',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
        actions: [
          if (_showForm)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _resetForm();
                setState(() => _showForm = false);
              },
              tooltip: 'Close Form',
            ),
        ],
      ),
      floatingActionButton: !_showForm
          ? FloatingActionButton(
              onPressed: () {
                _resetForm();
                setState(() {
                  _showForm = true;
                  _validUntil = DateTime.now();
                });
                // print('➕ Add offer form opened');
              },
              backgroundColor: Colors.black,
              child: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Add Offer',
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _showForm
            ? SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          _editingOfferId == null
                              ? 'Add New Offer'
                              : 'Edit Offer',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleController,
                          style: GoogleFonts.poppins(color: Colors.black),
                          decoration: _inputDecoration('Title'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _descController,
                          style: GoogleFonts.poppins(color: Colors.black),
                          decoration: _inputDecoration('Description'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _codeController,
                          style: GoogleFonts.poppins(color: Colors.black),
                          decoration: _inputDecoration('Code'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _discountController,
                          style: GoogleFonts.poppins(color: Colors.black),
                          decoration: _inputDecoration('Discount (%)').copyWith(
                            suffixText: '%',
                            suffixStyle: GoogleFonts.poppins(
                              color: Colors.black54,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            final value = int.tryParse(v);
                            if (value == null || value < 0 || value > 100)
                              return 'Enter 0-100';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _minPurchaseController,
                          style: GoogleFonts.poppins(color: Colors.black),
                          decoration: _inputDecoration('Min Purchase').copyWith(
                            prefixText: 'PKR ',
                            prefixStyle: GoogleFonts.poppins(
                              color: Colors.black54,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _categoryController,
                          style: GoogleFonts.poppins(color: Colors.black),
                          decoration: _inputDecoration('Category'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _pickDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              style: GoogleFonts.poppins(color: Colors.black),
                              decoration: _inputDecoration('Valid Until'),
                              controller: TextEditingController(
                                text: _validUntil != null
                                    ? DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(_validUntil!)
                                    : '',
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _pickImage,
                              icon: const Icon(Icons.image),
                              label: Text(
                                'Pick Image',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (_selectedImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else if (_editingImageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _editingImageUrl!,
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    _logError(
                                      'Image loading',
                                      error,
                                      stackTrace,
                                    );
                                    return const Icon(Icons.error);
                                  },
                                ),
                              ),
                          ],
                        ),
                        SwitchListTile(
                          title: Text(
                            'Active',
                            style: GoogleFonts.poppins(color: Colors.black),
                          ),
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                          activeColor: Colors.black,
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.black12,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            textStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _isLoading ? null : _saveOffer,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  _editingOfferId == null
                                      ? 'Save Offer'
                                      : 'Update Offer',
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('offers')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    _logError('StreamBuilder snapshot', snapshot.error);
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No offers yet',
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 18,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final validUntil = data['validUntil'];
                      String validUntilStr = '';
                      if (validUntil is Timestamp) {
                        validUntilStr = DateFormat(
                          'dd MMM yyyy',
                        ).format(validUntil.toDate());
                      }
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading:
                              data['imageUrl'] != null &&
                                  data['imageUrl'].toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    data['imageUrl'],
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      _logError(
                                        'List item image loading',
                                        error,
                                        stackTrace,
                                      );
                                      return const Icon(
                                        Icons.image,
                                        color: Colors.black26,
                                        size: 40,
                                      );
                                    },
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.local_offer,
                                    color: Colors.black26,
                                    size: 40,
                                  ),
                                ),
                          title: Text(
                            data['title'] ?? '',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((data['description'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    data['description'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Chip(
                                      label: Text(
                                        '${data['discount'] ?? '0'}%',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Colors.green[700],
                                    ),
                                    Chip(
                                      label: Text(
                                        'Min: PKR ${data['minPurchase'] ?? '0'}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Colors.blueGrey,
                                    ),
                                    if (validUntilStr.isNotEmpty)
                                      Chip(
                                        label: Text(
                                          'Valid: $validUntilStr',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: Colors.black87,
                                      ),
                                    // Move trailing icons here for better wrapping
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.amber,
                                      ),
                                      tooltip: 'Edit',
                                      onPressed: () => _editOffer(docs[i]),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Delete',
                                      onPressed: () => _deleteOffer(docs[i].id),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          trailing: null, // Remove trailing from ListTile
                          onTap: () => _editOffer(docs[i]),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      _titleController.dispose();
      _descController.dispose();
      _codeController.dispose();
      _discountController.dispose();
      _minPurchaseController.dispose();
      _categoryController.dispose();
      _logSuccess('Controllers disposed');
    } catch (e, stackTrace) {
      _logError('Disposing controllers', e, stackTrace);
    }
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black),
      ),
    );
  }
}
