// lib/routes/accommodation_routes.dart
// ignore_for_file: unused_import

import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database_connection.dart';
import '../models/accommodation.dart';
import '../utils/response_helper.dart';

class AccommodationRoutes {
  Router get router {
    final router = Router();

    // GET /api/accommodations - Get all accommodations
    router.get('/', _getAllAccommodations);

    // GET /api/accommodations/<id> - Get accommodation by ID
    router.get('/<id>', _getAccommodationById);

    // GET /api/accommodations/search?q=<query> - Search accommodations
    router.get('/search', _searchAccommodations);

    // GET /api/accommodations/filter - Filter accommodations
    router.get('/filter', _filterAccommodations);

    return router;
  }

  Future<Response> _getAllAccommodations(Request request) async {
    try {
      print('🔍 Fetching all accommodations...');

      final results = await DatabaseConnection.query('''
        SELECT * FROM accommodations ORDER BY rating DESC
      ''');

      if (results == null || results.isEmpty) {
        print('⚠️  No data from database, using fallback data');
        return ResponseHelper.success(data: _getFallbackAccommodations());
      }

      print('✅ Found ${results.length} accommodations in database');

      final accommodations = <Map<String, dynamic>>[];
      for (final row in results) {
        try {
          final accommodation = Accommodation.fromDatabase(row);
          accommodations.add(accommodation.toJson());
        } catch (e) {
          print('❌ Error processing accommodation row: $e');
          // Continue with other rows
        }
      }

      if (accommodations.isEmpty) {
        print('⚠️  No valid accommodations processed, using fallback data');
        return ResponseHelper.success(data: _getFallbackAccommodations());
      }

      return ResponseHelper.success(data: accommodations);
    } catch (e) {
      print('❌ Error in _getAllAccommodations: $e');
      return ResponseHelper.success(data: _getFallbackAccommodations());
    }
  }

  Future<Response> _getAccommodationById(Request request) async {
    try {
      final id = int.tryParse(request.params['id'] ?? '');
      if (id == null) {
        return ResponseHelper.badRequest(message: 'Invalid accommodation ID');
      }

      final results = await DatabaseConnection.query(
          'SELECT * FROM accommodations WHERE id = ?', [id]);

      if (results == null || results.isEmpty) {
        // Try fallback data
        final fallback = _getFallbackAccommodations().firstWhere(
          (a) => a['id'] == id,
          orElse: () => {},
        );
        if (fallback.isNotEmpty) {
          return ResponseHelper.success(data: fallback);
        }
        return ResponseHelper.notFound(message: 'Accommodation not found');
      }

      final accommodation = Accommodation.fromDatabase(results.first);
      return ResponseHelper.success(data: accommodation.toJson());
    } catch (e) {
      print('❌ Error in _getAccommodationById: $e');
      return ResponseHelper.error(message: 'Failed to fetch accommodation: $e');
    }
  }

  Future<Response> _searchAccommodations(Request request) async {
    try {
      final query = request.url.queryParameters['q'];
      if (query == null || query.isEmpty) {
        return ResponseHelper.badRequest(message: 'Search query is required');
      }

      final results = await DatabaseConnection.query('''
        SELECT * FROM accommodations 
        WHERE name LIKE ? OR description LIKE ? OR location LIKE ?
        ORDER BY rating DESC
      ''', ['%$query%', '%$query%', '%$query%']);

      if (results == null) {
        // Use fallback data for search
        final fallback = _getFallbackAccommodations().where((a) {
          final name = (a['name'] as String).toLowerCase();
          final location = (a['location'] as String).toLowerCase();
          final description = (a['description'] as String).toLowerCase();
          return name.contains(query.toLowerCase()) ||
              location.contains(query.toLowerCase()) ||
              description.contains(query.toLowerCase());
        }).toList();
        return ResponseHelper.success(data: fallback);
      }

      final accommodations = results
          .map((row) {
            try {
              final accommodation = Accommodation.fromDatabase(row);
              return accommodation.toJson();
            } catch (e) {
              print('❌ Error processing search result: $e');
              return null;
            }
          })
          .where((a) => a != null)
          .toList();

      return ResponseHelper.success(data: accommodations);
    } catch (e) {
      print('❌ Error in _searchAccommodations: $e');
      return ResponseHelper.error(message: 'Search failed: $e');
    }
  }

  Future<Response> _filterAccommodations(Request request) async {
    try {
      final type = request.url.queryParameters['type'];
      final location = request.url.queryParameters['location'];
      final minPrice =
          double.tryParse(request.url.queryParameters['min_price'] ?? '');
      final maxPrice =
          double.tryParse(request.url.queryParameters['max_price'] ?? '');

      String sql = 'SELECT * FROM accommodations WHERE 1=1';
      List<dynamic> params = [];

      if (type != null && type.isNotEmpty) {
        sql += ' AND type = ?';
        params.add(type);
      }

      if (location != null && location.isNotEmpty) {
        sql += ' AND location LIKE ?';
        params.add('%$location%');
      }

      if (minPrice != null) {
        sql += ' AND price >= ?';
        params.add(minPrice);
      }

      if (maxPrice != null) {
        sql += ' AND price <= ?';
        params.add(maxPrice);
      }

      sql += ' ORDER BY rating DESC';

      final results = await DatabaseConnection.query(sql, params);

      if (results == null) {
        // Use fallback data with filters
        var filtered = _getFallbackAccommodations();

        if (type != null) {
          filtered = filtered.where((a) => a['type'] == type).toList();
        }
        if (location != null) {
          filtered = filtered
              .where((a) => (a['location'] as String)
                  .toLowerCase()
                  .contains(location.toLowerCase()))
              .toList();
        }
        if (minPrice != null) {
          filtered = filtered.where((a) => a['price'] >= minPrice).toList();
        }
        if (maxPrice != null) {
          filtered = filtered.where((a) => a['price'] <= maxPrice).toList();
        }

        return ResponseHelper.success(data: filtered);
      }

      final accommodations = results
          .map((row) {
            try {
              final accommodation = Accommodation.fromDatabase(row);
              return accommodation.toJson();
            } catch (e) {
              print('❌ Error processing filtered accommodation: $e');
              return null;
            }
          })
          .where((a) => a != null)
          .toList();

      return ResponseHelper.success(data: accommodations);
    } catch (e) {
      print('❌ Error in _filterAccommodations: $e');
      return ResponseHelper.error(message: 'Filter failed: $e');
    }
  }

  // Fallback data when database is not available
  List<Map<String, dynamic>> _getFallbackAccommodations() {
    return [
      {
        'id': 1,
        'name': 'Royal Livingstone Hotel',
        'description':
            'Luxury hotel situated on the banks of the Zambezi River with stunning views of Victoria Falls.',
        'location': 'Livingstone',
        'type': 'Hotels',
        'price': 350.0,
        'rating': 4.8,
        'image_path': 'assets/royal_livingstone.jpg',
        'amenities': ['Pool', 'Spa', 'Free WiFi', 'Restaurant', 'Bar'],
        'is_available': true,
        'review_count': 245,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      },
      {
        'id': 2,
        'name': 'Tongabezi Lodge',
        'description':
            'Award-winning luxury lodge with private houses and cottages on the banks of the Zambezi River.',
        'location': 'Livingstone',
        'type': 'Lodges',
        'price': 420.0,
        'rating': 4.9,
        'image_path': 'assets/tongabezi.jpg',
        'amenities': ['Pool', 'Spa', 'Free WiFi', 'Restaurant', 'River views'],
        'is_available': true,
        'review_count': 189,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      },
      {
        'id': 3,
        'name': 'Mfuwe Lodge',
        'description':
            'Safari lodge located inside South Luangwa National Park, known for elephants walking through reception.',
        'location': 'South Luangwa',
        'type': 'Lodges',
        'price': 280.0,
        'rating': 4.7,
        'image_path': 'assets/mfuwe_lodge.jpg',
        'amenities': [
          'Pool',
          'Game drives',
          'Restaurant',
          'Bar',
          'Wildlife viewing'
        ],
        'is_available': true,
        'review_count': 156,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      },
      {
        'id': 4,
        'name': 'Avani Victoria Falls Resort',
        'description':
            'Family-friendly resort with free access to Victoria Falls and African-themed architecture.',
        'location': 'Livingstone',
        'type': 'Resorts',
        'price': 220.0,
        'rating': 4.5,
        'image_path': 'assets/avani_resort.jpg',
        'amenities': ['Pool', 'Free WiFi', 'Restaurant', 'Bar', 'Falls access'],
        'is_available': true,
        'review_count': 298,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      },
    ];
  }
}
