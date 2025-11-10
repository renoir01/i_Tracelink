import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class InstitutionModel {
  final String id;
  final String userId;
  final String institutionName;
  final String institutionType; // school, hospital, etc.
  final String registrationNumber;
  final LocationModel location;
  final String contactPerson;
  final String phone;
  final String email;
  final NutritionalRequirements? nutritionalRequirements;
  final ProcurementInfo? procurementInfo;
  final int? numberOfBeneficiaries; // students/patients
  final String? website;
  final DateTime createdAt;
  final bool isActive;

  InstitutionModel({
    required this.id,
    required this.userId,
    required this.institutionName,
    required this.institutionType,
    required this.registrationNumber,
    required this.location,
    required this.contactPerson,
    required this.phone,
    required this.email,
    this.nutritionalRequirements,
    this.procurementInfo,
    this.numberOfBeneficiaries,
    this.website,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'institutionName': institutionName,
      'institutionType': institutionType,
      'registrationNumber': registrationNumber,
      'location': location.toMap(),
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      if (nutritionalRequirements != null)
        'nutritionalRequirements': nutritionalRequirements!.toMap(),
      if (procurementInfo != null) 'procurementInfo': procurementInfo!.toMap(),
      if (numberOfBeneficiaries != null)
        'numberOfBeneficiaries': numberOfBeneficiaries,
      if (website != null) 'website': website,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory InstitutionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return InstitutionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      institutionName: data['institutionName'] ?? '',
      institutionType: data['institutionType'] ?? '',
      registrationNumber: data['registrationNumber'] ?? '',
      location: LocationModel.fromMap(data['location'] ?? {}),
      contactPerson: data['contactPerson'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      nutritionalRequirements: data['nutritionalRequirements'] != null
          ? NutritionalRequirements.fromMap(data['nutritionalRequirements'])
          : null,
      procurementInfo: data['procurementInfo'] != null
          ? ProcurementInfo.fromMap(data['procurementInfo'])
          : null,
      numberOfBeneficiaries: data['numberOfBeneficiaries'],
      website: data['website'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }
}

class NutritionalRequirements {
  final double monthlyBeanRequirement; // kg per month
  final bool requiresIronFortified;
  final String? specificVarietyPreference;
  final String? dietaryNotes;

  NutritionalRequirements({
    required this.monthlyBeanRequirement,
    required this.requiresIronFortified,
    this.specificVarietyPreference,
    this.dietaryNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'monthlyBeanRequirement': monthlyBeanRequirement,
      'requiresIronFortified': requiresIronFortified,
      if (specificVarietyPreference != null)
        'specificVarietyPreference': specificVarietyPreference,
      if (dietaryNotes != null) 'dietaryNotes': dietaryNotes,
    };
  }

  factory NutritionalRequirements.fromMap(Map<String, dynamic> map) {
    return NutritionalRequirements(
      monthlyBeanRequirement: map['monthlyBeanRequirement']?.toDouble() ?? 0.0,
      requiresIronFortified: map['requiresIronFortified'] ?? true,
      specificVarietyPreference: map['specificVarietyPreference'],
      dietaryNotes: map['dietaryNotes'],
    );
  }
}

class ProcurementInfo {
  final String budgetCycle; // quarterly, annually, etc.
  final double? budgetAmount;
  final String procurementMethod; // tender, direct purchase, etc.
  final String? preferredPaymentTerms;

  ProcurementInfo({
    required this.budgetCycle,
    this.budgetAmount,
    required this.procurementMethod,
    this.preferredPaymentTerms,
  });

  Map<String, dynamic> toMap() {
    return {
      'budgetCycle': budgetCycle,
      if (budgetAmount != null) 'budgetAmount': budgetAmount,
      'procurementMethod': procurementMethod,
      if (preferredPaymentTerms != null)
        'preferredPaymentTerms': preferredPaymentTerms,
    };
  }

  factory ProcurementInfo.fromMap(Map<String, dynamic> map) {
    return ProcurementInfo(
      budgetCycle: map['budgetCycle'] ?? '',
      budgetAmount: map['budgetAmount']?.toDouble(),
      procurementMethod: map['procurementMethod'] ?? '',
      preferredPaymentTerms: map['preferredPaymentTerms'],
    );
  }
}
