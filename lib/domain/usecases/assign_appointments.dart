import 'dart:math';
import '../entities/appointment.dart';
import '../entities/customer.dart';
import '../entities/employee.dart';

class AssignAppointmentsUseCase {
  List<Appointment> assign({
    required List<Customer> customers,
    required List<Employee> employees,
    required DateTime date,
  }) {
    if (customers.isEmpty || employees.isEmpty) {
      return [];
    }

    final random = Random();
    final List<Appointment> appointments = [];

    for (final customer in customers) {
      final employee = employees[random.nextInt(employees.length)];
      
      final appointmentTime = DateTime(
        date.year,
        date.month,
        date.day,
        9,
        0,
      );
      
      final appointmentId = '${customer.id}_${appointmentTime.toIso8601String()}';
      
      final appointment = Appointment(
        id: appointmentId,
        customerId: customer.id,
        employeeId: employee.id,
        time: appointmentTime,
        duration: const Duration(minutes: 30),
        status: 'scheduled',
      );
      
      appointments.add(appointment);
    }

    return appointments;
  }
}