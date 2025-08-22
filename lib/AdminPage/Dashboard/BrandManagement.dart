import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_ecommerce_app/AdminPage/models/Brand.dart';
import 'package:flutter_ecommerce_app/services/cloudinary_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class BrandManagement extends StatefulWidget {
  const BrandManagement({super.key});

  @override
  State<BrandManagement> createState() => _BrandManagementState();
}

class _BrandManagementState extends State<BrandManagement> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();

  String? _logoUrl;
  String? _bannerUrl;
  File? _selectedLogoFile;
  File? _selectedBannerFile;
  bool _isLoading = false;
  bool _isUploadingLogo = false;
  bool _isUploadingBanner = false;
  Brand? _editingBrand;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isLogo, ImageSource source, StateSetter? dialogSetState) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: isLogo ? 512 : 1200,
      maxHeight: isLogo ? 512 : 800,
      imageQuality: 80,
    );

    if (image == null) return;

    final file = File(image.path);
    
    if (dialogSetState != null) {
      dialogSetState(() {
        if (isLogo) {
          _selectedLogoFile = file;
        } else {
          _selectedBannerFile = file;
        }
      });
    } else {
      setState(() {
        if (isLogo) {
          _selectedLogoFile = file;
        } else {
          _selectedBannerFile = file;
        }
      });
    }
  }

  void _removeImage(bool isLogo, StateSetter? dialogSetState) {
    if (dialogSetState != null) {
      dialogSetState(() {
        if (isLogo) {
          _selectedLogoFile = null;
          _logoUrl = null;
        } else {
          _selectedBannerFile = null;
          _bannerUrl = null;
        }
      });
    } else {
      setState(() {
        if (isLogo) {
          _selectedLogoFile = null;
          _logoUrl = null;
        } else {
          _selectedBannerFile = null;
          _bannerUrl = null;
        }
      });
    }
  }

  Future<String?> _uploadImage(File? file, String? existingUrl) async {
    if (file == null) return existingUrl;

    try {
      return await CloudinaryService.uploadImage(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _deleteImage(String? imageUrl) async {
    if (imageUrl == null) return;

    try {
      final publicId = CloudinaryService.getPublicIdFromUrl(imageUrl);
      if (publicId.isNotEmpty) {
        await CloudinaryService.deleteImage(publicId);
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<void> _saveBrand() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      
      // Upload images if new files are selected
      String? uploadedLogoUrl = _logoUrl;
      String? uploadedBannerUrl = _bannerUrl;

      if (_selectedLogoFile != null) {
        setState(() => _isUploadingLogo = true);
        uploadedLogoUrl = await _uploadImage(_selectedLogoFile, _logoUrl);
        setState(() => _isUploadingLogo = false);
      }

      if (_selectedBannerFile != null) {
        setState(() => _isUploadingBanner = true);
        uploadedBannerUrl = await _uploadImage(_selectedBannerFile, _bannerUrl);
        setState(() => _isUploadingBanner = false);
      }

      if (_editingBrand != null) {
        // Delete old images if replaced
        if (uploadedLogoUrl != _editingBrand!.logoUrl && _editingBrand!.logoUrl != null) {
          await _deleteImage(_editingBrand!.logoUrl);
        }
        if (uploadedBannerUrl != _editingBrand!.imageUrl && _editingBrand!.imageUrl != null) {
          await _deleteImage(_editingBrand!.imageUrl);
        }

        // Update existing brand
        final updatedBrand = Brand(
          uuid: _editingBrand!.uuid,
          id: _editingBrand!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          website: _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
          logoUrl: uploadedLogoUrl,
          imageUrl: uploadedBannerUrl,
          createdAt: _editingBrand!.createdAt,
          updatedAt: now,
          isActive: _editingBrand!.isActive,
        );

        await _firestore
            .collection('brands')
            .doc(_editingBrand!.id)
            .update(updatedBrand.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brand updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Add new brand
        final brandId = _uuid.v4();
        final newBrand = Brand(
          id: brandId,
          uuid: brandId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          website: _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
          logoUrl: uploadedLogoUrl,
          imageUrl: uploadedBannerUrl,
          isActive: true,
          createdAt: now,
        );

        await _firestore
            .collection('brands')
            .doc(brandId)
            .set(newBrand.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brand added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving brand: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isUploadingLogo = false;
        _isUploadingBanner = false;
      });
    }
  }

  Future<void> _deleteBrand(Brand brand) async {
    try {
      // Delete images from Cloudinary
      await _deleteImage(brand.logoUrl);
      await _deleteImage(brand.imageUrl);

      // Delete the brand document
      await _firestore.collection('brands').doc(brand.id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brand deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting brand: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildImageUploadSection(bool isLogo, StateSetter? dialogSetState) {
    final isUploading = isLogo ? _isUploadingLogo : _isUploadingBanner;
    final selectedFile = isLogo ? _selectedLogoFile : _selectedBannerFile;
    final existingUrl = isLogo ? _logoUrl : _bannerUrl;
    final imageTitle = isLogo ? 'Logo' : 'Banner';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            imageTitle,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          
          // Image Preview
          if (selectedFile != null || existingUrl != null)
            Stack(
              children: [
                Container(
                  width: isLogo ? 100 : 150,
                  height: isLogo ? 100 : 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: selectedFile != null
                        ? Image.file(selectedFile, fit: BoxFit.cover)
                        : (existingUrl != null
                            ? Image.network(existingUrl, fit: BoxFit.cover)
                            : const Icon(Icons.image, size: 40)),
                  ),
                ),
                // Remove button
                Positioned(
                  top: -8,
                  right: -8,
                  child: IconButton(
                    onPressed: isUploading ? null : () => _removeImage(isLogo, dialogSetState),
                    icon: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 12),
          
          // Upload buttons
          if (selectedFile == null && existingUrl == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () => _pickImage(isLogo, ImageSource.gallery, dialogSetState),
                  icon: const Icon(Icons.photo_library),
                  label: Text('Gallery', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () => _pickImage(isLogo, ImageSource.camera, dialogSetState),
                  icon: const Icon(Icons.camera_alt),
                  label: Text('Camera', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          
          // Upload progress indicator
          if (isUploading)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Uploading $imageTitle...',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBrandCard(Brand brand) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: brand.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            brand.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.branding_watermark,
                                color: Colors.grey,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.branding_watermark,
                          color: Colors.grey,
                        ),
                ),
                const SizedBox(width: 12),
                // Brand info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (brand.description != null &&
                          brand.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            brand.description!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (brand.website != null && brand.website!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            brand.website!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditBrandDialog(brand),
                      tooltip: 'Edit Brand',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteBrand(brand),
                      tooltip: 'Delete Brand',
                    ),
                  ],
                ),
              ],
            ),
            // Banner image (if exists)
            if (brand.imageUrl != null && brand.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    brand.imageUrl!,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 120,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _websiteController.clear();
    _logoUrl = null;
    _bannerUrl = null;
    _selectedLogoFile = null;
    _selectedBannerFile = null;
  }

  Future<void> _showAddBrandDialog() async {
    _resetForm();
    _editingBrand = null;
    await _showBrandDialog('Add New Brand');
  }

  Future<void> _showEditBrandDialog(Brand brand) async {
    _resetForm();
    _editingBrand = brand;
    _nameController.text = brand.name;
    _descriptionController.text = brand.description ?? '';
    _websiteController.text = brand.website ?? '';
    _logoUrl = brand.logoUrl;
    _bannerUrl = brand.imageUrl;

    await _showBrandDialog('Edit Brand');
  }

  Widget _buildBrandForm(StateSetter dialogSetState) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Brand Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.branding_watermark),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter brand name';
                }
                if (value.length < 2) {
                  return 'Brand name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: InputDecoration(
                labelText: 'Website (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'https://example.com',
                prefixIcon: const Icon(Icons.web),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return 'Please enter a valid URL';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Logo Upload Section
            _buildImageUploadSection(true, dialogSetState),
            const SizedBox(height: 16),
            
            // Banner Upload Section
            _buildImageUploadSection(false, dialogSetState),
          ],
        ),
      ),
    );
  }

  Future<void> _showBrandDialog(String title) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: Text(
            title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: _buildBrandForm(dialogSetState),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: (_isLoading || _isUploadingLogo || _isUploadingBanner) ? null : _saveBrand,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: (_isLoading || _isUploadingLogo || _isUploadingBanner)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _editingBrand != null ? 'Update' : 'Add',
                      style: GoogleFonts.poppins(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteBrand(Brand brand) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Brand',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${brand.name}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteBrand(brand);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Brand Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('brands')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.poppins(),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.branding_watermark,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No brands found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first brand',
                    style: GoogleFonts.poppins(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final brands = snapshot.data!.docs
              .map((doc) => Brand.fromDocument(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              return _buildBrandCard(brands[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBrandDialog,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}