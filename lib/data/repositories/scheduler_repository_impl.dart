import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/scheduler_repository.dart';
import '../models/appointment_model.dart';
import '../models/customer_model.dart';
import '../models/employee_model.dart';

class SchedulerRepositoryImpl implements SchedulerRepository {
  final FirebaseFirestore firestore;

  SchedulerRepositoryImpl(this.firestore);

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    final snapshot = await firestore.collection('employees').get();
    return snapshot.docs
        .map((doc) => EmployeeModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<Customer>> getCustomers() async {
    final snapshot = await firestore.collection('customers').get();
    return snapshot.docs
        .map((doc) => CustomerModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> createAppointment(Appointment appointment) async {
    final model = AppointmentModel(
      id: appointment.id,
      employeeId: appointment.employeeId,
      customerId: appointment.customerId,
      time: appointment.time,
    );
    await firestore
        .collection('appointments')
        .doc(appointment.id)
        .set(model.toMap());
  }

  @override
  Future<List<Appointment>> getAppointmentsForEmployee(
    String employeeId,
  ) async {
    final snapshot =
        await firestore
            .collection('appointments')
            .where('employeeId', isEqualTo: employeeId)
            .get();

    return snapshot.docs
        .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> updateEmployeeLocation(
    String employeeId,
    double lat,
    double lng,
  ) async {
    await firestore.collection('employees').doc(employeeId).update({
      'latitude': lat,
      'longitude': lng,
    });
  }
}
