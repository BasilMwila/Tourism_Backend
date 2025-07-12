// lib/models/user.dart
import 'package:mysql1/mysql1.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? nationality;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.nationality,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromDatabase(ResultRow row) {
    return User(
      id: row['id'] as int,
      name: row['name'] as String,
      email: row['email'] as String,
      phone: row['phone'] as String?,
      dateOfBirth: row['date_of_birth'] as DateTime?,
      nationality: row['nationality'] as String?,
      isVerified: (row['is_verified'] as int?) == 1,
      createdAt: row['created_at'] as DateTime,
      updatedAt: row['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'nationality': nationality,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
