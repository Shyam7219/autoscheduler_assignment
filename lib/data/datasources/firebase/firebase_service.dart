import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/appointment.dart';
import '../../models/employee_model.dart';
import '../../models/customer_model.dart';
import '../../models/appointment_model.dart';

class FirebaseService {
  final FirebaseFirestore firestore;

  FirebaseService(this.firestore);

  Future<List<Employee>> fetchEmployees() async {
    final snapshot = await firestore.collection('employees').get();
    return snapshot.docs
        .map((doc) => EmployeeModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<Customer>> fetchCustomers() async {
    final snapshot = await firestore.collection('customers').get();
    return snapshot.docs
        .map((doc) => CustomerModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> saveAppointment(Appointment appointment) async {
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
}
