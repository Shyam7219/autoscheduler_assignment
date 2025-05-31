import 'appointment.dart';

class RoutePlan {
  final String employeeId;
  final DateTime date;
  final List<Appointment> appointments;
  final double totalDistanceKm;
  final Duration totalTravelTime;
  final double totalCost;

  RoutePlan({
    required this.employeeId,
    required this.date,
    required this.appointments,
    required this.totalDistanceKm,
    required this.totalTravelTime,
    required this.totalCost,
  });
}