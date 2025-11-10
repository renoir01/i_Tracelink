import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String type; // purchase, sale, direct_sale
  final String sellerId;
  final String sellerName;
  final String buyerId;
  final String buyerName;
  final String? batchId;
  final String batchNumber;
  final double quantity; // kg
  final double pricePerKg;
  final double totalAmount;
  final DateTime transactionDate;
  final String paymentStatus; // pending, completed, failed
  final String? paymentMethod; // cash, mobile_money, bank_transfer
  final String? receiptNumber;
  final Map<String, dynamic> location;
  final String status; // pending, confirmed, delivered, completed
  final String? notes;

  TransactionModel({
    required this.id,
    required this.type,
    required this.sellerId,
    required this.sellerName,
    required this.buyerId,
    required this.buyerName,
    this.batchId,
    required this.batchNumber,
    required this.quantity,
    required this.pricePerKg,
    required this.totalAmount,
    required this.transactionDate,
    this.paymentStatus = 'pending',
    this.paymentMethod,
    this.receiptNumber,
    required this.location,
    this.status = 'pending',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'batchId': batchId,
      'batchNumber': batchNumber,
      'quantity': quantity,
      'pricePerKg': pricePerKg,
      'totalAmount': totalAmount,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'receiptNumber': receiptNumber,
      'location': location,
      'status': status,
      'notes': notes,
    };
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      type: data['type'] ?? 'sale',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      batchId: data['batchId'],
      batchNumber: data['batchNumber'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      pricePerKg: (data['pricePerKg'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      transactionDate: (data['transactionDate'] as Timestamp).toDate(),
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentMethod: data['paymentMethod'],
      receiptNumber: data['receiptNumber'],
      location: data['location'] ?? {},
      status: data['status'] ?? 'pending',
      notes: data['notes'],
    );
  }
}
