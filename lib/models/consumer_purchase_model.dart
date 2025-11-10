import 'package:cloud_firestore/cloud_firestore.dart';

class ConsumerPurchaseModel {
  final String id;
  final String consumerId;
  final String batchId;
  final String sellerId; // Farmer or Trader ID
  final String sellerName;
  final String sellerType; // 'farmer', 'trader'
  final DateTime scanDate;
  final DateTime? purchaseDate;
  final double? quantityPurchased; // kg
  final double? pricePerKg;
  final double? totalAmount;
  final String? purchaseLocation;
  final bool wasVerified; // true if product was authentic
  final int? rating; // 1-5 stars
  final String? review;
  final List<String> photos;
  final bool reportedFraud;
  final String? fraudDetails;

  ConsumerPurchaseModel({
    required this.id,
    required this.consumerId,
    required this.batchId,
    required this.sellerId,
    required this.sellerName,
    required this.sellerType,
    required this.scanDate,
    this.purchaseDate,
    this.quantityPurchased,
    this.pricePerKg,
    this.totalAmount,
    this.purchaseLocation,
    this.wasVerified = true,
    this.rating,
    this.review,
    this.photos = const [],
    this.reportedFraud = false,
    this.fraudDetails,
  });

  Map<String, dynamic> toMap() {
    return {
      'consumerId': consumerId,
      'batchId': batchId,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerType': sellerType,
      'scanDate': Timestamp.fromDate(scanDate),
      'purchaseDate': purchaseDate != null ? Timestamp.fromDate(purchaseDate!) : null,
      'quantityPurchased': quantityPurchased,
      'pricePerKg': pricePerKg,
      'totalAmount': totalAmount,
      'purchaseLocation': purchaseLocation,
      'wasVerified': wasVerified,
      'rating': rating,
      'review': review,
      'photos': photos,
      'reportedFraud': reportedFraud,
      'fraudDetails': fraudDetails,
    };
  }

  factory ConsumerPurchaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConsumerPurchaseModel(
      id: doc.id,
      consumerId: data['consumerId'] ?? '',
      batchId: data['batchId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      sellerType: data['sellerType'] ?? 'trader',
      scanDate: (data['scanDate'] as Timestamp).toDate(),
      purchaseDate: data['purchaseDate'] != null
          ? (data['purchaseDate'] as Timestamp).toDate()
          : null,
      quantityPurchased: data['quantityPurchased']?.toDouble(),
      pricePerKg: data['pricePerKg']?.toDouble(),
      totalAmount: data['totalAmount']?.toDouble(),
      purchaseLocation: data['purchaseLocation'],
      wasVerified: data['wasVerified'] ?? true,
      rating: data['rating'],
      review: data['review'],
      photos: List<String>.from(data['photos'] ?? []),
      reportedFraud: data['reportedFraud'] ?? false,
      fraudDetails: data['fraudDetails'],
    );
  }
}
