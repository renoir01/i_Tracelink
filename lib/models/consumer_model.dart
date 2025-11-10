import 'package:cloud_firestore/cloud_firestore.dart';

class ConsumerModel {
  final String id;
  final String userId;
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final Map<String, dynamic>? location;
  final List<String> scannedProducts; // Batch IDs
  final List<String> trustedSellers; // Seller IDs
  final int totalScans;
  final double? ironIntakeGoal; // mg per day
  final bool notificationsEnabled;
  final String preferredLanguage; // 'en' or 'rw'
  final DateTime registrationDate;
  final DateTime? lastScanDate;

  ConsumerModel({
    required this.id,
    required this.userId,
    this.fullName,
    this.phoneNumber,
    this.email,
    this.location,
    this.scannedProducts = const [],
    this.trustedSellers = const [],
    this.totalScans = 0,
    this.ironIntakeGoal,
    this.notificationsEnabled = true,
    this.preferredLanguage = 'en',
    required this.registrationDate,
    this.lastScanDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'location': location,
      'scannedProducts': scannedProducts,
      'trustedSellers': trustedSellers,
      'totalScans': totalScans,
      'ironIntakeGoal': ironIntakeGoal,
      'notificationsEnabled': notificationsEnabled,
      'preferredLanguage': preferredLanguage,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'lastScanDate': lastScanDate != null ? Timestamp.fromDate(lastScanDate!) : null,
    };
  }

  factory ConsumerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConsumerModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      fullName: data['fullName'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      location: data['location'],
      scannedProducts: List<String>.from(data['scannedProducts'] ?? []),
      trustedSellers: List<String>.from(data['trustedSellers'] ?? []),
      totalScans: data['totalScans'] ?? 0,
      ironIntakeGoal: data['ironIntakeGoal']?.toDouble(),
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      preferredLanguage: data['preferredLanguage'] ?? 'en',
      registrationDate: (data['registrationDate'] as Timestamp).toDate(),
      lastScanDate: data['lastScanDate'] != null
          ? (data['lastScanDate'] as Timestamp).toDate()
          : null,
    );
  }

  ConsumerModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? email,
    Map<String, dynamic>? location,
    List<String>? scannedProducts,
    List<String>? trustedSellers,
    int? totalScans,
    double? ironIntakeGoal,
    bool? notificationsEnabled,
    String? preferredLanguage,
    DateTime? registrationDate,
    DateTime? lastScanDate,
  }) {
    return ConsumerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      location: location ?? this.location,
      scannedProducts: scannedProducts ?? this.scannedProducts,
      trustedSellers: trustedSellers ?? this.trustedSellers,
      totalScans: totalScans ?? this.totalScans,
      ironIntakeGoal: ironIntakeGoal ?? this.ironIntakeGoal,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      registrationDate: registrationDate ?? this.registrationDate,
      lastScanDate: lastScanDate ?? this.lastScanDate,
    );
  }
}
