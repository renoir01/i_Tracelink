import 'package:cloud_firestore/cloud_firestore.dart';

class AgroDealerSaleModel {
  final String id;
  final String agroDealerId;
  final String seedVariety;
  final double quantity; // kg
  final double pricePerKg;
  final double totalAmount;
  final String customerId; // Farmer/Cooperative ID
  final String customerName;
  final String customerType; // farmer, cooperative
  final DateTime saleDate;
  final String paymentStatus; // completed, pending
  final String? paymentMethod; // cash, mobile_money, credit
  final String? certificationNumber;
  final double ironContent;
  final String quality; // certified, foundation, commercial
  final String? batchNumber;
  final Map<String, dynamic>? location;
  final String? notes;
  final String? receiptNumber;

  AgroDealerSaleModel({
    required this.id,
    required this.agroDealerId,
    required this.seedVariety,
    required this.quantity,
    required this.pricePerKg,
    required this.totalAmount,
    required this.customerId,
    required this.customerName,
    required this.customerType,
    required this.saleDate,
    this.paymentStatus = 'completed',
    this.paymentMethod,
    this.certificationNumber,
    this.ironContent = 80.0,
    this.quality = 'certified',
    this.batchNumber,
    this.location,
    this.notes,
    this.receiptNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'agroDealerId': agroDealerId,
      'seedVariety': seedVariety,
      'quantity': quantity,
      'pricePerKg': pricePerKg,
      'totalAmount': totalAmount,
      'customerId': customerId,
      'customerName': customerName,
      'customerType': customerType,
      'saleDate': Timestamp.fromDate(saleDate),
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'certificationNumber': certificationNumber,
      'ironContent': ironContent,
      'quality': quality,
      'batchNumber': batchNumber,
      'location': location,
      'notes': notes,
      'receiptNumber': receiptNumber,
    };
  }

  factory AgroDealerSaleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgroDealerSaleModel(
      id: doc.id,
      agroDealerId: data['agroDealerId'] ?? '',
      seedVariety: data['seedVariety'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      pricePerKg: (data['pricePerKg'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerType: data['customerType'] ?? 'farmer',
      saleDate: (data['saleDate'] as Timestamp).toDate(),
      paymentStatus: data['paymentStatus'] ?? 'completed',
      paymentMethod: data['paymentMethod'],
      certificationNumber: data['certificationNumber'],
      ironContent: (data['ironContent'] ?? 80.0).toDouble(),
      quality: data['quality'] ?? 'certified',
      batchNumber: data['batchNumber'],
      location: data['location'],
      notes: data['notes'],
      receiptNumber: data['receiptNumber'],
    );
  }
}
