// lib/routes/auth_routes.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'dart:io';
import '../database/database_connection.dart';
import '../models/user.dart';
import '../utils/response_helper.dart';

class AuthRoutes {
  Router get router {
    final router = Router();

    // POST /api/auth/register - Register new user
    router.post('/register', _register);

    // POST /api/auth/login - Login user
    router.post('/login', _login);

    // GET /api/auth/user - Get current user (requires auth)
    router.get('/user', _getCurrentUser);

    // POST /api/auth/logout - Logout user
    router.post('/logout', _logout);

    return router;
  }

  Future<Response> _register(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      final email = data['email'] as String?;
      final password = data['password'] as String?;
      final phone = data['phone'] as String?;

      if (name == null || email == null || password == null) {
        return ResponseHelper.badRequest(
            message: 'Name, email, and password are required');
      }

      // Check if user already exists
      final existingUser = await DatabaseConnection.query(
          'SELECT id FROM users WHERE email = ?', [email]);

      if (existingUser != null && existingUser.isNotEmpty) {
        return ResponseHelper.badRequest(message: 'Email already registered');
      }

      // Hash password
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // Insert new user
      final result = await DatabaseConnection.query('''
        INSERT INTO users (name, email, password, phone, created_at, updated_at)
        VALUES (?, ?, ?, ?, NOW(), NOW())
      ''', [name, email, hashedPassword, phone]);

      if (result == null || result.insertId == null) {
        return ResponseHelper.error(message: 'Failed to create user account');
      }

      final userId = result.insertId!;

      // Generate JWT token
      final jwt = JWT({
        'user_id': userId,
        'email': email,
        'exp': DateTime.now()
                .add(const Duration(days: 7))
                .millisecondsSinceEpoch ~/
            1000,
      });

      final token = jwt.sign(
          SecretKey(Platform.environment['JWT_SECRET'] ?? 'default_secret'));

      // Get user data
      final userData = await DatabaseConnection.query(
          'SELECT * FROM users WHERE id = ?', [userId]);

      if (userData == null || userData.isEmpty) {
        return ResponseHelper.error(message: 'Failed to retrieve user data');
      }

      final user = User.fromDatabase(userData.first);

      return ResponseHelper.created(data: {
        'user': user.toJson(),
        'token': token,
      });
    } catch (e) {
      print('❌ Registration error: $e');
      return ResponseHelper.error(message: 'Registration failed: $e');
    }
  }

  Future<Response> _login(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final email = data['email'] as String?;
      final password = data['password'] as String?;

      if (email == null || password == null) {
        return ResponseHelper.badRequest(
            message: 'Email and password are required');
      }

      // Find user by email
      final results = await DatabaseConnection.query(
          'SELECT * FROM users WHERE email = ?', [email]);

      if (results == null || results.isEmpty) {
        return ResponseHelper.unauthorized(message: 'Invalid credentials');
      }

      final userData = results.first;
      final storedPassword = userData['password'] as String?;

      if (storedPassword == null) {
        return ResponseHelper.unauthorized(message: 'Invalid credentials');
      }

      // Verify password
      if (!BCrypt.checkpw(password, storedPassword)) {
        return ResponseHelper.unauthorized(message: 'Invalid credentials');
      }

      // Generate JWT token
      final jwt = JWT({
        'user_id': userData['id'],
        'email': email,
        'exp': DateTime.now()
                .add(const Duration(days: 7))
                .millisecondsSinceEpoch ~/
            1000,
      });

      final token = jwt.sign(
          SecretKey(Platform.environment['JWT_SECRET'] ?? 'default_secret'));

      final user = User.fromDatabase(userData);

      return ResponseHelper.success(data: {
        'user': user.toJson(),
        'token': token,
      });
    } catch (e) {
      print('❌ Login error: $e');
      return ResponseHelper.error(message: 'Login failed: $e');
    }
  }

  Future<Response> _getCurrentUser(Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return ResponseHelper.unauthorized(message: 'No token provided');
      }

      final token = authHeader.substring(7);

      try {
        final jwt = JWT.verify(token,
            SecretKey(Platform.environment['JWT_SECRET'] ?? 'default_secret'));
        final userId = jwt.payload['user_id'];

        final results = await DatabaseConnection.query(
            'SELECT * FROM users WHERE id = ?', [userId]);

        if (results == null || results.isEmpty) {
          return ResponseHelper.unauthorized(message: 'Invalid token');
        }

        final user = User.fromDatabase(results.first);
        return ResponseHelper.success(data: user.toJson());
      } catch (e) {
        print('❌ Token verification error: $e');
        return ResponseHelper.unauthorized(message: 'Invalid token');
      }
    } catch (e) {
      print('❌ Get current user error: $e');
      return ResponseHelper.error(message: 'Failed to get user: $e');
    }
  }

  Future<Response> _logout(Request request) async {
    try {
      // In a real app, you might want to blacklist the token
      // For now, just return success
      return ResponseHelper.success(message: 'Logged out successfully');
    } catch (e) {
      print('❌ Logout error: $e');
      return ResponseHelper.error(message: 'Logout failed: $e');
    }
  }
}
