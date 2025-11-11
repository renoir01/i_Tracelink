import 'package:cloud_firestore/cloud_firestore.dart';

class SeedBatchModel {
  final String id;
  final String producerId;
  final String batchNumber;
  final String variety;
  final double quantity;
  final String qualityGrade;
  final DateTime productionDate;
  final DateTime expiryDate;
  final String certificationNumber;
  final String status; // active, expired, depleted
  final DateTime createdAt;
  final double? ironContent; // Iron content in mg per 100g (optional)

  SeedBatchModel({
    required this.id,
    required this.producerId,
    required this.batchNumber,
    required this.variety,
    required this.quantity,
    required this.qualityGrade,
    required this.productionDate,
    required this.expiryDate,
    required this.certificationNumber,
    required this.status,
    required this.createdAt,
    this.ironContent,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'producerId': producerId,
      'batchNumber': batchNumber,
      'variety': variety,
      'quantity': quantity,
      'qualityGrade': qualityGrade,
      'productionDate': Timestamp.fromDate(productionDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'certificationNumber': certificationNumber,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'ironContent': ironContent,
    };
  }

  // Create from Firestore document
  factory SeedBatchModel.fromMap(String id, Map<String, dynamic> data) {
    return SeedBatchModel(
      id: id,
      producerId: data['producerId'] ?? '',
      batchNumber: data['batchNumber'] ?? '',
      variety: data['variety'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      qualityGrade: data['qualityGrade'] ?? 'Grade A',
      productionDate: (data['productionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 365)),
      certificationNumber: data['certificationNumber'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ironContent: data['ironContent']?.toDouble(),
    );
  }

  // Create from Firestore DocumentSnapshot
  factory SeedBatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SeedBatchModel.fromMap(doc.id, data);
  }

  // Create a copy with updated fields
  SeedBatchModel copyWith({
    String? id,
    String? producerId,
    String? batchNumber,
    String? variety,
    double? quantity,
    String? qualityGrade,
    DateTime? productionDate,
    DateTime? expiryDate,
    String? certificationNumber,
    String? status,
    DateTime? createdAt,
    double? ironContent,
  }) {
    return SeedBatchModel(
      id: id ?? this.id,
      producerId: producerId ?? this.producerId,
      batchNumber: batchNumber ?? this.batchNumber,
      variety: variety ?? this.variety,
      quantity: quantity ?? this.quantity,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      productionDate: productionDate ?? this.productionDate,
      expiryDate: expiryDate ?? this.expiryDate,
      certificationNumber: certificationNumber ?? this.certificationNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      ironContent: ironContent ?? this.ironContent,
    );
  }

  // Check if batch is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  // Check if batch is expiring soon (within 30 days)
  bool get isExpiringSoon => expiryDate.difference(DateTime.now()).inDays <= 30;

  // Check if stock is low (less than 100kg)
  bool get isLowStock => quantity < 100;

  // Get remaining shelf life in days
  int get remainingShelfLife => expiryDate.difference(DateTime.now()).inDays;

  @override
  String toString() {
    return 'SeedBatchModel(id: $id, batchNumber: $batchNumber, variety: $variety, quantity: $quantity kg)';
  }
}
