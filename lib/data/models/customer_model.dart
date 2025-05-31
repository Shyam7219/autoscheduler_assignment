import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  CustomerModel({
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    super.recurringTimes = const [],
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map, String docId) {
    try {
      List<DateTime> recurringTimes = [];
      if (map['recurringTimes'] != null) {
        recurringTimes = (map['recurringTimes'] as List)
            .map((time) => (time as Timestamp).toDate())
            .toList();
      }
      
      return CustomerModel(
        id: docId,
        name: map['name'] ?? "",
        latitude: map['latitude']?.toDouble() ?? 0.0,
        longitude: map['longitude']?.toDouble() ?? 0.0,
        recurringTimes: recurringTimes,
      );
    } catch (e, st) {
      debugPrint('Error parsing CustomerModel: $e\n$st');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'recurringTimes': recurringTimes.map((time) => Timestamp.fromDate(time)).toList(),
    };
  }
}