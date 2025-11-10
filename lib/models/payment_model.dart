import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded
}

enum PaymentMethod {
  mtnMomo,
  airtelMoney
}

class PaymentModel {
  final String id;
  final String orderId;
  final String payerId;
  final String payeeId;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final String? transactionId;
  final String? externalTransactionId;
  final String? phoneNumber;
  final Map<String, dynamic>? paymentDetails;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;
  final String? webhookData;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.payerId,
    required this.payeeId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    this.externalTransactionId,
    this.phoneNumber,
    this.paymentDetails,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
    this.webhookData,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'payerId': payerId,
      'payeeId': payeeId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod.toString(),
      'status': status.toString(),
      'transactionId': transactionId,
      'externalTransactionId': externalTransactionId,
      'phoneNumber': phoneNumber,
      'paymentDetails': paymentDetails,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failureReason': failureReason,
      'webhookData': webhookData,
    };
  }

  // Create from Firestore document
  factory PaymentModel.fromMap(String id, Map<String, dynamic> data) {
    return PaymentModel(
      id: id,
      orderId: data['orderId'] ?? '',
      payerId: data['payerId'] ?? '',
      payeeId: data['payeeId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'RWF',
      paymentMethod: _parsePaymentMethod(data['paymentMethod'] ?? ''),
      status: _parsePaymentStatus(data['status'] ?? ''),
      transactionId: data['transactionId'],
      externalTransactionId: data['externalTransactionId'],
      phoneNumber: data['phoneNumber'],
      paymentDetails: data['paymentDetails'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      failureReason: data['failureReason'],
      webhookData: data['webhookData'],
    );
  }

  static PaymentMethod _parsePaymentMethod(String value) {
    switch (value) {
      case 'PaymentMethod.mtnMomo':
        return PaymentMethod.mtnMomo;
      case 'PaymentMethod.airtelMoney':
        return PaymentMethod.airtelMoney;
      default:
        return PaymentMethod.mtnMomo;
    }
  }

  static PaymentStatus _parsePaymentStatus(String value) {
    switch (value) {
      case 'PaymentStatus.pending':
        return PaymentStatus.pending;
      case 'PaymentStatus.processing':
        return PaymentStatus.processing;
      case 'PaymentStatus.completed':
        return PaymentStatus.completed;
      case 'PaymentStatus.failed':
        return PaymentStatus.failed;
      case 'PaymentStatus.cancelled':
        return PaymentStatus.cancelled;
      case 'PaymentStatus.refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  // Helper methods
  bool get isCompleted => status == PaymentStatus.completed;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isPending => status == PaymentStatus.pending;

  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case PaymentMethod.mtnMomo:
        return 'MTN MoMo';
      case PaymentMethod.airtelMoney:
        return 'Airtel Money';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

// Payment Configuration Model
class PaymentConfig {
  final String apiKey;
  final String apiSecret;
  final String baseUrl;
  final String callbackUrl;
  final String collectionAccount;
  final String currency;

  const PaymentConfig({
    required this.apiKey,
    required this.apiSecret,
    required this.baseUrl,
    required this.callbackUrl,
    required this.collectionAccount,
    required this.currency,
  });
}

// Payment Request/Response Models
class PaymentRequest {
  final String phoneNumber;
  final double amount;
  final String currency;
  final String reference;
  final String description;

  const PaymentRequest({
    required this.phoneNumber,
    required this.amount,
    required this.currency,
    required this.reference,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'amount': amount.toString(),
      'currency': currency,
      'reference': reference,
      'description': description,
    };
  }
}

class PaymentResponse {
  final bool success;
  final String? transactionId;
  final String? message;
  final Map<String, dynamic>? rawResponse;

  const PaymentResponse({
    required this.success,
    this.transactionId,
    this.message,
    this.rawResponse,
  });

  factory PaymentResponse.success(String transactionId, [Map<String, dynamic>? rawResponse]) {
    return PaymentResponse(
      success: true,
      transactionId: transactionId,
      rawResponse: rawResponse,
    );
  }

  factory PaymentResponse.failure(String message, [Map<String, dynamic>? rawResponse]) {
    return PaymentResponse(
      success: false,
      message: message,
      rawResponse: rawResponse,
    );
  }
}
