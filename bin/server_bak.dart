// bin/server.dart - FIXED STANDALONE VERSION
import 'dart:io';
import 'dart:convert';
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
  print('🚀 Starting Zambia Tourism API...');

  // CORS configuration
  final overrideHeaders = {
    ACCESS_CONTROL_ALLOW_ORIGIN: '*',
    ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, PUT, DELETE, OPTIONS',
    ACCESS_CONTROL_ALLOW_HEADERS: 'Origin, Content-Type, Authorization',
  };

  // Configure router
  final router = Router();

  // Health check endpoint
  router.get('/health', (Request request) {
    return Response.ok('Zambia Tourism API is running!');
  });

  // Root endpoint
  router.get('/', (Request request) {
    return Response.ok('Zambia Tourism Backend API is running!');
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

  // Auth endpoints (FIXED - Mock authentication)
  router.post('/api/auth/login', (Request request) async {
    try {
      print('📥 Login request received');
      final body = await request.readAsString();
      print('📤 Request body: $body');

      final data = jsonDecode(body);
      final email = data['email'];
      final password = data['password'];

      print('🔐 Login attempt for: $email');

      // Mock authentication - accept any email/password for demo
      if (email != null && password != null) {
        final responseData = {
          'token': 'mock_jwt_token_123456789',
          'user': {
            'id': 1,
            'name': 'Demo User',
            'email': email,
            'phone': '+260123456789',
            'profile_picture': null,
            'date_of_birth': null,
            'nationality': 'Zambian',
            'preferences': null,
            'is_verified': true,
            'created_at': '2024-01-01T00:00:00Z',
            'updated_at': '2024-01-01T00:00:00Z',
          }
        };

        print('✅ Login successful for: $email');
        return successResponse(responseData);
      } else {
        print('❌ Missing email or password');
        return errorResponse('Email and password are required',
            statusCode: 400);
      }
    } catch (e) {
      print('❌ Login error: $e');
      return errorResponse('Login failed: $e', statusCode: 500);
    }
  });

  router.post('/api/auth/register', (Request request) async {
    try {
      print('📥 Register request received');
      final body = await request.readAsString();
      print('📤 Request body: $body');

      final data = jsonDecode(body);
      final name = data['name'];
      final email = data['email'];
      final password = data['password'];
      final phone = data['phone'];

      print('👤 Registration attempt for: $email');

      if (name != null && email != null && password != null) {
        final responseData = {
          'token': 'mock_jwt_token_123456789',
          'user': {
            'id': 2,
            'name': name,
            'email': email,
            'phone': phone,
            'profile_picture': null,
            'date_of_birth': null,
            'nationality': null,
            'preferences': null,
            'is_verified': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }
        };

        print('✅ Registration successful for: $email');
        return successResponse(responseData);
      } else {
        print('❌ Missing required fields');
        return errorResponse('Name, email, and password are required',
            statusCode: 400);
      }
    } catch (e) {
      print('❌ Registration error: $e');
      return errorResponse('Registration failed: $e', statusCode: 500);
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

  // Add middleware
  final handler = Pipeline()
      .addMiddleware(corsHeaders(headers: overrideHeaders))
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // IMPORTANT: Bind to all interfaces (0.0.0.0) instead of localhost
  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);

  // Get the actual network IP address
  String? networkIP;
  try {
    final interfaces = await NetworkInterface.list();
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          networkIP = addr.address;
          break;
        }
      }
      if (networkIP != null) break;
    }
  } catch (e) {
    print('⚠️  Could not determine network IP: $e');
  }

  print('');
  print('🎉 Zambia Tourism API server is running!');
  print('🌐 Server bound to: 0.0.0.0:${server.port}');
  print('🌐 Local access: http://localhost:${server.port}');
  if (networkIP != null) {
    print('🌐 Network access: http://$networkIP:${server.port}');
    print('📱 For mobile device: http://$networkIP:${server.port}/api');
  }
  print('🏥 Health check: http://localhost:${server.port}/health');
  print('📍 API Base URL: http://localhost:${server.port}/api');
  print('');
  print('📋 Available endpoints:');
  print('   GET    /api/attractions');
  print('   GET    /api/accommodations');
  print('   POST   /api/auth/register');
  print('   POST   /api/auth/login');
  print('   POST   /api/bookings');
  print('');
  print('🟢 Server ready - Database not required for this version');
  print('Press Ctrl+C to stop the server');
}
