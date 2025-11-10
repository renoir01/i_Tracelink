import 'package:cloud_firestore/cloud_firestore.dart';

class BatchModel {
  final String id;
  final String farmerId; // Cooperative user ID
  final String cooperativeName;
  final String batchNumber;
  final String beanVariety;
  final double quantity; // in kg
  final String status; // growing, harvested, available, sold
  final DateTime registrationDate;
  final DateTime? harvestDate;
  final DateTime? plantingDate;
  final double? landSize; // in hectares
  final String? seedSource; // Agro-dealer ID or name
  final String? seedBatchNumber;
  final String quality; // A, B, C or not_graded
  final double? pricePerKg;
  final bool availableForSale;
  final String? storageLocation;
  final List<String> photos;
  final double ironContent; // mg per 100g
  final String? notes;
  final Map<String, dynamic>? location;

  BatchModel({
    required this.id,
    required this.farmerId,
    required this.cooperativeName,
    required this.batchNumber,
    required this.beanVariety,
    required this.quantity,
    required this.status,
    required this.registrationDate,
    this.harvestDate,
    this.plantingDate,
    this.landSize,
    this.seedSource,
    this.seedBatchNumber,
    this.quality = 'not_graded',
    this.pricePerKg,
    this.availableForSale = false,
    this.storageLocation,
    this.photos = const [],
    this.ironContent = 80.0,
    this.notes,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'cooperativeName': cooperativeName,
      'batchNumber': batchNumber,
      'beanVariety': beanVariety,
      'quantity': quantity,
      'status': status,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'harvestDate': harvestDate != null ? Timestamp.fromDate(harvestDate!) : null,
      'plantingDate': plantingDate != null ? Timestamp.fromDate(plantingDate!) : null,
      'landSize': landSize,
      'seedSource': seedSource,
      'seedBatchNumber': seedBatchNumber,
      'quality': quality,
      'pricePerKg': pricePerKg,
      'availableForSale': availableForSale,
      'storageLocation': storageLocation,
      'photos': photos,
      'ironContent': ironContent,
      'notes': notes,
      'location': location,
    };
  }

  factory BatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BatchModel(
      id: doc.id,
      farmerId: data['farmerId'] ?? '',
      cooperativeName: data['cooperativeName'] ?? '',
      batchNumber: data['batchNumber'] ?? '',
      beanVariety: data['beanVariety'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      status: data['status'] ?? 'growing',
      registrationDate: (data['registrationDate'] as Timestamp).toDate(),
      harvestDate: data['harvestDate'] != null
          ? (data['harvestDate'] as Timestamp).toDate()
          : null,
      plantingDate: data['plantingDate'] != null
          ? (data['plantingDate'] as Timestamp).toDate()
          : null,
      landSize: data['landSize']?.toDouble(),
      seedSource: data['seedSource'],
      seedBatchNumber: data['seedBatchNumber'],
      quality: data['quality'] ?? 'not_graded',
      pricePerKg: data['pricePerKg']?.toDouble(),
      availableForSale: data['availableForSale'] ?? false,
      storageLocation: data['storageLocation'],
      photos: List<String>.from(data['photos'] ?? []),
      ironContent: (data['ironContent'] ?? 80.0).toDouble(),
      notes: data['notes'],
      location: data['location'],
    );
  }

  BatchModel copyWith({
    String? id,
    String? farmerId,
    String? cooperativeName,
    String? batchNumber,
    String? beanVariety,
    double? quantity,
    String? status,
    DateTime? registrationDate,
    DateTime? harvestDate,
    DateTime? plantingDate,
    double? landSize,
    String? seedSource,
    String? seedBatchNumber,
    String? quality,
    double? pricePerKg,
    bool? availableForSale,
    String? storageLocation,
    List<String>? photos,
    double? ironContent,
    String? notes,
    Map<String, dynamic>? location,
  }) {
    return BatchModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      cooperativeName: cooperativeName ?? this.cooperativeName,
      batchNumber: batchNumber ?? this.batchNumber,
      beanVariety: beanVariety ?? this.beanVariety,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      registrationDate: registrationDate ?? this.registrationDate,
      harvestDate: harvestDate ?? this.harvestDate,
      plantingDate: plantingDate ?? this.plantingDate,
      landSize: landSize ?? this.landSize,
      seedSource: seedSource ?? this.seedSource,
      seedBatchNumber: seedBatchNumber ?? this.seedBatchNumber,
      quality: quality ?? this.quality,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      availableForSale: availableForSale ?? this.availableForSale,
      storageLocation: storageLocation ?? this.storageLocation,
      photos: photos ?? this.photos,
      ironContent: ironContent ?? this.ironContent,
      notes: notes ?? this.notes,
      location: location ?? this.location,
    );
  }
}
