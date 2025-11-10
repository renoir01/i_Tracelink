import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class AggregatorModel {
  final String id;
  final String userId;
  final String businessName;
  final String registrationNumber;
  final String tinNumber; // Tax Identification Number
  final LocationModel location;
  final String contactPerson;
  final String phone;
  final String email;
  final List<String> serviceAreas; // Districts/Sectors served
  final List<CooperativePartnership> cooperativePartnerships;
  final StorageCapacity? storageInfo;
  final TransportCapacity? transportInfo;
  final String? website;
  final DateTime createdAt;
  final bool isActive;

  AggregatorModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.registrationNumber,
    required this.tinNumber,
    required this.location,
    required this.contactPerson,
    required this.phone,
    required this.email,
    this.serviceAreas = const [],
    this.cooperativePartnerships = const [],
    this.storageInfo,
    this.transportInfo,
    this.website,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessName': businessName,
      'registrationNumber': registrationNumber,
      'tinNumber': tinNumber,
      'location': location.toMap(),
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'serviceAreas': serviceAreas,
      'cooperativePartnerships':
          cooperativePartnerships.map((c) => c.toMap()).toList(),
      if (storageInfo != null) 'storageInfo': storageInfo!.toMap(),
      if (transportInfo != null) 'transportInfo': transportInfo!.toMap(),
      if (website != null) 'website': website,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory AggregatorModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AggregatorModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      businessName: data['businessName'] ?? '',
      registrationNumber: data['registrationNumber'] ?? '',
      tinNumber: data['tinNumber'] ?? '',
      location: LocationModel.fromMap(data['location'] ?? {}),
      contactPerson: data['contactPerson'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      serviceAreas: List<String>.from(data['serviceAreas'] ?? []),
      cooperativePartnerships: (data['cooperativePartnerships'] as List<dynamic>?)
              ?.map((c) => CooperativePartnership.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      storageInfo: data['storageInfo'] != null
          ? StorageCapacity.fromMap(data['storageInfo'])
          : null,
      transportInfo: data['transportInfo'] != null
          ? TransportCapacity.fromMap(data['transportInfo'])
          : null,
      website: data['website'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }
}

class CooperativePartnership {
  final String cooperativeId;
  final String cooperativeName;
  final DateTime partnershipDate;

  CooperativePartnership({
    required this.cooperativeId,
    required this.cooperativeName,
    required this.partnershipDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'cooperativeId': cooperativeId,
      'cooperativeName': cooperativeName,
      'partnershipDate': Timestamp.fromDate(partnershipDate),
    };
  }

  factory CooperativePartnership.fromMap(Map<String, dynamic> map) {
    return CooperativePartnership(
      cooperativeId: map['cooperativeId'] ?? '',
      cooperativeName: map['cooperativeName'] ?? '',
      partnershipDate: (map['partnershipDate'] as Timestamp).toDate(),
    );
  }
}

class StorageCapacity {
  final double capacityInTons;
  final bool hasRefrigeration;
  final String storageType; // warehouse, cold storage, etc.

  StorageCapacity({
    required this.capacityInTons,
    required this.hasRefrigeration,
    required this.storageType,
  });

  Map<String, dynamic> toMap() {
    return {
      'capacityInTons': capacityInTons,
      'hasRefrigeration': hasRefrigeration,
      'storageType': storageType,
    };
  }

  factory StorageCapacity.fromMap(Map<String, dynamic> map) {
    return StorageCapacity(
      capacityInTons: map['capacityInTons']?.toDouble() ?? 0.0,
      hasRefrigeration: map['hasRefrigeration'] ?? false,
      storageType: map['storageType'] ?? '',
    );
  }
}

class TransportCapacity {
  final int numberOfVehicles;
  final double capacityInTons;
  final bool hasRefrigeratedTransport;

  TransportCapacity({
    required this.numberOfVehicles,
    required this.capacityInTons,
    required this.hasRefrigeratedTransport,
  });

  Map<String, dynamic> toMap() {
    return {
      'numberOfVehicles': numberOfVehicles,
      'capacityInTons': capacityInTons,
      'hasRefrigeratedTransport': hasRefrigeratedTransport,
    };
  }

  factory TransportCapacity.fromMap(Map<String, dynamic> map) {
    return TransportCapacity(
      numberOfVehicles: map['numberOfVehicles'] ?? 0,
      capacityInTons: map['capacityInTons']?.toDouble() ?? 0.0,
      hasRefrigeratedTransport: map['hasRefrigeratedTransport'] ?? false,
    );
  }
}
