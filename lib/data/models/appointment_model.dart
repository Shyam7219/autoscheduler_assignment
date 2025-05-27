import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/appointment.dart';

class AppointmentModel extends Appointment {
  AppointmentModel({
    required super.id,
    required super.employeeId,
    required super.customerId,
    required super.time,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String docId) {
    try {
      final rawTime = map['time'];
      DateTime parsedTime;

      if (rawTime is Timestamp) {
        parsedTime = rawTime.toDate();
      } else if (rawTime is String) {
        parsedTime = DateTime.parse(rawTime);
      } else {
        throw Exception('Unsupported time format in Firestore: $rawTime');
      }

      return AppointmentModel(
        id: docId,
        employeeId: map['employeeId'] ?? '',
        customerId: map['customerId'] ?? '',
        time: parsedTime,
      );
    } catch (e, st) {
      debugPrint(' Error parsing AppointmentModel: $e\n$st');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'customerId': customerId,
      'time': Timestamp.fromDate(time),
    };
  }
}
