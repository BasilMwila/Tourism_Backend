// lib/models/booking.dart
import 'package:mysql1/mysql1.dart';

class Booking {
  final int id;
  final int itemId;
  final String type;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int adultCount;
  final int childCount;
  final double totalPrice;
  final String status;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String? specialRequests;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.itemId,
    required this.type,
    required this.checkInDate,
    required this.checkOutDate,
    required this.adultCount,
    required this.childCount,
    required this.totalPrice,
    required this.status,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.specialRequests,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromDatabase(ResultRow row) {
    return Booking(
      id: row['id'] as int,
      itemId: row['item_id'] as int,
      type: row['type'] as String,
      checkInDate: row['check_in_date'] as DateTime,
      checkOutDate: row['check_out_date'] as DateTime,
      adultCount: row['adult_count'] as int,
      childCount: row['child_count'] as int,
      totalPrice: (row['total_price'] as num).toDouble(),
      status: row['status'] as String,
      customerName: row['customer_name'] as String,
      customerEmail: row['customer_email'] as String,
      customerPhone: row['customer_phone'] as String,
      specialRequests: row['special_requests'] as String?,
      createdAt: row['created_at'] as DateTime,
      updatedAt: row['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'type': type,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'adult_count': adultCount,
      'child_count': childCount,
      'total_price': totalPrice,
      'status': status,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'special_requests': specialRequests,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get totalDays => checkOutDate.difference(checkInDate).inDays;
}
