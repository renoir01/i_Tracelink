import 'package:cloud_firestore/cloud_firestore.dart';

class SeedDistributionModel {
  final String id;
  final String seedProducerId;
  final String seedVariety;
  final double quantity; // kg
  final String recipientId; // Farmer/Cooperative ID
  final String recipientName;
  final String recipientType; // farmer, cooperative, agro_dealer
  final DateTime distributionDate;
  final String distributionMethod; // direct, through_dealer
  final String? agroDealerId; // If distributed through dealer
  final String? agroDealerName;
  final String certificationNumber;
  final double ironContent; // mg per 100g
  final String quality; // certified, foundation, commercial
  final String? batchNumber;
  final Map<String, dynamic>? location;
  final String status; // distributed, planted, harvested
  final String? notes;
  final bool followUpRequired;
  final DateTime? expectedPlantingDate;
  final DateTime? expectedHarvestDate;

  SeedDistributionModel({
    required this.id,
    required this.seedProducerId,
    required this.seedVariety,
    required this.quantity,
    required this.recipientId,
    required this.recipientName,
    required this.recipientType,
    required this.distributionDate,
    this.distributionMethod = 'direct',
    this.agroDealerId,
    this.agroDealerName,
    required this.certificationNumber,
    this.ironContent = 80.0,
    this.quality = 'certified',
    this.batchNumber,
    this.location,
    this.status = 'distributed',
    this.notes,
    this.followUpRequired = false,
    this.expectedPlantingDate,
    this.expectedHarvestDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'seedProducerId': seedProducerId,
      'seedVariety': seedVariety,
      'quantity': quantity,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'recipientType': recipientType,
      'distributionDate': Timestamp.fromDate(distributionDate),
      'distributionMethod': distributionMethod,
      'agroDealerId': agroDealerId,
      'agroDealerName': agroDealerName,
      'certificationNumber': certificationNumber,
      'ironContent': ironContent,
      'quality': quality,
      'batchNumber': batchNumber,
      'location': location,
      'status': status,
      'notes': notes,
      'followUpRequired': followUpRequired,
      'expectedPlantingDate': expectedPlantingDate != null
          ? Timestamp.fromDate(expectedPlantingDate!)
          : null,
      'expectedHarvestDate': expectedHarvestDate != null
          ? Timestamp.fromDate(expectedHarvestDate!)
          : null,
    };
  }

  factory SeedDistributionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SeedDistributionModel(
      id: doc.id,
      seedProducerId: data['seedProducerId'] ?? '',
      seedVariety: data['seedVariety'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      recipientId: data['recipientId'] ?? '',
      recipientName: data['recipientName'] ?? '',
      recipientType: data['recipientType'] ?? 'farmer',
      distributionDate: (data['distributionDate'] as Timestamp).toDate(),
      distributionMethod: data['distributionMethod'] ?? 'direct',
      agroDealerId: data['agroDealerId'],
      agroDealerName: data['agroDealerName'],
      certificationNumber: data['certificationNumber'] ?? '',
      ironContent: (data['ironContent'] ?? 80.0).toDouble(),
      quality: data['quality'] ?? 'certified',
      batchNumber: data['batchNumber'],
      location: data['location'],
      status: data['status'] ?? 'distributed',
      notes: data['notes'],
      followUpRequired: data['followUpRequired'] ?? false,
      expectedPlantingDate: data['expectedPlantingDate'] != null
          ? (data['expectedPlantingDate'] as Timestamp).toDate()
          : null,
      expectedHarvestDate: data['expectedHarvestDate'] != null
          ? (data['expectedHarvestDate'] as Timestamp).toDate()
          : null,
    );
  }
}
