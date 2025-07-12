// lib/database/database_connection.dart
import 'package:mysql1/mysql1.dart';
import 'dart:io';

class DatabaseConnection {
  static MySqlConnection? _connection;
  static bool _isInitialized = false;

  static MySqlConnection get connection {
    if (_connection == null) {
      throw Exception(
          'Database not initialized. Call DatabaseConnection.initialize() first.');
    }
    return _connection!;
  }

  // Add the missing isConnected getter
  static bool get isConnected => _connection != null && _isInitialized;

  static Future<void> initialize() async {
    if (_isInitialized && _connection != null) return;

    try {
      final settings = ConnectionSettings(
        host: Platform.environment['DB_HOST'] ??
            'ls-ab91bdaf741ac46789f3e1084d92ae72d98ef346.c0vyackkg5lk.us-east-1.rds.amazonaws.com',
        port: int.parse(Platform.environment['DB_PORT'] ?? '3306'),
        user: Platform.environment['DB_USER'] ?? 'dbmasteruser',
        password: Platform.environment['DB_PASSWORD'] ??
            'eXon4kXY-B4sUm#H&^nIysYa#m,}V)nZ',
        db: Platform.environment['DB_NAME'] ?? 'zambia_tourism',
        timeout: const Duration(seconds: 30),
      );

      print(
          '🔗 Connecting to database: ${settings.host}:${settings.port}/${settings.db}');
      _connection = await MySqlConnection.connect(settings);
      _isInitialized = true;

      print('✅ Database connected successfully to AWS Lightsail');
      print('📍 Host: ${settings.host}');
      print('🗄️  Database: ${settings.db}');

      // Test the connection
      await _testConnection();
    } catch (e) {
      print('❌ Database connection failed: $e');
      print('Host: ${Platform.environment['DB_HOST']}');
      print('Database: ${Platform.environment['DB_NAME']}');
      print('⚠️  Server will continue with fallback data');
      // Don't throw - allow server to start with fallback data
      _isInitialized = false;
      _connection = null;
    }
  }

  static Future<void> _testConnection() async {
    try {
      if (_connection != null) {
        final result = await _connection!.query('SELECT 1 as test');
        if (result.isNotEmpty) {
          print('✅ Database connection test passed');
        }
      }
    } catch (e) {
      print('⚠️  Database test query failed: $e');
    }
  }

  static Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      _isInitialized = false;
      print('🔌 Database connection closed');
    }
  }

  // Helper method for executing queries with error handling and null safety
  static Future<Results?> query(String sql, [List<Object?>? values]) async {
    try {
      if (_connection == null || !_isInitialized) {
        print('⚠️  No database connection available');
        return null;
      }

      if (values != null && values.isNotEmpty) {
        return await _connection!.query(sql, values);
      } else {
        return await _connection!.query(sql);
      }
    } catch (e) {
      print('❌ Database query error: $e');
      print('🔍 SQL: $sql');
      if (values != null) print('📊 Values: $values');
      return null;
    }
  }

  // Helper method for executing prepared statements
  static Future<Results?> prepared(String sql, List<Object?> values) async {
    try {
      if (_connection == null || !_isInitialized) {
        print('⚠️  No database connection available');
        return null;
      }

      return await _connection!.query(sql, values);
    } catch (e) {
      print('❌ Database prepared statement error: $e');
      print('🔍 SQL: $sql');
      print('📊 Values: $values');
      return null;
    }
  }

  // Transaction support
  static Future<T?> transaction<T>(
      Future<T> Function(MySqlConnection) callback) async {
    if (_connection == null || !_isInitialized) {
      print('⚠️  No database connection available for transaction');
      return null;
    }

    try {
      await _connection!.query('START TRANSACTION');
      final result = await callback(_connection!);
      await _connection!.query('COMMIT');
      return result;
    } catch (e) {
      print('❌ Transaction error: $e');
      try {
        await _connection!.query('ROLLBACK');
      } catch (rollbackError) {
        print('❌ Rollback error: $rollbackError');
      }
      rethrow;
    }
  }
}
