import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class CooperativeModel {
  final String id;
  final String userId;
  final String cooperativeName;
  final String registrationNumber;
  final int numberOfMembers;
  final LocationModel location;
  final String contactPerson;
  final String phone;
  final AgroDealerPurchase? agroDealerPurchase;
  final PlantingInfo? plantingInfo;
  final HarvestInfo? harvestInfo;
  final double? pricePerKg;
  final bool availableForSale;

  CooperativeModel({
    required this.id,
    required this.userId,
    required this.cooperativeName,
    required this.registrationNumber,
    required this.numberOfMembers,
    required this.location,
    required this.contactPerson,
    required this.phone,
    this.agroDealerPurchase,
    this.plantingInfo,
    this.harvestInfo,
    this.pricePerKg,
    this.availableForSale = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'cooperativeName': cooperativeName,
      'registrationNumber': registrationNumber,
      'numberOfMembers': numberOfMembers,
      'location': location.toMap(),
      'contactPerson': contactPerson,
      'phone': phone,
      if (agroDealerPurchase != null) 'agroDealerPurchase': agroDealerPurchase!.toMap(),
      if (plantingInfo != null) 'plantingInfo': plantingInfo!.toMap(),
      if (harvestInfo != null) 'harvestInfo': harvestInfo!.toMap(),
      if (pricePerKg != null) 'pricePerKg': pricePerKg,
      'availableForSale': availableForSale,
    };
  }

  factory CooperativeModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CooperativeModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      cooperativeName: data['cooperativeName'] ?? '',
      registrationNumber: data['registrationNumber'] ?? '',
      numberOfMembers: data['numberOfMembers'] ?? 0,
      location: LocationModel.fromMap(data['location'] ?? {}),
      contactPerson: data['contactPerson'] ?? '',
      phone: data['phone'] ?? '',
      agroDealerPurchase: data['agroDealerPurchase'] != null
          ? AgroDealerPurchase.fromMap(data['agroDealerPurchase'])
          : null,
      plantingInfo: data['plantingInfo'] != null
          ? PlantingInfo.fromMap(data['plantingInfo'])
          : null,
      harvestInfo: data['harvestInfo'] != null
          ? HarvestInfo.fromMap(data['harvestInfo'])
          : null,
      pricePerKg: data['pricePerKg']?.toDouble(),
      availableForSale: data['availableForSale'] ?? false,
    );
  }
}

class AgroDealerPurchase {
  final String dealerName;
  final String seedBatch;
  final double quantity;
  final DateTime purchaseDate;

  AgroDealerPurchase({
    required this.dealerName,
    required this.seedBatch,
    required this.quantity,
    required this.purchaseDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'dealerName': dealerName,
      'seedBatch': seedBatch,
      'quantity': quantity,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
    };
  }

  factory AgroDealerPurchase.fromMap(Map<String, dynamic> map) {
    return AgroDealerPurchase(
      dealerName: map['dealerName'] ?? '',
      seedBatch: map['seedBatch'] ?? '',
      quantity: map['quantity']?.toDouble() ?? 0.0,
      purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
    );
  }
}

class PlantingInfo {
  final DateTime plantingDate;
  final double landArea;
  final DateTime expectedHarvestDate;

  PlantingInfo({
    required this.plantingDate,
    required this.landArea,
    required this.expectedHarvestDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'plantingDate': Timestamp.fromDate(plantingDate),
      'landArea': landArea,
      'expectedHarvestDate': Timestamp.fromDate(expectedHarvestDate),
    };
  }

  factory PlantingInfo.fromMap(Map<String, dynamic> map) {
    return PlantingInfo(
      plantingDate: (map['plantingDate'] as Timestamp).toDate(),
      landArea: map['landArea']?.toDouble() ?? 0.0,
      expectedHarvestDate: (map['expectedHarvestDate'] as Timestamp).toDate(),
    );
  }
}

class HarvestInfo {
  final double expectedQuantity;
  final double? actualQuantity;
  final DateTime? harvestDate;
  final String? storageLocation;

  HarvestInfo({
    required this.expectedQuantity,
    this.actualQuantity,
    this.harvestDate,
    this.storageLocation,
  });

  Map<String, dynamic> toMap() {
    return {
      'expectedQuantity': expectedQuantity,
      if (actualQuantity != null) 'actualQuantity': actualQuantity,
      if (harvestDate != null) 'harvestDate': Timestamp.fromDate(harvestDate!),
      if (storageLocation != null) 'storageLocation': storageLocation,
    };
  }

  factory HarvestInfo.fromMap(Map<String, dynamic> map) {
    return HarvestInfo(
      expectedQuantity: map['expectedQuantity']?.toDouble() ?? 0.0,
      actualQuantity: map['actualQuantity']?.toDouble(),
      harvestDate: map['harvestDate'] != null
          ? (map['harvestDate'] as Timestamp).toDate()
          : null,
      storageLocation: map['storageLocation'],
    );
  }
}
