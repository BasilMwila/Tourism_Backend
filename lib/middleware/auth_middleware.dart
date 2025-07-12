// lib/middleware/auth_middleware.dart
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthMiddleware {
  static Middleware authRequired() {
    return (Handler innerHandler) {
      return (Request request) async {
        final authHeader = request.headers['authorization'];

        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return Response(401,
              body: jsonEncode(
                  {'success': false, 'message': 'No token provided'}),
              headers: {'Content-Type': 'application/json'});
        }

        final token = authHeader.substring(7);

        try {
          final jwt = JWT.verify(
              token,
              SecretKey(
                  Platform.environment['JWT_SECRET'] ?? 'default_secret'));

          // Add user info to request context if needed
          final updatedRequest = request.change(context: {
            'user_id': jwt.payload['user_id'],
            'email': jwt.payload['email'],
          });

          return await innerHandler(updatedRequest);
        } catch (e) {
          return Response(401,
              body: jsonEncode({'success': false, 'message': 'Invalid token'}),
              headers: {'Content-Type': 'application/json'});
        }
      };
    };
  }
}
