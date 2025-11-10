import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class SeedProducerModel {
  final String id;
  final String userId;
  final String organizationName;
  final String registrationNumber;
  final String licenseNumber;
  final LocationModel location;
  final String contactPerson;
  final String phone;
  final String email;
  final List<String> certifications;
  final List<SeedVariety> seedVarieties;
  final double? productionCapacity; // kg per season
  final String? website;
  final DateTime createdAt;
  final bool isActive;

  SeedProducerModel({
    required this.id,
    required this.userId,
    required this.organizationName,
    required this.registrationNumber,
    required this.licenseNumber,
    required this.location,
    required this.contactPerson,
    required this.phone,
    required this.email,
    this.certifications = const [],
    this.seedVarieties = const [],
    this.productionCapacity,
    this.website,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'organizationName': organizationName,
      'registrationNumber': registrationNumber,
      'licenseNumber': licenseNumber,
      'location': location.toMap(),
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'certifications': certifications,
      'seedVarieties': seedVarieties.map((v) => v.toMap()).toList(),
      if (productionCapacity != null) 'productionCapacity': productionCapacity,
      if (website != null) 'website': website,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory SeedProducerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SeedProducerModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      organizationName: data['organizationName'] ?? '',
      registrationNumber: data['registrationNumber'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      location: LocationModel.fromMap(data['location'] ?? {}),
      contactPerson: data['contactPerson'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      certifications: List<String>.from(data['certifications'] ?? []),
      seedVarieties: (data['seedVarieties'] as List<dynamic>?)
              ?.map((v) => SeedVariety.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
      productionCapacity: data['productionCapacity']?.toDouble(),
      website: data['website'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }
}

class SeedVariety {
  final String varietyName;
  final String varietyCode;
  final double ironContent; // mg per 100g
  final String description;
  final int maturityDays;
  final double pricePerKg;

  SeedVariety({
    required this.varietyName,
    required this.varietyCode,
    required this.ironContent,
    required this.description,
    required this.maturityDays,
    required this.pricePerKg,
  });

  Map<String, dynamic> toMap() {
    return {
      'varietyName': varietyName,
      'varietyCode': varietyCode,
      'ironContent': ironContent,
      'description': description,
      'maturityDays': maturityDays,
      'pricePerKg': pricePerKg,
    };
  }

  factory SeedVariety.fromMap(Map<String, dynamic> map) {
    return SeedVariety(
      varietyName: map['varietyName'] ?? '',
      varietyCode: map['varietyCode'] ?? '',
      ironContent: map['ironContent']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      maturityDays: map['maturityDays'] ?? 0,
      pricePerKg: map['pricePerKg']?.toDouble() ?? 0.0,
    );
  }
}
