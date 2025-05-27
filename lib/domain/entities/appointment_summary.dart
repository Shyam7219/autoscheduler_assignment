import 'appointment.dart';

class AppointmentSummary {
  final Appointment appointment;
  final double distanceKm;
  final Duration travelTime;
  final double cost;

  AppointmentSummary({
    required this.appointment,
    required this.distanceKm,
    required this.travelTime,
    required this.cost,
  });
}
