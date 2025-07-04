import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

// Cloudinary Service - Place in lib/services/cloudinary_service.dart
class CloudinaryService {
  static const String cloudName = 'name_of_your_cloud'; // Replace with your Cloudinary cloud name
  static const String apiKey = 'key';
  static const String apiSecret = 'secret';
  static const String uploadPreset = 'flutter_ecommerce_app'; // Optional

  // Upload image to Cloudinary
  static Future<String> uploadImage(File imageFile) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    // Create multipart request
    var request = http.MultipartRequest('POST', url);

    // Add file to request
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    // Add parameters (using upload preset if available)
    if (uploadPreset.isNotEmpty) {
      request.fields['upload_preset'] = uploadPreset;
    } else {
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      // Generate signature
      final signature = _generateSignature(request.fields);
      request.fields['signature'] = signature;
    }

    // Send request
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonResponse = json.decode(responseData);

    if (response.statusCode == 200) {
      return jsonResponse['secure_url'];
    } else {
      throw Exception(
        'Failed to upload image: ${jsonResponse['error']['message']}',
      );
    }
  }

  // Delete image from Cloudinary
  static Future<void> deleteImage(String publicId) async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();
    final signature = _generateSignature({
      'public_id': publicId,
      'timestamp': timestamp,
    });

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
    );

    final response = await http.post(
      url,
      body: {
        'public_id': publicId,
        'signature': signature,
        'api_key': apiKey,
        'timestamp': timestamp,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete image: ${response.body}');
    }
  }

  // Extract public ID from Cloudinary URL
  static String getPublicIdFromUrl(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 2) return '';

      // Find the index of the 'upload' segment
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1)
        return '';

      // Extract the part after the version number
      final publicIdParts = pathSegments.sublist(uploadIndex + 2);
      return publicIdParts.join('/').split('.')[0];
    } catch (e) {
      debugPrint('Error parsing Cloudinary URL: $e');
      return '';
    }
  }

  // Generate signature for Cloudinary upload
  static String _generateSignature(Map<String, String> params) {
    // Sort parameters alphabetically
    final sortedKeys = params.keys.toList()..sort();
    final signatureParams = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');

    // Append API secret and hash
    final signatureString = '$signatureParams$apiSecret';
    return sha256.convert(utf8.encode(signatureString)).toString();
  }
}
