import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class OrderModel {
  final String id;
  final String orderType;
  final String buyerId;
  final String sellerId;
  final double quantity;
  final double pricePerKg;
  final double totalAmount;
  final DateTime requestDate;
  final DateTime expectedDeliveryDate;
  final String status;
  final LocationModel deliveryLocation;
  final String paymentStatus;
  final String? notes;
  final String? seedVariety;
  final String? qualityGrade;

  // Status timestamps for tracking order progress
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? preparingAt;
  final DateTime? shippedAt;
  final DateTime? collectedAt;
  final DateTime? inTransitAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;

  OrderModel({
    required this.id,
    required this.orderType,
    required this.buyerId,
    required this.sellerId,
    required this.quantity,
    required this.pricePerKg,
    required this.totalAmount,
    required this.requestDate,
    required this.expectedDeliveryDate,
    required this.status,
    required this.deliveryLocation,
    required this.paymentStatus,
    this.notes,
    this.seedVariety,
    this.qualityGrade,
    this.acceptedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.preparingAt,
    this.shippedAt,
    this.collectedAt,
    this.inTransitAt,
    this.deliveredAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderType': orderType,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'quantity': quantity,
      'pricePerKg': pricePerKg,
      'totalAmount': totalAmount,
      'requestDate': Timestamp.fromDate(requestDate),
      'expectedDeliveryDate': Timestamp.fromDate(expectedDeliveryDate),
      'status': status,
      'deliveryLocation': deliveryLocation.toMap(),
      'paymentStatus': paymentStatus,
      if (notes != null) 'notes': notes,
      if (seedVariety != null) 'seedVariety': seedVariety,
      if (qualityGrade != null) 'qualityGrade': qualityGrade,
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (preparingAt != null) 'preparingAt': Timestamp.fromDate(preparingAt!),
      if (shippedAt != null) 'shippedAt': Timestamp.fromDate(shippedAt!),
      if (collectedAt != null) 'collectedAt': Timestamp.fromDate(collectedAt!),
      if (inTransitAt != null) 'inTransitAt': Timestamp.fromDate(inTransitAt!),
      if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    };
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      orderType: data['orderType'] ?? '',
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      quantity: data['quantity']?.toDouble() ?? 0.0,
      pricePerKg: data['pricePerKg']?.toDouble() ?? 0.0,
      totalAmount: data['totalAmount']?.toDouble() ?? 0.0,
      requestDate: (data['requestDate'] as Timestamp).toDate(),
      expectedDeliveryDate: (data['expectedDeliveryDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      deliveryLocation: LocationModel.fromMap(data['deliveryLocation'] ?? {}),
      paymentStatus: data['paymentStatus'] ?? 'pending',
      notes: data['notes'],
      seedVariety: data['seedVariety'],
      qualityGrade: data['qualityGrade'],
      acceptedAt: data['acceptedAt'] != null ? (data['acceptedAt'] as Timestamp).toDate() : null,
      rejectedAt: data['rejectedAt'] != null ? (data['rejectedAt'] as Timestamp).toDate() : null,
      rejectionReason: data['rejectionReason'],
      preparingAt: data['preparingAt'] != null ? (data['preparingAt'] as Timestamp).toDate() : null,
      shippedAt: data['shippedAt'] != null ? (data['shippedAt'] as Timestamp).toDate() : null,
      collectedAt: data['collectedAt'] != null ? (data['collectedAt'] as Timestamp).toDate() : null,
      inTransitAt: data['inTransitAt'] != null ? (data['inTransitAt'] as Timestamp).toDate() : null,
      deliveredAt: data['deliveredAt'] != null ? (data['deliveredAt'] as Timestamp).toDate() : null,
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
    );
  }

  OrderModel copyWith({
    String? id,
    String? orderType,
    String? buyerId,
    String? sellerId,
    double? quantity,
    double? pricePerKg,
    double? totalAmount,
    DateTime? requestDate,
    DateTime? expectedDeliveryDate,
    String? status,
    LocationModel? deliveryLocation,
    String? paymentStatus,
    String? notes,
    String? seedVariety,
    String? qualityGrade,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    DateTime? preparingAt,
    DateTime? shippedAt,
    DateTime? collectedAt,
    DateTime? inTransitAt,
    DateTime? deliveredAt,
    DateTime? completedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderType: orderType ?? this.orderType,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      quantity: quantity ?? this.quantity,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalAmount: totalAmount ?? this.totalAmount,
      requestDate: requestDate ?? this.requestDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      status: status ?? this.status,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      seedVariety: seedVariety ?? this.seedVariety,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      preparingAt: preparingAt ?? this.preparingAt,
      shippedAt: shippedAt ?? this.shippedAt,
      collectedAt: collectedAt ?? this.collectedAt,
      inTransitAt: inTransitAt ?? this.inTransitAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
