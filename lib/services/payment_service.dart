import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../utils/constants.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // Payment Configurations
  late final PaymentConfig _mtnConfig;
  late final PaymentConfig _airtelConfig;
  
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize configurations from environment variables
  void initialize() {
    _mtnConfig = PaymentConfig(
      apiKey: dotenv.env['MTN_MOMO_API_KEY'] ?? '',
      apiSecret: dotenv.env['MTN_MOMO_API_SECRET'] ?? '',
      baseUrl: dotenv.env['MTN_MOMO_BASE_URL'] ?? 'https://sandbox.momodeveloper.mtn.com',
      callbackUrl: dotenv.env['MTN_MOMO_CALLBACK_URL'] ??
      'https://itracelink.web.app/api/payments/mtn/callback',
      collectionAccount: dotenv.env['MTN_COLLECTION_ACCOUNT'] ?? '',
      currency: 'EUR', // MTN uses EUR in sandbox
    );

    _airtelConfig = PaymentConfig(
      apiKey: dotenv.env['AIRTEL_API_KEY'] ?? '',
      apiSecret: dotenv.env['AIRTEL_API_SECRET'] ?? '',
      baseUrl: dotenv.env['AIRTEL_BASE_URL'] ?? 'https://openapiuat.airtel.africa',
      callbackUrl: dotenv.env['AIRTEL_CALLBACK_URL'] ??
      'https://itracelink.web.app/api/payments/airtel/callback',
      collectionAccount: dotenv.env['AIRTEL_COLLECTION_ACCOUNT'] ?? '',
      currency: 'RWF',
    );
  }

  // Get access token for MTN MoMo
  Future<String?> _getMtnAccessToken() async {
    try {
      final credentials = base64Encode(utf8.encode('${_mtnConfig.apiKey}:${_mtnConfig.apiSecret}'));

      final response = await http.post(
        Uri.parse('${_mtnConfig.baseUrl}/collection/token/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': _mtnConfig.apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      }
    } catch (e) {
      print('MTN Token Error: $e');
    }
    return null;
  }

  // Get access token for Airtel Money
  Future<String?> _getAirtelAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse('${_airtelConfig.baseUrl}/auth/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': _airtelConfig.apiKey,
          'client_secret': _airtelConfig.apiSecret,
          'grant_type': 'client_credentials',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      }
    } catch (e) {
      print('Airtel Token Error: $e');
    }
    return null;
  }

  // Request payment from MTN MoMo
  Future<PaymentResponse> requestMtnPayment(PaymentRequest request) async {
    try {
      final token = await _getMtnAccessToken();
      if (token == null) {
        return PaymentResponse.failure('Failed to get access token');
      }

      final response = await http.post(
        Uri.parse('${_mtnConfig.baseUrl}/collection/v1_0/requesttopay'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Reference-Id': request.reference,
          'X-Target-Environment': 'sandbox',
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': _mtnConfig.apiKey,
        },
        body: jsonEncode({
          'amount': request.amount.toStringAsFixed(2),
          'currency': request.currency,
          'externalId': request.reference,
          'payer': {
            'partyIdType': 'MSISDN',
            'partyId': request.phoneNumber,
          },
          'payerMessage': request.description,
          'payeeNote': 'iTraceLink Payment',
        }),
      );

      if (response.statusCode == 202) {
        return PaymentResponse.success(request.reference);
      } else {
        final errorData = jsonDecode(response.body);
        return PaymentResponse.failure(
          errorData['message'] ?? 'Payment request failed',
          errorData,
        );
      }
    } catch (e) {
      return PaymentResponse.failure('Network error: $e');
    }
  }

  // Request payment from Airtel Money
  Future<PaymentResponse> requestAirtelPayment(PaymentRequest request) async {
    try {
      final token = await _getAirtelAccessToken();
      if (token == null) {
        return PaymentResponse.failure('Failed to get access token');
      }

      final response = await http.post(
        Uri.parse('${_airtelConfig.baseUrl}/merchant/v1/payments/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reference': request.reference,
          'subscriber': {
            'country': 'RW',
            'currency': request.currency,
            'msisdn': request.phoneNumber,
          },
          'transaction': {
            'amount': request.amount,
            'country': 'RW',
            'currency': request.currency,
            'id': request.reference,
          },
          'additional_info': {
            'narration': request.description,
            'callback_url': _airtelConfig.callbackUrl,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentResponse.success(
          data['transaction']?['id'] ?? request.reference,
          data,
        );
      } else {
        final errorData = jsonDecode(response.body);
        return PaymentResponse.failure(
          errorData['message'] ?? 'Payment request failed',
          errorData,
        );
      }
    } catch (e) {
      return PaymentResponse.failure('Network error: $e');
    }
  }

  // Check MTN MoMo payment status
  Future<PaymentStatus> checkMtnPaymentStatus(String transactionId) async {
    try {
      final token = await _getMtnAccessToken();
      if (token == null) return PaymentStatus.failed;

      final response = await http.get(
        Uri.parse('${_mtnConfig.baseUrl}/collection/v1_0/requesttopay/$transactionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Target-Environment': 'sandbox',
          'Ocp-Apim-Subscription-Key': _mtnConfig.apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];

        switch (status) {
          case 'SUCCESSFUL':
            return PaymentStatus.completed;
          case 'FAILED':
            return PaymentStatus.failed;
          case 'PENDING':
            return PaymentStatus.processing;
          default:
            return PaymentStatus.pending;
        }
      }
    } catch (e) {
      print('MTN Status Check Error: $e');
    }
    return PaymentStatus.failed;
  }

  // Check Airtel Money payment status
  Future<PaymentStatus> checkAirtelPaymentStatus(String transactionId) async {
    try {
      final token = await _getAirtelAccessToken();
      if (token == null) return PaymentStatus.failed;

      final response = await http.get(
        Uri.parse('${_airtelConfig.baseUrl}/merchant/v1/payments/$transactionId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['transaction']?['status'];

        switch (status) {
          case 'SUCCESS':
            return PaymentStatus.completed;
          case 'FAILED':
            return PaymentStatus.failed;
          case 'PENDING':
            return PaymentStatus.processing;
          default:
            return PaymentStatus.pending;
        }
      }
    } catch (e) {
      print('Airtel Status Check Error: $e');
    }
    return PaymentStatus.failed;
  }

  // Process payment request based on method
  Future<PaymentResponse> processPayment(PaymentMethod method, PaymentRequest request) async {
    switch (method) {
      case PaymentMethod.mtnMomo:
        return requestMtnPayment(request);
      case PaymentMethod.airtelMoney:
        return requestAirtelPayment(request);
    }
  }

  // Check payment status
  Future<PaymentStatus> checkPaymentStatus(PaymentMethod method, String transactionId) async {
    switch (method) {
      case PaymentMethod.mtnMomo:
        return checkMtnPaymentStatus(transactionId);
      case PaymentMethod.airtelMoney:
        return checkAirtelPaymentStatus(transactionId);
    }
  }

  // Validate phone number format
  bool isValidPhoneNumber(String phoneNumber, PaymentMethod method) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    switch (method) {
      case PaymentMethod.mtnMomo:
        // Rwanda MTN numbers start with 078, 079, 072
        return RegExp(r'^250(78|79|72)\d{7}$').hasMatch(cleanNumber) ||
               RegExp(r'^(078|079|072)\d{7}$').hasMatch(cleanNumber);
      case PaymentMethod.airtelMoney:
        // Rwanda Airtel/Tigo numbers start with 073, 078 (shared), 079 (shared)
        return RegExp(r'^250(73|78|79)\d{7}$').hasMatch(cleanNumber) ||
               RegExp(r'^(073|078|079)\d{7}$').hasMatch(cleanNumber);
    }
  }

  // Format phone number for API
  String formatPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If already international format, return as is
    if (cleanNumber.startsWith('250')) {
      return cleanNumber;
    }

    // Add Rwanda country code
    return '250$cleanNumber';
  }

  // Generate unique transaction reference
  String generateTransactionReference(String orderId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ITRACE_${orderId}_$timestamp';
  }

  // Validate payment amount
  bool isValidAmount(double amount) {
    return amount > 0 && amount <= 1000000; // Max 1M RWF
  }

  // ============= ENHANCED PAYMENT MANAGEMENT =============

  /// Create and process a complete payment transaction
  Future<PaymentResult> createAndProcessPayment({
    required String orderId,
    required String payerId,
    required String payeeId,
    required double amount,
    required String phoneNumber,
    required PaymentMethod paymentMethod,
    String? description,
  }) async {
    try {
      // 1. Validate inputs
      if (!isValidAmount(amount)) {
        return PaymentResult.error('Invalid payment amount');
      }

      if (!isValidPhoneNumber(phoneNumber, paymentMethod)) {
        return PaymentResult.error('Invalid phone number for selected method');
      }

      // 2. Generate reference
      final reference = generateTransactionReference(orderId);
      final formattedPhone = formatPhoneNumber(phoneNumber);

      // 3. Create payment record in Firestore
      final paymentDoc = await _firestore.collection('payments').add({
        'orderId': orderId,
        'payerId': payerId,
        'payeeId': payeeId,
        'amount': amount,
        'currency': 'RWF',
        'paymentMethod': paymentMethod.toString(),
        'status': PaymentStatus.pending.toString(),
        'phoneNumber': formattedPhone,
        'transactionId': reference,
        'createdAt': FieldValue.serverTimestamp(),
        'description': description ?? 'Order payment',
      });

      debugPrint('💳 Payment record created: ${paymentDoc.id}');

      // 4. Create payment request
      final request = PaymentRequest(
        phoneNumber: formattedPhone,
        amount: amount,
        currency: 'RWF',
        reference: reference,
        description: description ?? 'Order #$orderId payment',
      );

      // 5. Process payment
      final response = await processPayment(paymentMethod, request);

      if (response.success) {
        // Update to processing
        await paymentDoc.update({
          'status': PaymentStatus.processing.toString(),
          'externalTransactionId': response.transactionId,
        });

        debugPrint('✅ Payment initiated successfully: ${response.transactionId}');

        // Start status polling in background
        _pollPaymentStatus(paymentDoc.id, paymentMethod, response.transactionId!);

        return PaymentResult.success(
          paymentId: paymentDoc.id,
          transactionId: response.transactionId!,
        );
      } else {
        // Update as failed
        await paymentDoc.update({
          'status': PaymentStatus.failed.toString(),
          'failureReason': response.message,
        });

        debugPrint('❌ Payment failed: ${response.message}');

        return PaymentResult.error(response.message ?? 'Payment failed');
      }
    } catch (e) {
      debugPrint('💥 Payment error: $e');
      return PaymentResult.error('Payment error: $e');
    }
  }

  /// Poll payment status until completion or timeout
  Future<void> _pollPaymentStatus(
    String paymentId,
    PaymentMethod method,
    String transactionId,
  ) async {
    // Poll every 5 seconds for up to 2 minutes (24 attempts)
    for (int attempt = 0; attempt < 24; attempt++) {
      await Future.delayed(const Duration(seconds: 5));

      try {
        final status = await checkPaymentStatus(method, transactionId);

        if (status == PaymentStatus.completed) {
          await _firestore.collection('payments').doc(paymentId).update({
            'status': PaymentStatus.completed.toString(),
            'completedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ Payment completed: $paymentId');
          break;
        } else if (status == PaymentStatus.failed) {
          await _firestore.collection('payments').doc(paymentId).update({
            'status': PaymentStatus.failed.toString(),
            'failureReason': 'Payment verification failed',
          });
          debugPrint('❌ Payment failed: $paymentId');
          break;
        }

        debugPrint('⏳ Payment pending (attempt ${attempt + 1}/24): $paymentId');
      } catch (e) {
        debugPrint('⚠️ Status check error: $e');
      }
    }

    // If we reach here without completion, mark as timeout
    final doc = await _firestore.collection('payments').doc(paymentId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data?['status'] == PaymentStatus.processing.toString()) {
        await _firestore.collection('payments').doc(paymentId).update({
          'status': PaymentStatus.failed.toString(),
          'failureReason': 'Payment verification timeout',
        });
        debugPrint('⏱️ Payment timeout: $paymentId');
      }
    }
  }

  /// Get payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      if (doc.exists) {
        return PaymentModel.fromMap(doc.id, doc.data()!);
      }
    } catch (e) {
      debugPrint('Error getting payment: $e');
    }
    return null;
  }

  /// Get payments for an order
  Future<List<PaymentModel>> getPaymentsForOrder(String orderId) async {
    try {
      final query = await _firestore
          .collection('payments')
          .where('orderId', isEqualTo: orderId)
          .get();
      return query.docs
          .map((doc) => PaymentModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting payments for order: $e');
    }
    return [];
  }
}

class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? transactionId;
  final String? message;

  PaymentResult.success({
    required this.paymentId,
    required this.transactionId,
  })  : success = true,
        message = null;

  PaymentResult.error(this.message) : success = false, paymentId = null, transactionId = null;
}
