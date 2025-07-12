// lib/routes/attraction_routes.dart
// ignore_for_file: unused_import

import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database_connection.dart';
import '../models/attraction.dart';
import '../utils/response_helper.dart';

class AttractionRoutes {
  Router get router {
    final router = Router();

    // IMPORTANT: Put specific routes BEFORE parameterized routes
    // GET /api/attractions/search?q=<query> - Search attractions
    router.get('/search', _searchAttractions);

    // GET /api/attractions/popular - Get popular attractions
    router.get('/popular', _getPopularAttractions);

    // GET /api/attractions/filter - Filter attractions
    router.get('/filter', _filterAttractions);

    // GET /api/attractions - Get all attractions
    router.get('/', _getAllAttractions);

    // GET /api/attractions/<id> - Get attraction by ID (MUST be last)
    router.get('/<id>', _getAttractionById);

    return router;
  }

  Future<Response> _getAllAttractions(Request request) async {
    try {
      print('🔍 Fetching all attractions...');

      final results = await DatabaseConnection.query('''
        SELECT * FROM attractions ORDER BY is_popular DESC, rating DESC
      ''');

      if (results == null || results.isEmpty) {
        print('⚠️  No data from database, using fallback data');
        return ResponseHelper.success(data: _getFallbackAttractions());
      }

      print('✅ Found ${results.length} attractions in database');

      final attractions = <Map<String, dynamic>>[];
      for (final row in results) {
        try {
          final attraction = Attraction.fromDatabase(row);
          attractions.add(attraction.toJson());
        } catch (e) {
          print('❌ Error processing attraction row: $e');
          // Continue with other rows
        }
      }

      if (attractions.isEmpty) {
        print('⚠️  No valid attractions processed, using fallback data');
        return ResponseHelper.success(data: _getFallbackAttractions());
      }

      return ResponseHelper.success(data: attractions);
    } catch (e) {
      print('❌ Error in _getAllAttractions: $e');
      return ResponseHelper.success(data: _getFallbackAttractions());
    }
  }

  Future<Response> _getAttractionById(Request request) async {
    try {
      final id = int.tryParse(request.params['id'] ?? '');
      if (id == null) {
        return ResponseHelper.badRequest(message: 'Invalid attraction ID');
      }

      final results = await DatabaseConnection.query(
          'SELECT * FROM attractions WHERE id = ?', [id]);

      if (results == null || results.isEmpty) {
        // Try fallback data
        final fallback = _getFallbackAttractions().firstWhere(
          (a) => a['id'] == id,
          orElse: () => {},
        );
        if (fallback.isNotEmpty) {
          return ResponseHelper.success(data: fallback);
        }
        return ResponseHelper.notFound(message: 'Attraction not found');
      }

      final attraction = Attraction.fromDatabase(results.first);
      return ResponseHelper.success(data: attraction.toJson());
    } catch (e) {
      print('❌ Error in _getAttractionById: $e');
      return ResponseHelper.error(message: 'Failed to fetch attraction: $e');
    }
  }

  Future<Response> _searchAttractions(Request request) async {
    try {
      final query = request.url.queryParameters['q'];
      if (query == null || query.isEmpty) {
        return ResponseHelper.badRequest(message: 'Search query is required');
      }

      print('🔍 Searching attractions for: "$query"');

      final results = await DatabaseConnection.query('''
        SELECT * FROM attractions 
        WHERE name LIKE ? OR description LIKE ? OR location LIKE ?
        ORDER BY rating DESC
      ''', ['%$query%', '%$query%', '%$query%']);

      if (results == null) {
        print('⚠️  Database search failed, using fallback data');
        // Use fallback data for search
        final fallback = _getFallbackAttractions().where((a) {
          final name = (a['name'] as String).toLowerCase();
          final location = (a['location'] as String).toLowerCase();
          final description = (a['description'] as String).toLowerCase();
          return name.contains(query.toLowerCase()) ||
              location.contains(query.toLowerCase()) ||
              description.contains(query.toLowerCase());
        }).toList();
        return ResponseHelper.success(data: fallback);
      }

      print('✅ Found ${results.length} search results');

      final attractions = results
          .map((row) {
            try {
              final attraction = Attraction.fromDatabase(row);
              return attraction.toJson();
            } catch (e) {
              print('❌ Error processing search result: $e');
              return null;
            }
          })
          .where((a) => a != null)
          .toList();

      return ResponseHelper.success(data: attractions);
    } catch (e) {
      print('❌ Error in _searchAttractions: $e');
      return ResponseHelper.error(message: 'Search failed: $e');
    }
  }

  Future<Response> _getPopularAttractions(Request request) async {
    try {
      final results = await DatabaseConnection.query('''
        SELECT * FROM attractions WHERE is_popular = 1 ORDER BY rating DESC
      ''');

      if (results == null) {
        final popular = _getFallbackAttractions()
            .where((a) => a['is_popular'] == true)
            .toList();
        return ResponseHelper.success(data: popular);
      }

      final attractions = results
          .map((row) {
            try {
              final attraction = Attraction.fromDatabase(row);
              return attraction.toJson();
            } catch (e) {
              print('❌ Error processing popular attraction: $e');
              return null;
            }
          })
          .where((a) => a != null)
          .toList();

      return ResponseHelper.success(data: attractions);
    } catch (e) {
      print('❌ Error in _getPopularAttractions: $e');
      return ResponseHelper.error(
          message: 'Failed to fetch popular attractions: $e');
    }
  }

  Future<Response> _filterAttractions(Request request) async {
    try {
      final category = request.url.queryParameters['category'];
      final location = request.url.queryParameters['location'];
      final minRating =
          double.tryParse(request.url.queryParameters['min_rating'] ?? '');

      String sql = 'SELECT * FROM attractions WHERE 1=1';
      List<dynamic> params = [];

      if (category != null && category.isNotEmpty) {
        sql += ' AND category = ?';
        params.add(category);
      }

      if (location != null && location.isNotEmpty) {
        sql += ' AND location LIKE ?';
        params.add('%$location%');
      }

      if (minRating != null) {
        sql += ' AND rating >= ?';
        params.add(minRating);
      }

      sql += ' ORDER BY rating DESC';

      final results = await DatabaseConnection.query(sql, params);

      if (results == null) {
        // Use fallback data with filters
        var filtered = _getFallbackAttractions();

        if (category != null) {
          filtered = filtered.where((a) => a['category'] == category).toList();
        }
        if (location != null) {
          filtered = filtered
              .where((a) => (a['location'] as String)
                  .toLowerCase()
                  .contains(location.toLowerCase()))
              .toList();
        }
        if (minRating != null) {
          filtered = filtered.where((a) => a['rating'] >= minRating).toList();
        }

        return ResponseHelper.success(data: filtered);
      }

      final attractions = results
          .map((row) {
            try {
              final attraction = Attraction.fromDatabase(row);
              return attraction.toJson();
            } catch (e) {
              print('❌ Error processing filtered attraction: $e');
              return null;
            }
          })
          .where((a) => a != null)
          .toList();

      return ResponseHelper.success(data: attractions);
    } catch (e) {
      print('❌ Error in _filterAttractions: $e');
      return ResponseHelper.error(message: 'Filter failed: $e');
    }
  }

  // Fallback data when database is not available
  List<Map<String, dynamic>> _getFallbackAttractions() {
    return [
      {
        'id': 1,
        'name': 'Victoria Falls',
        'location': 'Livingstone',
        'description':
            'One of the Seven Natural Wonders of the World, locally known as "Mosi-oa-Tunya" (The Smoke That Thunders).',
        'image_path': 'assets/victoria_falls.jpg',
        'rating': 4.9,
        'price': 20.0,
        'activities': ['Viewing', 'Photography', 'Helicopter Tours'],
        'latitude': -17.9243,
        'longitude': 25.8572,
        'category': 'Natural Wonder',
        'is_popular': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      },
      {
        'id': 2,
        'name': 'South Luangwa National Park',
        'location': 'Eastern Province',
        'description':
            'Known for its abundant wildlife and walking safaris. Home to over 400 bird species and 60 different animal species.',
        'image_path': 'assets/south_luangwa.jpg',
        'rating': 4.8,
        'price': 25.0,
        'activities': ['Game Drives', 'Walking Safaris', 'Bird Watching'],
        'latitude': -13.0864,
        'longitude': 31.8656,
        'category': 'National Park',
        'is_popular': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      },
      {
        'id': 3,
        'name': 'Lower Zambezi National Park',
        'location': 'Southern Province',
        'description':
            'Offers exceptional game viewing along the Zambezi River with canoeing and fishing experiences.',
        'image_path': 'assets/lower_zambezi.jpg',
        'rating': 4.7,
        'price': 25.0,
        'activities': ['Game Drives', 'Canoeing', 'Fishing'],
        'latitude': -15.75,
        'longitude': 29.25,
        'category': 'National Park',
        'is_popular': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      },
    ];
  }
}
