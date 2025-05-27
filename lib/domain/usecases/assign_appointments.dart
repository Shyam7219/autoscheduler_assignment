import 'dart:math';
import '../entities/customer.dart';
import '../entities/employee.dart';
import '../entities/appointment.dart';

class AssignAppointmentsUseCase {
  static const double milesCharge = 0.45;
  static const double hourlyCharge = 15.0;

  List<Appointment> assign({
    required List<Customer> customers,
    required List<Employee> employees,
    required DateTime date,
  }) {
    List<Appointment> assignments = [];

    for (Customer customer in customers) {
      for (DateTime time in customer.recurringTimes) {
        Employee? bestEmployee;
        double minDistance = double.infinity;

        for (final emp in employees.where((e) => e.isAvailable)) {
          final dist = _calculateDistance(
            emp.latitude,
            emp.longitude,
            customer.latitude,
            customer.longitude,
          );

          if (dist < minDistance) {
            bestEmployee = emp;
            minDistance = dist;
          }
        }

        if (bestEmployee != null) {
          assignments.add(
            Appointment(
              id: '${customer.id}_${time.toIso8601String()}',
              employeeId: bestEmployee.id,
              customerId: customer.id,
              time: time,
            ),
          );
        }
      }
    }

    return assignments;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371; // Radius of earth in km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c; // Distance in km
  }

  double _deg2rad(double deg) => deg * (pi / 180);
}
