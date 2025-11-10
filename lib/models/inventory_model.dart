import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel {
  final String id;
  final String traderId; // Aggregator user ID
  final String batchId;
  final String batchNumber;
  final String beanVariety;
  final double quantityAvailable; // kg
  final double quantityPurchased; // original amount
  final double quantitySold; // kg sold
  final double purchasePricePerKg;
  final double? sellingPricePerKg;
  final DateTime purchaseDate;
  final String supplierId; // Farmer/Cooperative ID
  final String supplierName;
  final String storageLocation;
  final String status; // in_stock, low_stock, out_of_stock, expired
  final String quality; // A, B, C
  final DateTime? expiryDate;
  final double ironContent;
  final String? notes;

  InventoryModel({
    required this.id,
    required this.traderId,
    required this.batchId,
    required this.batchNumber,
    required this.beanVariety,
    required this.quantityAvailable,
    required this.quantityPurchased,
    this.quantitySold = 0,
    required this.purchasePricePerKg,
    this.sellingPricePerKg,
    required this.purchaseDate,
    required this.supplierId,
    required this.supplierName,
    required this.storageLocation,
    this.status = 'in_stock',
    this.quality = 'A',
    this.expiryDate,
    this.ironContent = 80.0,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'traderId': traderId,
      'batchId': batchId,
      'batchNumber': batchNumber,
      'beanVariety': beanVariety,
      'quantityAvailable': quantityAvailable,
      'quantityPurchased': quantityPurchased,
      'quantitySold': quantitySold,
      'purchasePricePerKg': purchasePricePerKg,
      'sellingPricePerKg': sellingPricePerKg,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'supplierId': supplierId,
      'supplierName': supplierName,
      'storageLocation': storageLocation,
      'status': status,
      'quality': quality,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'ironContent': ironContent,
      'notes': notes,
    };
  }

  factory InventoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryModel(
      id: doc.id,
      traderId: data['traderId'] ?? '',
      batchId: data['batchId'] ?? '',
      batchNumber: data['batchNumber'] ?? '',
      beanVariety: data['beanVariety'] ?? '',
      quantityAvailable: (data['quantityAvailable'] ?? 0).toDouble(),
      quantityPurchased: (data['quantityPurchased'] ?? 0).toDouble(),
      quantitySold: (data['quantitySold'] ?? 0).toDouble(),
      purchasePricePerKg: (data['purchasePricePerKg'] ?? 0).toDouble(),
      sellingPricePerKg: data['sellingPricePerKg']?.toDouble(),
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      supplierId: data['supplierId'] ?? '',
      supplierName: data['supplierName'] ?? '',
      storageLocation: data['storageLocation'] ?? '',
      status: data['status'] ?? 'in_stock',
      quality: data['quality'] ?? 'A',
      expiryDate: data['expiryDate'] != null
          ? (data['expiryDate'] as Timestamp).toDate()
          : null,
      ironContent: (data['ironContent'] ?? 80.0).toDouble(),
      notes: data['notes'],
    );
  }

  InventoryModel copyWith({
    String? id,
    String? traderId,
    String? batchId,
    String? batchNumber,
    String? beanVariety,
    double? quantityAvailable,
    double? quantityPurchased,
    double? quantitySold,
    double? purchasePricePerKg,
    double? sellingPricePerKg,
    DateTime? purchaseDate,
    String? supplierId,
    String? supplierName,
    String? storageLocation,
    String? status,
    String? quality,
    DateTime? expiryDate,
    double? ironContent,
    String? notes,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      traderId: traderId ?? this.traderId,
      batchId: batchId ?? this.batchId,
      batchNumber: batchNumber ?? this.batchNumber,
      beanVariety: beanVariety ?? this.beanVariety,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      quantityPurchased: quantityPurchased ?? this.quantityPurchased,
      quantitySold: quantitySold ?? this.quantitySold,
      purchasePricePerKg: purchasePricePerKg ?? this.purchasePricePerKg,
      sellingPricePerKg: sellingPricePerKg ?? this.sellingPricePerKg,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      storageLocation: storageLocation ?? this.storageLocation,
      status: status ?? this.status,
      quality: quality ?? this.quality,
      expiryDate: expiryDate ?? this.expiryDate,
      ironContent: ironContent ?? this.ironContent,
      notes: notes ?? this.notes,
    );
  }

  double get profitMargin {
    if (sellingPricePerKg == null) return 0;
    return sellingPricePerKg! - purchasePricePerKg;
  }

  double get totalValue {
    return quantityAvailable * (sellingPricePerKg ?? purchasePricePerKg);
  }

  bool get isLowStock {
    return quantityAvailable < (quantityPurchased * 0.2); // Less than 20%
  }
}
