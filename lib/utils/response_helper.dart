// lib/utils/response_helper.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';

class ResponseHelper {
  static Response success({
    dynamic data,
    String message = 'Success',
    int statusCode = 200,
  }) {
    final response = {
      'success': true,
      'message': message,
      'data': data,
    };

    return Response(
      statusCode,
      body: jsonEncode(response),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Response error({
    String message = 'An error occurred',
    dynamic error,
    int statusCode = 500,
  }) {
    final response = {
      'success': false,
      'message': message,
      'error': error,
    };

    return Response(
      statusCode,
      body: jsonEncode(response),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Response badRequest({String message = 'Bad Request'}) {
    return error(message: message, statusCode: 400);
  }

  static Response unauthorized({String message = 'Unauthorized'}) {
    return error(message: message, statusCode: 401);
  }

  static Response forbidden({String message = 'Forbidden'}) {
    return error(message: message, statusCode: 403);
  }

  static Response notFound({String message = 'Not Found'}) {
    return error(message: message, statusCode: 404);
  }

  static Response created({
    dynamic data,
    String message = 'Created successfully',
  }) {
    return success(data: data, message: message, statusCode: 201);
  }

  static Response noContent({String message = 'No Content'}) {
    return success(message: message, statusCode: 204);
  }
}
