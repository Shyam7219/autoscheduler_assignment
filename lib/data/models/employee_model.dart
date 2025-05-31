import 'package:flutter/material.dart';
import '../../domain/entities/employee.dart';

class EmployeeModel extends Employee {
  EmployeeModel({
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    required super.isAvailable,
  });

  factory EmployeeModel.fromMap(Map<String, dynamic> map, String docId) {
    try {
      double longitude = 0.0;
      if (map['longitude'] != null) {
        longitude = map['longitude']?.toDouble() ?? 0.0;
      } else if (map['longitute'] != null) {
        longitude = map['longitute']?.toDouble() ?? 0.0;
      }
      
      return EmployeeModel(
        id: docId,
        name: map['name'] ?? "",
        latitude: map['latitude']?.toDouble() ?? 0.0,
        longitude: longitude,
        isAvailable: map['isAvailable'] ?? false,
      );
    } catch (e, st) {
      debugPrint('Error parsing EmployeeModel: $e\n$st');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'isAvailable': isAvailable,
    };
  }
}