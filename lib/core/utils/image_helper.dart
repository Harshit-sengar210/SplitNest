import 'dart:convert';
import 'package:flutter/material.dart';

/// Resolves a dynamic image path/URL/base64 string into a compatible [ImageProvider].
ImageProvider? getAvatarImageProvider(String? path) {
  if (path == null || path.isEmpty) return null;
  
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  
  if (path.startsWith('data:image')) {
    try {
      final base64Str = path.contains(',') ? path.split(',')[1] : path;
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  }
  
  return NetworkImage(path); // Fallback
}
