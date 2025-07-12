// lib/models/attraction.dart
import 'package:mysql1/mysql1.dart';
import 'dart:typed_data';
import 'dart:convert';

class Attraction {
  final int id;
  final String name;
  final String location;
  final String description;
  final String imagePath;
  final double rating;
  final double price;
  final List<String> activities;
  final double latitude;
  final double longitude;
  final String category;
  final bool isPopular;
  final DateTime createdAt;
  final DateTime updatedAt;

  Attraction({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.imagePath,
    required this.rating,
    required this.price,
    required this.activities,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.isPopular,
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

  // Create from database row
  factory Attraction.fromDatabase(ResultRow row) {
    try {
      return Attraction(
        id: _safeIntConvert(row['id']),
        name: _safeStringConvert(row['name']),
        location: _safeStringConvert(row['location']),
        description: _safeStringConvert(row['description']),
        imagePath: _safeStringConvert(row['image_path']),
        rating: _safeDoubleConvert(row['rating']),
        price: _safeDoubleConvert(row['price']),
        activities: _parseActivities(_safeStringConvert(row['activities'])),
        latitude: _safeDoubleConvert(row['latitude']),
        longitude: _safeDoubleConvert(row['longitude']),
        category: _safeStringConvert(row['category']),
        isPopular: _safeIntConvert(row['is_popular']) == 1,
        createdAt: row['created_at'] as DateTime? ?? DateTime.now(),
        updatedAt: row['updated_at'] as DateTime? ?? DateTime.now(),
      );
    } catch (e) {
      print('Error creating Attraction from database row: $e');
      print('Row data: ${row.fields}');
      rethrow;
    }
  }

  // Convert to JSON for API response
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'description': description,
      'image_path': imagePath,
      'rating': rating,
      'price': price,
      'activities': activities,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'is_popular': isPopular,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Parse activities from JSON string or comma-separated string
  static List<String> _parseActivities(String? activitiesString) {
    if (activitiesString == null || activitiesString.isEmpty) {
      return [];
    }

    try {
      // First, try to parse as JSON array
      if (activitiesString.startsWith('[') && activitiesString.endsWith(']')) {
        try {
          final List<dynamic> jsonList = jsonDecode(activitiesString);
          return jsonList.map((e) => e.toString()).toList();
        } catch (e) {
          print('Failed to parse as JSON array: $e');
        }
      }

      // If it looks like a JSON string but wrapped in quotes, try to clean it
      if (activitiesString.startsWith('"[') &&
          activitiesString.endsWith(']"')) {
        try {
          // Remove outer quotes and try parsing
          final cleanString =
              activitiesString.substring(1, activitiesString.length - 1);
          final List<dynamic> jsonList = jsonDecode(cleanString);
          return jsonList.map((e) => e.toString()).toList();
        } catch (e) {
          print('Failed to parse cleaned JSON: $e');
        }
      }

      // Try parsing as comma-separated string
      if (activitiesString.contains(',')) {
        return activitiesString
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .map((e) {
          // Remove quotes if present
          if (e.startsWith('"') && e.endsWith('"')) {
            return e.substring(1, e.length - 1);
          }
          return e;
        }).toList();
      }

      // If all else fails, return as single item
      return [activitiesString];
    } catch (e) {
      print('Error parsing activities: $e for input: $activitiesString');
      return [activitiesString]; // Return the original string as fallback
    }
  }
}
