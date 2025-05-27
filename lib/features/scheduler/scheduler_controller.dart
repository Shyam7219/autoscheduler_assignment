import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/employee.dart';
import '../../domain/usecases/assign_appointments.dart';
import '../../domain/repositories/scheduler_repository.dart';
import '../../providers.dart';

final schedulerControllerProvider = Provider<SchedulerController>((ref) {
  final repository = ref.watch(schedulerRepositoryProvider);
  final assigner = ref.watch(assignAppointmentsProvider);
  return SchedulerController(repository, assigner);
});

class SchedulerController {
  final SchedulerRepository _repository;
  final AssignAppointmentsUseCase _assignAppointments;

  SchedulerController(this._repository, this._assignAppointments);

  Future<List<Appointment>> assignAndSaveAppointments(DateTime date) async {
    final employees = await _repository.getEmployees();
    final customers = await _repository.getCustomers();

    final appointments = _assignAppointments.assign(
      customers: customers,
      employees: employees,
      date: date,
    );

    for (final appointment in appointments) {
      await _repository.createAppointment(appointment);
    }

    return appointments;
  }

  Future<List<Customer>> getCustomers() => _repository.getCustomers();

  Future<List<Employee>> getEmployees() => _repository.getEmployees();

  Future<List<Appointment>> getAppointments(String employeeId) {
    return _repository.getAppointmentsForEmployee(employeeId);
  }
}
