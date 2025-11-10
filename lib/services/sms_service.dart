import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SMSService {
  static final SMSService _instance = SMSService._internal();
  factory SMSService() => _instance;
  SMSService._internal();

  final String _apiKey = dotenv.env['AFRICAS_TALKING_API_KEY'] ?? '';
  final String _username = dotenv.env['AFRICAS_TALKING_USERNAME'] ?? 'sandbox';
  final String _senderId = dotenv.env['AFRICAS_TALKING_SENDER_ID'] ?? 'AFRICASTKNG';
  
  final String _baseUrl = 'https://api.sandbox.africastalking.com/version1';

  // Generate 6-digit OTP
  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send SMS
  Future<bool> sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/messaging');
      
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
          'apiKey': _apiKey,
        },
        body: {
          'username': _username,
          'to': _formatPhoneNumber(phoneNumber),
          'message': message,
          'from': _senderId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('SMS sent successfully: ${data.toString()}');
        return true;
      } else {
        print('SMS failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('SMS error: $e');
      return false;
    }
  }

  // Format phone number to international format
  String _formatPhoneNumber(String phone) {
    // Remove spaces and special characters
    phone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If doesn't start with +, assume Rwanda (+250)
    if (!phone.startsWith('+')) {
      if (phone.startsWith('0')) {
        phone = '+250${phone.substring(1)}';
      } else if (phone.startsWith('250')) {
        phone = '+$phone';
      } else {
        phone = '+250$phone';
      }
    }
    
    return phone;
  }

  // ========== SMS TEMPLATES ==========

  // OTP Verification
  Future<bool> sendOTP(String phoneNumber, String otp) async {
    final message = 'Your iTraceLink verification code is: $otp. Valid for 10 minutes. Do not share this code.';
    return await sendSMS(phoneNumber: phoneNumber, message: message);
  }

  // Order Placed (to Farmer)
  Future<bool> sendOrderPlacedNotification({
    required String phoneNumber,
    required String aggregatorName,
    required double quantity,
    required double pricePerKg,
    required String deliveryDate,
  }) async {
    final message = 'New order from $aggregatorName: ${quantity.round()}kg @ ${pricePerKg.round()} RWF/kg. '
        'Delivery: $deliveryDate. Open iTraceLink app to respond.';
    return await sendSMS(phoneNumber: phoneNumber, message: message);
  }

  // Order Accepted (to Aggregator)
  Future<bool> sendOrderAcceptedNotification({
    required String phoneNumber,
    required String cooperativeName,
    required double quantity,
    required String deliveryDate,
  }) async {
    final message = '$cooperativeName accepted your order for ${quantity.round()}kg. '
        'Collection: $deliveryDate. Check iTraceLink for details.';
    return await sendSMS(phoneNumber: phoneNumber, message: message);
  }

  // Order Rejected (to Aggregator)
  Future<bool> sendOrderRejectedNotification({
    required String phoneNumber,
    required String cooperativeName,
    required double quantity,
  }) async {
    final message = '$cooperativeName declined your order for ${quantity.round()}kg. '
        'Try another cooperative on iTraceLink app.';
    return await sendSMS(phoneNumber: phoneNumber, message: message);
  }

  // Order Status Update
  Future<bool> sendOrderStatusUpdate({
    required String phoneNumber,
    required String orderId,
    required String newStatus,
  }) async {
    String statusText;
    switch (newStatus) {
      case 'collected':
        statusText = 'has been collected';
        break;
      case 'in_transit':
        statusText = 'is now in transit';
        break;
      case 'delivered':
        statusText = 'has been delivered';
        break;
      case 'completed':
        statusText = 'is completed';
        break;
      default:
        statusText = 'status updated to $newStatus';
    }
    
    final message = 'Order #${orderId.substring(0, 8)} $statusText. '
        'Track on iTraceLink app for details.';
    return await sendSMS(phoneNumber: phoneNumber, message: message);
  }

  // Payment Received
  Future<bool> sendPaymentConfirmation({
    required String phoneNumber,
    required double amount,
    required double quantity,
    required String transactionId,
  }) async {
    final message = 'Payment received: ${amount.round()} RWF for ${quantity.round()}kg beans. '
        'Transaction ID: ${transactionId.substring(0, 8)}. Thank you!';
    return await sendSMS(phoneNumber: phoneNumber, message: message);
  }

  // Harvest Reminder
  Future<bool> sendHarvestReminder({
    required String phoneNumber,
    required String cooperativeName,
    required String expectedDate,
  }) async {
    final message = 'Reminder: Expected harvest date for $cooperativeName is $expectedDate. '
        'Update harvest info on iTraceLink app when ready.';
    return await sendSMS(phoneNumber: phoneNumber, message: message);
  }

  // Account Verified
  Future<bool> sendAccountVerifiedNotification({
    required String phoneNumber,
    required String userName,
  }) async {
    final message = 'Welcome to iTraceLink, $userName! Your account has been verified. '
        'You now have full access to all features.';
    return await sendSMS(phoneNumber: phoneNumber, message: message);
  }

  // Generic Notification
  Future<bool> sendNotification({
    required String phoneNumber,
    required String title,
    required String body,
  }) async {
    final message = '$title: $body';
    return await sendSMS(phoneNumber: phoneNumber, message: message);
  }
}
