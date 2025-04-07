import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageUtils {
  // Check if a string is a valid base64 image
  static bool isBase64Image(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Display a base64 image with proper error handling
  static Widget buildBase64Image(
    String imageString, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
  }) {
    if (imageString.isEmpty) {
      return placeholder ?? _buildDefaultPlaceholder();
    }
    
    try {
      // Clean the base64 string if needed
      String cleanBase64 = imageString;
      if (imageString.contains(',')) {
        cleanBase64 = imageString.split(',').last;
      }
      
      final Uint8List bytes = base64Decode(cleanBase64);
      
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          print('Error displaying image: $error');
          return placeholder ?? _buildDefaultPlaceholder();
        },
      );
    } catch (e) {
      print('Error decoding base64 image: $e');
      return placeholder ?? _buildDefaultPlaceholder();
    }
  }
  
  // Default placeholder widget
  static Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
    );
  }
  
  // Compress image function for better performance
  static Future<String> compressAndEncodeImage(List<int> imageBytes) async {
    // Here you would add compression logic if needed
    return base64Encode(imageBytes);
  }
}