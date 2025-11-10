import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String district;
  final String sector;
  final String cell;
  final GeoPoint? gps;

  LocationModel({
    required this.district,
    required this.sector,
    required this.cell,
    this.gps,
  });

  Map<String, dynamic> toMap() {
    return {
      'district': district,
      'sector': sector,
      'cell': cell,
      if (gps != null) 'gps': gps,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      district: map['district'] ?? '',
      sector: map['sector'] ?? '',
      cell: map['cell'] ?? '',
      gps: map['gps'] as GeoPoint?,
    );
  }

  LocationModel copyWith({
    String? district,
    String? sector,
    String? cell,
    GeoPoint? gps,
  }) {
    return LocationModel(
      district: district ?? this.district,
      sector: sector ?? this.sector,
      cell: cell ?? this.cell,
      gps: gps ?? this.gps,
    );
  }
}
