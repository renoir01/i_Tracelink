import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/certification_model.dart';
import '../utils/constants.dart';

class CertificationService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload certification document to Firebase Storage
  Future<String> uploadCertificationDocument(String producerId, String fileName, File file) async {
    try {
      final storageRef = _storage.ref().child('certifications/$producerId/$fileName');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  // Create new certification
  Future<String> createCertification(CertificationModel certification) async {
    try {
      final docRef = await _firestore.collection('certifications').add(certification.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create certification: $e');
    }
  }

  // Get certifications by producer
  Future<List<CertificationModel>> getCertificationsByProducer(String producerId) async {
    try {
      final snapshot = await _firestore
          .collection('certifications')
          .where('producerId', isEqualTo: producerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return CertificationModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to get certifications: $e');
    }
  }

  // Get certifications by batch
  Future<List<CertificationModel>> getCertificationsByBatch(String batchId) async {
    try {
      final snapshot = await _firestore
          .collection('certifications')
          .where('batchId', isEqualTo: batchId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return CertificationModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to get certifications by batch: $e');
    }
  }

  // Update certification status (admin function)
  Future<void> updateCertificationStatus(
    String certificationId,
    CertificationStatus status,
    String reviewedBy,
    {String? rejectionReason}
  ) async {
    try {
      final updates = <String, dynamic>{
        'status': status.toString(),
        'reviewedAt': Timestamp.now(),
        'reviewedBy': reviewedBy,
      };

      if (rejectionReason != null) {
        updates['rejectionReason'] = rejectionReason;
      }

      await _firestore.collection('certifications').doc(certificationId).update(updates);
    } catch (e) {
      throw Exception('Failed to update certification status: $e');
    }
  }

  // Get certification by ID
  Future<CertificationModel?> getCertificationById(String certificationId) async {
    try {
      final doc = await _firestore.collection('certifications').doc(certificationId).get();
      if (doc.exists) {
        return CertificationModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get certification: $e');
    }
  }

  // Get pending certifications for review (admin)
  Future<List<CertificationModel>> getPendingCertifications() async {
    try {
      final snapshot = await _firestore
          .collection('certifications')
          .where('status', isEqualTo: CertificationStatus.pending.toString())
          .orderBy('createdAt', descending: false) // Oldest first for review
          .get();

      return snapshot.docs.map((doc) {
        return CertificationModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to get pending certifications: $e');
    }
  }

  // Get expiring certifications
  Future<List<CertificationModel>> getExpiringCertifications(String producerId, {int daysAhead = 30}) async {
    try {
      final expiryThreshold = DateTime.now().add(Duration(days: daysAhead));
      final snapshot = await _firestore
          .collection('certifications')
          .where('producerId', isEqualTo: producerId)
          .where('expiryDate', isLessThanOrEqualTo: Timestamp.fromDate(expiryThreshold))
          .where('status', isEqualTo: CertificationStatus.approved.toString())
          .get();

      return snapshot.docs.map((doc) {
        return CertificationModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to get expiring certifications: $e');
    }
  }

  // Validate iron content meets biofortification standards
  ValidationResult validateIronContent(double ironContentMgPer100g) {
    if (ironContentMgPer100g < IronBiofortificationStandards.minimumIronContent) {
      return ValidationResult(
        isValid: false,
        message: 'Iron content (${ironContentMgPer100g.toStringAsFixed(1)} mg/100g) is below the minimum biofortification standard of ${IronBiofortificationStandards.minimumIronContent} mg/100g.',
        grade: 'Below Standard',
      );
    } else if (ironContentMgPer100g >= IronBiofortificationStandards.targetIronContent) {
      return ValidationResult(
        isValid: true,
        message: 'Excellent! Iron content (${ironContentMgPer100g.toStringAsFixed(1)} mg/100g) exceeds target biofortification standard.',
        grade: 'Excellent',
      );
    } else {
      return ValidationResult(
        isValid: true,
        message: 'Good! Iron content (${ironContentMgPer100g.toStringAsFixed(1)} mg/100g) meets minimum biofortification standard.',
        grade: 'Good',
      );
    }
  }

  // Generate certification report
  Future<Map<String, dynamic>> generateCertificationReport(String producerId) async {
    try {
      final certifications = await getCertificationsByProducer(producerId);

      final stats = {
        'totalCertifications': certifications.length,
        'approvedCertifications': certifications.where((c) => c.isApproved).length,
        'pendingCertifications': certifications.where((c) => c.isPending).length,
        'expiredCertifications': certifications.where((c) => c.isExpired).length,
        'expiringSoonCertifications': certifications.where((c) => c.isExpiringSoon).length,
        'biofortifiedBatches': certifications.where((c) =>
          c.type == CertificationType.ironContent &&
          c.isApproved &&
          c.meetsIronBiofortificationStandard
        ).length,
      };

      final typeBreakdown = <CertificationType, int>{};
      for (var cert in certifications) {
        typeBreakdown[cert.type] = (typeBreakdown[cert.type] ?? 0) + 1;
      }

      return {
        'statistics': stats,
        'certifications': certifications.map((c) => c.toMap()).toList(),
        'typeBreakdown': typeBreakdown.map((key, value) => MapEntry(key.toString(), value)),
        'generatedAt': DateTime.now(),
      };
    } catch (e) {
      throw Exception('Failed to generate certification report: $e');
    }
  }

  // Check if batch has required certifications
  Future<bool> hasRequiredCertifications(String batchId) async {
    try {
      final certifications = await getCertificationsByBatch(batchId);

      // Check for essential certifications
      final hasRAB = certifications.any((c) =>
        c.type == CertificationType.rabCertification && c.isApproved && !c.isExpired
      );

      final hasIronContent = certifications.any((c) =>
        c.type == CertificationType.ironContent && c.isApproved && !c.isExpired &&
        c.meetsIronBiofortificationStandard
      );

      final hasGermination = certifications.any((c) =>
        c.type == CertificationType.germination && c.isApproved && !c.isExpired
      );

      return hasRAB && hasIronContent && hasGermination;
    } catch (e) {
      return false;
    }
  }
}

// Validation result for iron content testing
class ValidationResult {
  final bool isValid;
  final String message;
  final String grade;

  const ValidationResult({
    required this.isValid,
    required this.message,
    required this.grade,
  });
}

// Predefined test parameters for different certification types
class CertificationTestParameters {
  static const Map<CertificationType, List<String>> requiredTests = {
    CertificationType.rabCertification: [
      'Certificate Number',
      'Issue Date',
      'Expiry Date',
      'Issuing Authority',
    ],
    CertificationType.ironContent: [
      'Iron Content (mg/100g)',
      'Testing Method',
      'Laboratory Name',
      'Sample Size',
      'Test Date',
    ],
    CertificationType.germination: [
      'Germination Rate (%)',
      'Test Duration (days)',
      'Testing Conditions',
      'Laboratory Name',
    ],
    CertificationType.purity: [
      'Genetic Purity (%)',
      'Testing Method',
      'Reference Variety',
      'Laboratory Name',
    ],
    CertificationType.quality: [
      'Overall Quality Score',
      'Moisture Content (%)',
      'Foreign Matter (%)',
      'Damaged Seeds (%)',
    ],
  };

  static List<String> getRequiredTests(CertificationType type) {
    return requiredTests[type] ?? [];
  }
}
