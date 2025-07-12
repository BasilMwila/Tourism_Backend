// lib/routes/booking_routes.dart
// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database_connection.dart';
import '../models/booking.dart';
import '../utils/response_helper.dart';

class BookingRoutes {
  Router get router {
    final router = Router();

    // POST /api/bookings - Create new booking
    router.post('/', _createBooking);

    // GET /api/bookings/user - Get user bookings (requires auth)
    router.get('/user', _getUserBookings);

    // GET /api/bookings/<id> - Get booking by ID
    router.get('/<id>', _getBookingById);

    // PUT /api/bookings/<id>/status - Update booking status
    router.put('/<id>/status', _updateBookingStatus);

    // DELETE /api/bookings/<id> - Cancel booking
    router.delete('/<id>', _cancelBooking);

    return router;
  }

  Future<Response> _createBooking(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final itemId = data['item_id'] as int?;
      final type = data['type'] as String?;
      final checkInDate = data['check_in_date'] as String?;
      final checkOutDate = data['check_out_date'] as String?;
      final adultCount = data['adult_count'] as int?;
      final childCount = data['child_count'] as int?;
      final customerName = data['customer_name'] as String?;
      final customerEmail = data['customer_email'] as String?;
      final customerPhone = data['customer_phone'] as String?;
      final specialRequests = data['special_requests'] as String?;

      if (itemId == null ||
          type == null ||
          checkInDate == null ||
          checkOutDate == null ||
          adultCount == null ||
          childCount == null ||
          customerName == null ||
          customerEmail == null ||
          customerPhone == null) {
        return ResponseHelper.badRequest(message: 'Missing required fields');
      }

      print('🔍 Creating booking for item $itemId of type $type');

      // Calculate total price based on item type
      double basePrice = 50.0; // Default price if item not found

      try {
        if (type == 'attraction') {
          final priceResult = await DatabaseConnection.query(
              'SELECT price FROM attractions WHERE id = ?', [itemId]);
          if (priceResult != null && priceResult.isNotEmpty) {
            basePrice = (priceResult.first['price'] as num).toDouble();
            print('✅ Found attraction price: \$${basePrice}');
          }
        } else if (type == 'accommodation') {
          final priceResult = await DatabaseConnection.query(
              'SELECT price FROM accommodations WHERE id = ?', [itemId]);
          if (priceResult != null && priceResult.isNotEmpty) {
            basePrice = (priceResult.first['price'] as num).toDouble();
            print('✅ Found accommodation price: \$${basePrice}');
          }
        }
      } catch (e) {
        print('⚠️  Could not fetch price, using default: $e');
      }

      final checkIn = DateTime.parse(checkInDate);
      final checkOut = DateTime.parse(checkOutDate);
      final days = checkOut.difference(checkIn).inDays;
      final totalPrice = (basePrice * adultCount * days) +
          (basePrice * 0.5 * childCount * days);

      print('💰 Calculated total price: \$${totalPrice} for $days days');

      // Insert booking without user_id (make it nullable)
      final result = await DatabaseConnection.query('''
        INSERT INTO bookings (
          item_id, type, check_in_date, check_out_date, adult_count, child_count,
          total_price, status, customer_name, customer_email, customer_phone,
          special_requests, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?, ?, NOW(), NOW())
      ''', [
        itemId,
        type,
        checkInDate,
        checkOutDate,
        adultCount,
        childCount,
        totalPrice,
        customerName,
        customerEmail,
        customerPhone,
        specialRequests
      ]);

      if (result == null) {
        print('❌ Insert query returned null');
        return ResponseHelper.error(message: 'Database insert failed');
      }

      if (result.insertId == null) {
        print('❌ Insert ID is null');
        return ResponseHelper.error(message: 'Failed to get booking ID');
      }

      final bookingId = result.insertId!;
      print('✅ Created booking with ID: $bookingId');

      // Get the created booking
      final bookingData = await DatabaseConnection.query(
          'SELECT * FROM bookings WHERE id = ?', [bookingId]);

      if (bookingData == null || bookingData.isEmpty) {
        print('❌ Could not retrieve created booking');
        return ResponseHelper.error(
            message: 'Failed to retrieve created booking');
      }

      final booking = Booking.fromDatabase(bookingData.first);
      return ResponseHelper.created(data: booking.toJson());
    } catch (e) {
      print('❌ Error creating booking: $e');
      // Return a more specific error message
      if (e.toString().contains('Date')) {
        return ResponseHelper.error(
            message: 'Invalid date format. Use YYYY-MM-DD');
      }
      return ResponseHelper.error(
          message: 'Failed to create booking: ${e.toString()}');
    }
  }

  Future<Response> _getUserBookings(Request request) async {
    try {
      // In a real app, you'd extract user ID from JWT token
      // For now, we'll get all bookings or filter by email
      final email = request.url.queryParameters['email'];

      String sql = 'SELECT * FROM bookings';
      List<dynamic> params = [];

      if (email != null) {
        sql += ' WHERE customer_email = ?';
        params.add(email);
      }

      sql += ' ORDER BY created_at DESC';

      final results = await DatabaseConnection.query(sql, params);

      if (results == null) {
        return ResponseHelper.success(data: []);
      }

      final bookings = results
          .map((row) {
            try {
              return Booking.fromDatabase(row).toJson();
            } catch (e) {
              print('❌ Error processing booking row: $e');
              return null;
            }
          })
          .where((booking) => booking != null)
          .toList();

      return ResponseHelper.success(data: bookings);
    } catch (e) {
      print('❌ Error fetching user bookings: $e');
      return ResponseHelper.error(message: 'Failed to fetch bookings: $e');
    }
  }

  Future<Response> _getBookingById(Request request) async {
    try {
      final id = int.tryParse(request.params['id'] ?? '');
      if (id == null) {
        return ResponseHelper.badRequest(message: 'Invalid booking ID');
      }

      final results = await DatabaseConnection.query(
          'SELECT * FROM bookings WHERE id = ?', [id]);

      if (results == null || results.isEmpty) {
        return ResponseHelper.notFound(message: 'Booking not found');
      }

      final booking = Booking.fromDatabase(results.first);
      return ResponseHelper.success(data: booking.toJson());
    } catch (e) {
      print('❌ Error fetching booking: $e');
      return ResponseHelper.error(message: 'Failed to fetch booking: $e');
    }
  }

  Future<Response> _updateBookingStatus(Request request) async {
    try {
      final id = int.tryParse(request.params['id'] ?? '');
      if (id == null) {
        return ResponseHelper.badRequest(message: 'Invalid booking ID');
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status == null) {
        return ResponseHelper.badRequest(message: 'Status is required');
      }

      final updateResult = await DatabaseConnection.query(
          'UPDATE bookings SET status = ?, updated_at = NOW() WHERE id = ?',
          [status, id]);

      if (updateResult == null) {
        return ResponseHelper.error(message: 'Failed to update booking status');
      }

      final results = await DatabaseConnection.query(
          'SELECT * FROM bookings WHERE id = ?', [id]);

      if (results == null || results.isEmpty) {
        return ResponseHelper.notFound(message: 'Booking not found');
      }

      final booking = Booking.fromDatabase(results.first);
      return ResponseHelper.success(data: booking.toJson());
    } catch (e) {
      print('❌ Error updating booking status: $e');
      return ResponseHelper.error(message: 'Failed to update booking: $e');
    }
  }

  Future<Response> _cancelBooking(Request request) async {
    try {
      final id = int.tryParse(request.params['id'] ?? '');
      if (id == null) {
        return ResponseHelper.badRequest(message: 'Invalid booking ID');
      }

      final result = await DatabaseConnection.query(
          'UPDATE bookings SET status = "cancelled", updated_at = NOW() WHERE id = ?',
          [id]);

      if (result == null) {
        return ResponseHelper.error(message: 'Failed to cancel booking');
      }

      return ResponseHelper.success(message: 'Booking cancelled successfully');
    } catch (e) {
      print('❌ Error cancelling booking: $e');
      return ResponseHelper.error(message: 'Failed to cancel booking: $e');
    }
  }
}
