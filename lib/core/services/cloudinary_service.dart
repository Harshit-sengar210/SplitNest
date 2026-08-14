import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  /// Uploads an image to Cloudinary and returns the secure URL.
  /// Accepts either a base64 string (data URI) or a file path.
  static Future<String?> uploadImage(String imagePathOrBase64) async {
    try {
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      final preset = dotenv.env['CLOUDINARY_PRESET'];

      if (cloudName == null || preset == null) {
        debugPrint('Cloudinary configuration missing in .env');
        return null;
      }

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      var request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = preset;

      if (imagePathOrBase64.startsWith('data:image')) {
        // Handle Base64 string
        // Format: data:image/png;base64,iVBORw0KGgo...
        final parts = imagePathOrBase64.split(',');
        if (parts.length != 2) return null;
        
        final base64Str = parts[1];
        final bytes = base64Decode(base64Str);
        
        // Extract mime type for extension
        String extension = 'png';
        if (parts[0].contains('jpeg') || parts[0].contains('jpg')) {
          extension = 'jpg';
        }
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'upload_image.$extension',
          ),
        );
      } else if (imagePathOrBase64.startsWith('http://') || imagePathOrBase64.startsWith('https://')) {
        // It's already a network URL (e.g. from a preset), just return it
        return imagePathOrBase64;
      } else {
        // Handle local file path
        if (kIsWeb) {
          debugPrint('File path upload is not supported on web directly unless it is a blob URL.');
          // You might need to handle web blob URLs differently if they occur.
          // For now, if it's not base64 on web, it might fail.
          request.fields['file'] = imagePathOrBase64; 
        } else {
          final file = File(imagePathOrBase64);
          if (!await file.exists()) {
             debugPrint('File does not exist: $imagePathOrBase64');
             return null;
          }
          request.files.add(
            await http.MultipartFile.fromPath('file', imagePathOrBase64),
          );
        }
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(responseBody);
        return jsonResponse['secure_url'];
      } else {
        debugPrint('Cloudinary upload failed: \${response.statusCode} - $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('Exception during Cloudinary upload: $e');
      return null;
    }
  }
}
