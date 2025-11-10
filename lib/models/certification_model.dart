import 'package:cloud_firestore/cloud_firestore.dart';

enum CertificationType {
  rabCertification, // Rwanda Agriculture Board
  ironContent,      // Iron biofortification test
  germination,      // Germination test
  purity,          // Genetic purity test
  quality,         // General quality certification
}

enum CertificationStatus {
  pending,      // Submitted, awaiting review
  underReview,  // Being reviewed by authorities
  approved,     // Certification approved
  rejected,     // Certification rejected
  expired,      // Certification has expired
  revoked,      // Certification revoked
}

class CertificationModel {
  final String id;
  final String producerId;
  final String batchId; // Link to seed batch
  final CertificationType type;
  final CertificationStatus status;
  final String certificateNumber;
  final String issuingAuthority; // RAB, private lab, etc.
  final DateTime issueDate;
  final DateTime expiryDate;
  final Map<String, dynamic> testResults;
  final List<String> documentUrls; // URLs to uploaded documents
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  CertificationModel({
    required this.id,
    required this.producerId,
    required this.batchId,
    required this.type,
    required this.status,
    required this.certificateNumber,
    required this.issuingAuthority,
    required this.issueDate,
    required this.expiryDate,
    required this.testResults,
    required this.documentUrls,
    this.rejectionReason,
    this.notes,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'producerId': producerId,
      'batchId': batchId,
      'type': type.toString(),
      'status': status.toString(),
      'certificateNumber': certificateNumber,
      'issuingAuthority': issuingAuthority,
      'issueDate': Timestamp.fromDate(issueDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'testResults': testResults,
      'documentUrls': documentUrls,
      'rejectionReason': rejectionReason,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
    };
  }

  // Create from Firestore document
  factory CertificationModel.fromMap(String id, Map<String, dynamic> data) {
    return CertificationModel(
      id: id,
      producerId: data['producerId'] ?? '',
      batchId: data['batchId'] ?? '',
      type: _parseCertificationType(data['type'] ?? ''),
      status: _parseCertificationStatus(data['status'] ?? ''),
      certificateNumber: data['certificateNumber'] ?? '',
      issuingAuthority: data['issuingAuthority'] ?? '',
      issueDate: (data['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 365)),
      testResults: data['testResults'] ?? {},
      documentUrls: List<String>.from(data['documentUrls'] ?? []),
      rejectionReason: data['rejectionReason'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
    );
  }

  static CertificationType _parseCertificationType(String value) {
    switch (value) {
      case 'CertificationType.rabCertification':
        return CertificationType.rabCertification;
      case 'CertificationType.ironContent':
        return CertificationType.ironContent;
      case 'CertificationType.germination':
        return CertificationType.germination;
      case 'CertificationType.purity':
        return CertificationType.purity;
      case 'CertificationType.quality':
        return CertificationType.quality;
      default:
        return CertificationType.quality;
    }
  }

  static CertificationStatus _parseCertificationStatus(String value) {
    switch (value) {
      case 'CertificationStatus.pending':
        return CertificationStatus.pending;
      case 'CertificationStatus.underReview':
        return CertificationStatus.underReview;
      case 'CertificationStatus.approved':
        return CertificationStatus.approved;
      case 'CertificationStatus.rejected':
        return CertificationStatus.rejected;
      case 'CertificationStatus.expired':
        return CertificationStatus.expired;
      case 'CertificationStatus.revoked':
        return CertificationStatus.revoked;
      default:
        return CertificationStatus.pending;
    }
  }

  // Helper properties
  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isExpiringSoon => expiryDate.difference(DateTime.now()).inDays <= 30;
  bool get isApproved => status == CertificationStatus.approved;
  bool get isPending => status == CertificationStatus.pending;

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  String get typeDisplayName {
    switch (type) {
      case CertificationType.rabCertification:
        return 'RAB Certification';
      case CertificationType.ironContent:
        return 'Iron Content Test';
      case CertificationType.germination:
        return 'Germination Test';
      case CertificationType.purity:
        return 'Genetic Purity Test';
      case CertificationType.quality:
        return 'Quality Certification';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case CertificationStatus.pending:
        return 'Pending Review';
      case CertificationStatus.underReview:
        return 'Under Review';
      case CertificationStatus.approved:
        return 'Approved';
      case CertificationStatus.rejected:
        return 'Rejected';
      case CertificationStatus.expired:
        return 'Expired';
      case CertificationStatus.revoked:
        return 'Revoked';
    }
  }

  // Iron content specific properties
  double? get ironContentMgPer100g => testResults['ironContentMgPer100g']?.toDouble();
  bool get meetsIronBiofortificationStandard => ironContentMgPer100g != null && ironContentMgPer100g! >= 50.0;
}

// Iron Biofortification Standards
class IronBiofortificationStandards {
  static const double minimumIronContent = 50.0; // mg/100g dry weight
  static const double targetIronContent = 80.0; // mg/100g dry weight
  static const double maximumAcceptableIronContent = 150.0; // mg/100g dry weight

  static bool isBiofortified(double ironContentMgPer100g) {
    return ironContentMgPer100g >= minimumIronContent;
  }

  static String getIronContentGrade(double ironContentMgPer100g) {
    if (ironContentMgPer100g >= targetIronContent) {
      return 'Excellent';
    } else if (ironContentMgPer100g >= minimumIronContent) {
      return 'Good';
    } else {
      return 'Below Standard';
    }
  }
}

// Certification Issuing Authorities
class CertificationAuthorities {
  static const String rab = 'Rwanda Agriculture Board (RAB)';
  static const String icipe = 'International Centre of Insect Physiology and Ecology (ICIPE)';
  static const String harvestPlus = 'HarvestPlus';
  static const String privateLab = 'Private Certified Laboratory';
  static const String universityLab = 'University Research Laboratory';

  static const List<String> allAuthorities = [
    rab,
    icipe,
    harvestPlus,
    privateLab,
    universityLab,
  ];
}
