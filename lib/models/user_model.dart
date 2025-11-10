import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String userType;
  final String? name; // User's name or organization name (optional for backwards compatibility)
  final String email;
  final String phone;
  final String? phoneNumber; // Alias for phone
  final String language;
  final DateTime? createdAt;
  final bool isVerified;
  final Map<String, dynamic>? location;
  final String? status;

  UserModel({
    required this.id,
    required this.userType,
    this.name,
    required this.email,
    required this.phone,
    this.phoneNumber,
    required this.language,
    this.createdAt,
    this.isVerified = false,
    this.location,
    this.status,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userType': userType,
      'name': name,
      'email': email,
      'phone': phone,
      'phoneNumber': phoneNumber ?? phone,
      'language': language,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'isVerified': isVerified,
      'location': location,
      'status': status,
    };
  }

  // Create from Firestore Document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      userType: data['userType'] ?? '',
      name: data['name'] ?? data['email'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      phoneNumber: data['phoneNumber'] ?? data['phone'],
      language: data['language'] ?? 'en',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      isVerified: data['isVerified'] ?? false,
      location: data['location'],
      status: data['status'],
    );
  }

  // Helper method to get display name (name or email fallback)
  String get displayName => name ?? email.split('@')[0];

  UserModel copyWith({
    String? id,
    String? userType,
    String? name,
    String? email,
    String? phone,
    String? phoneNumber,
    String? language,
    DateTime? createdAt,
    bool? isVerified,
    Map<String, dynamic>? location,
    String? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      userType: userType ?? this.userType,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      phoneNumber: phoneNumber ?? this.phoneNumber ?? phone,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      location: location ?? this.location,
      status: status ?? this.status,
    );
  }
}
