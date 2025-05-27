import 'package:flutter/material.dart';
import '../../domain/entities/appointment.dart';

class AppointmentTile extends StatelessWidget {
  final Appointment appointment;

  const AppointmentTile({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Employee: ${appointment.employeeId}'),
      subtitle: Text('Time: ${appointment.time.toLocal()}'),
    );
  }
}
