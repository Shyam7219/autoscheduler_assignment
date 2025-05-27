class Appointment {
  final String id;
  final String employeeId;
  final String customerId;
  final DateTime time;

  Appointment({
    required this.id,
    required this.employeeId,
    required this.customerId,
    required this.time,
  });
}
