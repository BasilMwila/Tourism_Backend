// bin/server.dart
// ignore_for_file: implicit_call_tearoffs, avoid_relative_lib_imports, avoid_single_cascade_in_expression_statements

import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:dotenv/dotenv.dart';

import '../lib/database/database_connection.dart';
import '../lib/routes/attraction_routes.dart';
import '../lib/routes/accommodation_routes.dart';
import '../lib/routes/auth_routes.dart';
import '../lib/routes/booking_routes.dart';

void main(List<String> args) async {
  print('🚀 Starting Zambia Tourism API...');

  // Load environment variables
  DotEnv(includePlatformEnvironment: true)..load();
  print('✅ Environment variables loaded');

  // Initialize database connection
  await DatabaseConnection.initialize();

  // Configure router
  final router = Router();

  // CORS configuration
  final overrideHeaders = {
    ACCESS_CONTROL_ALLOW_ORIGIN: '*',
    ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, PUT, DELETE, OPTIONS',
    ACCESS_CONTROL_ALLOW_HEADERS: 'Origin, Content-Type, Authorization',
  };

  // Health check endpoint
  router.get('/health', (Request request) {
    return Response.ok('Zambia Tourism API is running!');
  });

  // API routes
  router.mount('/api/attractions', AttractionRoutes().router);
  router.mount('/api/accommodations', AccommodationRoutes().router);
  router.mount('/api/auth', AuthRoutes().router);
  router.mount('/api/bookings', BookingRoutes().router);

  // Add middleware
  final handler = Pipeline()
      .addMiddleware(corsHeaders(headers: overrideHeaders))
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // IMPORTANT: Bind to all interfaces (0.0.0.0) instead of localhost
  final ip = InternetAddress.anyIPv4; // This binds to 0.0.0.0
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
  } else {
    print('🌐 Network access: http://[YOUR_IP]:${server.port}');
  }
  print('🏥 Health check: http://localhost:${server.port}/health');
  print('📍 API Base URL: http://localhost:${server.port}/api');
  print('');
  print('📋 Available endpoints:');
  print('   GET    /api/attractions');
  print('   GET    /api/attractions/<id>');
  print('   GET    /api/attractions/search?q=<query>');
  print('   GET    /api/accommodations');
  print('   GET    /api/accommodations/<id>');
  print('   POST   /api/auth/register');
  print('   POST   /api/auth/login');
  print('   GET    /api/auth/user');
  print('   POST   /api/bookings');
  print('   GET    /api/bookings/user');
  print('');
  print('🔍 Testing network connectivity...');

  // Test database connection
  if (DatabaseConnection.isConnected) {
    print('✅ Database connection: OK');
  } else {
    print('⚠️  Database connection: Using fallback data');
  }

  print('Press Ctrl+C to stop the server');
}
