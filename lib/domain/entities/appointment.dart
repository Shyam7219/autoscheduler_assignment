class Appointment {
  final String id;
  final String employeeId;
  final String customerId;
  final DateTime time;
  final Duration duration;
  final String status;

  Appointment({
    required this.id,
    required this.employeeId,
    required this.customerId,
    required this.time,
    this.duration = const Duration(minutes: 30),
    this.status = 'scheduled',
  });
}