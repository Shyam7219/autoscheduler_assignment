import 'package:autoscheduler_assignment/data/models/employee_model.dart';

import '../entities/customer.dart';
import '../entities/appointment.dart';

abstract class SchedulerRepository {
  Future<List<EmployeeModel>> getEmployees();
  Future<List<Customer>> getCustomers();
  Future<void> createAppointment(Appointment appointment);
  Future<List<Appointment>> getAppointmentsForEmployee(String employeeId);
  Future<void> updateEmployeeLocation(
    String employeeId,
    double lat,
    double lng,
  );
}
