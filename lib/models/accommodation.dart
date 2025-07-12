// lib/models/accommodation.dart
import 'package:mysql1/mysql1.dart';
import 'dart:typed_data';

class Accommodation {
  final int id;
  final String name;
  final String description;
  final String location;
  final String type;
  final double price;
  final double rating;
  final String imagePath;
  final List<String> amenities;
  final bool isAvailable;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Accommodation({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.type,
    required this.price,
    required this.rating,
    required this.imagePath,
    required this.amenities,
    required this.isAvailable,
    required this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper method to safely convert database values to strings
  static String _safeStringConvert(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Uint8List) {
      // Convert BLOB to string
      return String.fromCharCodes(value);
    }
    if (value is Blob) {
      // Convert Blob to string
      return String.fromCharCodes(value.toBytes());
    }
    return value.toString();
  }

  // Helper method to safely convert to double
  static double _safeDoubleConvert(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper method to safely convert to int
  static int _safeIntConvert(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  factory Accommodation.fromDatabase(ResultRow row) {
    try {
      return Accommodation(
        id: _safeIntConvert(row['id']),
        name: _safeStringConvert(row['name']),
        description: _safeStringConvert(row['description']),
        location: _safeStringConvert(row['location']),
        type: _safeStringConvert(row['type']),
        price: _safeDoubleConvert(row['price']),
        rating: _safeDoubleConvert(row['rating']),
        imagePath: _safeStringConvert(row['image_path']),
        amenities: _parseAmenities(_safeStringConvert(row['amenities'])),
        isAvailable: _safeIntConvert(row['is_available']) == 1,
        reviewCount: _safeIntConvert(row['review_count']),
        createdAt: row['created_at'] as DateTime? ?? DateTime.now(),
        updatedAt: row['updated_at'] as DateTime? ?? DateTime.now(),
      );
    } catch (e) {
      print('Error creating Accommodation from database row: $e');
      print('Row data: ${row.fields}');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'type': type,
      'price': price,
      'rating': rating,
      'image_path': imagePath,
      'amenities': amenities,
      'is_available': isAvailable,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static List<String> _parseAmenities(String? amenitiesString) {
    if (amenitiesString == null || amenitiesString.isEmpty) {
      return [];
    }
    try {
      return amenitiesString
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error parsing amenities: $e');
      return [];
    }
  }
}
