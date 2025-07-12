// bin/server.dart
// ignore_for_file: implicit_call_tearoffs

import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

// Sample data - In a real app, this would come from a database
final List<Map<String, dynamic>> attractions = [
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
  {
    'id': 4,
    'name': 'Kafue National Park',
    'location': 'Central Zambia',
    'description':
        'Zambia\'s oldest and largest national park with diverse landscapes and wildlife.',
    'image_path': 'assets/kafue_park.jpg',
    'rating': 4.6,
    'price': 20.0,
    'activities': ['Game Drives', 'Bush Walks', 'Boat Trips'],
    'latitude': -15.5,
    'longitude': 26.0,
    'category': 'National Park',
    'is_popular': false,
    'created_at': '2024-01-01T00:00:00Z',
    'updated_at': '2024-01-01T00:00:00Z',
  },
  {
    'id': 5,
    'name': 'Livingstone Museum',
    'location': 'Livingstone',
    'description':
        'Zambia\'s largest and oldest museum, featuring exhibits on David Livingstone and local culture.',
    'image_path': 'assets/livingstone_museum.jpg',
    'rating': 4.3,
    'price': 5.0,
    'activities': ['Museum Tours', 'Cultural Exhibits', 'Historical Learning'],
    'latitude': -17.8419,
    'longitude': 25.8564,
    'category': 'Museum',
    'is_popular': false,
    'created_at': '2024-01-01T00:00:00Z',
    'updated_at': '2024-01-01T00:00:00Z',
  },
];

final List<Map<String, dynamic>> accommodations = [
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
    'images': [],
    'coordinates': {'lat': -17.9243, 'lng': 25.8572},
    'is_available': true,
    'is_favorite': false,
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
    'images': [],
    'coordinates': {'lat': -17.9243, 'lng': 25.8572},
    'is_available': true,
    'is_favorite': false,
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
    'images': [],
    'coordinates': {'lat': -13.0864, 'lng': 31.8656},
    'is_available': true,
    'is_favorite': false,
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
    'images': [],
    'coordinates': {'lat': -17.9243, 'lng': 25.8572},
    'is_available': true,
    'is_favorite': false,
    'review_count': 298,
    'created_at': '2024-01-01T00:00:00Z',
    'updated_at': '2024-01-01T00:00:00Z',
  },
];

// Helper function to create JSON response
Response jsonResponse(Map<String, dynamic> data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {
      'Content-Type': 'application/json',
    },
  );
}

// Helper function to create error response
Response errorResponse(String message, {int statusCode = 400}) {
  return jsonResponse({
    'success': false,
    'message': message,
  }, statusCode: statusCode);
}

// Helper function to create success response
Response successResponse(dynamic data, {String? message}) {
  return jsonResponse({
    'success': true,
    'data': data,
    if (message != null) 'message': message,
  });
}

void main(List<String> args) async {
  // Use any available host or container IP (0.0.0.0).
  final ip = InternetAddress.anyIPv4;

  // Configure routes.
  final router = Router();

  // CORS middleware
  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(router);

  // Root endpoint
  router.get('/', (Request request) {
    return Response.ok('Zambia Tourism Backend API is running!');
  });

  // Health check
  router.get('/health', (Request request) {
    return jsonResponse({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    });
  });

  // Attractions endpoints
  router.get('/api/attractions', (Request request) {
    return successResponse(attractions);
  });

  router.get('/api/attractions/<id>', (Request request) {
    final id = int.tryParse(request.params['id'] ?? '');
    if (id == null) {
      return errorResponse('Invalid attraction ID');
    }

    final attraction = attractions.firstWhere(
      (a) => a['id'] == id,
      orElse: () => {},
    );

    if (attraction.isEmpty) {
      return errorResponse('Attraction not found', statusCode: 404);
    }

    return successResponse(attraction);
  });

  router.get('/api/attractions/popular', (Request request) {
    final popularAttractions =
        attractions.where((a) => a['is_popular'] == true).toList();
    return successResponse(popularAttractions);
  });

  router.get('/api/attractions/search', (Request request) {
    final query = request.url.queryParameters['q']?.toLowerCase();
    if (query == null || query.isEmpty) {
      return errorResponse('Search query is required');
    }

    final results = attractions.where((a) {
      final name = (a['name'] as String).toLowerCase();
      final location = (a['location'] as String).toLowerCase();
      final description = (a['description'] as String).toLowerCase();
      return name.contains(query) ||
          location.contains(query) ||
          description.contains(query);
    }).toList();

    return successResponse(results);
  });

  // Accommodations endpoints
  router.get('/api/accommodations', (Request request) {
    return successResponse(accommodations);
  });

  router.get('/api/accommodations/<id>', (Request request) {
    final id = int.tryParse(request.params['id'] ?? '');
    if (id == null) {
      return errorResponse('Invalid accommodation ID');
    }

    final accommodation = accommodations.firstWhere(
      (a) => a['id'] == id,
      orElse: () => {},
    );

    if (accommodation.isEmpty) {
      return errorResponse('Accommodation not found', statusCode: 404);
    }

    return successResponse(accommodation);
  });

  router.get('/api/accommodations/search', (Request request) {
    final query = request.url.queryParameters['q']?.toLowerCase();
    if (query == null || query.isEmpty) {
      return errorResponse('Search query is required');
    }

    final results = accommodations.where((a) {
      final name = (a['name'] as String).toLowerCase();
      final location = (a['location'] as String).toLowerCase();
      final description = (a['description'] as String).toLowerCase();
      return name.contains(query) ||
          location.contains(query) ||
          description.contains(query);
    }).toList();

    return successResponse(results);
  });

  // Filter accommodations by type
  router.get('/api/accommodations/filter', (Request request) {
    final type = request.url.queryParameters['type'];
    final location = request.url.queryParameters['location'];
    final minPrice =
        double.tryParse(request.url.queryParameters['min_price'] ?? '');
    final maxPrice =
        double.tryParse(request.url.queryParameters['max_price'] ?? '');

    var filtered = accommodations.toList();

    if (type != null && type.isNotEmpty) {
      filtered = filtered.where((a) => a['type'] == type).toList();
    }

    if (location != null && location.isNotEmpty) {
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

    return successResponse(filtered);
  });

  // Auth endpoints (mock)
  router.post('/api/auth/login', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      // Mock authentication - in real app, validate against database
      if (data['email'] == 'test@example.com' &&
          data['password'] == 'password') {
        return successResponse({
          'token': 'mock_jwt_token_123456789',
          'user': {
            'id': 1,
            'name': 'Test User',
            'email': 'test@example.com',
            'phone': '+260123456789',
            'profile_picture': null,
            'date_of_birth': null,
            'nationality': 'Zambian',
            'preferences': null,
            'is_verified': true,
            'created_at': '2024-01-01T00:00:00Z',
            'updated_at': '2024-01-01T00:00:00Z',
          }
        });
      } else {
        return errorResponse('Invalid credentials', statusCode: 401);
      }
    } catch (e) {
      return errorResponse('Invalid request body');
    }
  });

  router.post('/api/auth/register', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      // Mock registration
      return successResponse({
        'token': 'mock_jwt_token_123456789',
        'user': {
          'id': 2,
          'name': data['name'],
          'email': data['email'],
          'phone': data['phone'],
          'profile_picture': null,
          'date_of_birth': null,
          'nationality': null,
          'preferences': null,
          'is_verified': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }
      });
    } catch (e) {
      return errorResponse('Invalid request body');
    }
  });

  // Bookings endpoint (mock)
  router.post('/api/bookings', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      // Mock booking creation
      return successResponse({
        'id': 1,
        'user_id': 1,
        'item_id': data['item_id'],
        'type': data['type'],
        'check_in_date': data['check_in_date'],
        'check_out_date': data['check_out_date'],
        'adult_count': data['adult_count'],
        'child_count': data['child_count'],
        'total_price': 100.0,
        'status': 'confirmed',
        'customer_name': data['customer_name'],
        'customer_email': data['customer_email'],
        'customer_phone': data['customer_phone'],
        'special_requests': data['special_requests'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return errorResponse('Invalid request body');
    }
  });

  // Catch-all for unmatched routes
  router.all('/<ignored|.*>', (Request request) {
    return errorResponse('Route not found', statusCode: 404);
  });

  // Configure a pipeline that logs requests.
  final server = await serve(handler, ip, 8080);
  print('Server listening on port ${server.port}');
  print('API available at: http://localhost:8080/api');
  print('Health check: http://localhost:8080/health');
}
