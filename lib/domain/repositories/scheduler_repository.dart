import '../entities/appointment.dart';
import '../entities/customer.dart';
import '../entities/employee.dart';

abstract class SchedulerRepository {
  Future<List<Employee>> getEmployees();
  
  Future<List<Customer>> getCustomers();
  
  Future<Customer> getCustomer(String customerId);
  
  Future<void> createAppointment(Appointment appointment);
  
  Future<List<Appointment>> getAppointmentsForEmployee(String employeeId);
  
  Future<List<Appointment>> getAppointmentsForEmployeeOnDate(
    String employeeId, 
    DateTime date
  );
  
  Future<void> updateEmployeeLocation(String employeeId, double lat, double lng);
}