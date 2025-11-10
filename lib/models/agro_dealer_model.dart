import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class AgroDealerModel {
  final String id;
  final String userId;
  final String businessName;
  final String registrationNumber;
  final String licenseNumber;
  final LocationModel location;
  final String contactPerson;
  final String phone;
  final String email;
  final List<String> seedProducerIds; // Suppliers
  final List<SeedInventory> inventory;
  final String? website;
  final DateTime createdAt;
  final bool isActive;

  AgroDealerModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.registrationNumber,
    required this.licenseNumber,
    required this.location,
    required this.contactPerson,
    required this.phone,
    required this.email,
    this.seedProducerIds = const [],
    this.inventory = const [],
    this.website,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessName': businessName,
      'registrationNumber': registrationNumber,
      'licenseNumber': licenseNumber,
      'location': location.toMap(),
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'seedProducerIds': seedProducerIds,
      'inventory': inventory.map((i) => i.toMap()).toList(),
      if (website != null) 'website': website,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory AgroDealerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AgroDealerModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      businessName: data['businessName'] ?? '',
      registrationNumber: data['registrationNumber'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      location: LocationModel.fromMap(data['location'] ?? {}),
      contactPerson: data['contactPerson'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      seedProducerIds: List<String>.from(data['seedProducerIds'] ?? []),
      inventory: (data['inventory'] as List<dynamic>?)
              ?.map((i) => SeedInventory.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      website: data['website'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }
}

class SeedInventory {
  final String varietyCode;
  final String varietyName;
  final String seedProducerId;
  final String batchNumber;
  final double quantity; // kg
  final double pricePerKg;
  final DateTime expiryDate;

  SeedInventory({
    required this.varietyCode,
    required this.varietyName,
    required this.seedProducerId,
    required this.batchNumber,
    required this.quantity,
    required this.pricePerKg,
    required this.expiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'varietyCode': varietyCode,
      'varietyName': varietyName,
      'seedProducerId': seedProducerId,
      'batchNumber': batchNumber,
      'quantity': quantity,
      'pricePerKg': pricePerKg,
      'expiryDate': Timestamp.fromDate(expiryDate),
    };
  }

  factory SeedInventory.fromMap(Map<String, dynamic> map) {
    return SeedInventory(
      varietyCode: map['varietyCode'] ?? '',
      varietyName: map['varietyName'] ?? '',
      seedProducerId: map['seedProducerId'] ?? '',
      batchNumber: map['batchNumber'] ?? '',
      quantity: map['quantity']?.toDouble() ?? 0.0,
      pricePerKg: map['pricePerKg']?.toDouble() ?? 0.0,
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
    );
  }
}
