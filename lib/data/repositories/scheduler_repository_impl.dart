import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/scheduler_repository.dart';
import '../models/appointment_model.dart';
import '../models/customer_model.dart';
import '../models/employee_model.dart';

class SchedulerRepositoryImpl implements SchedulerRepository {
  final FirebaseFirestore _firestore;

  SchedulerRepositoryImpl(this._firestore);

  @override
  Future<List<Employee>> getEmployees() async {
    try {
      final snapshot = await _firestore.collection('employees').get();

      final employees = snapshot.docs
          .map((doc) => EmployeeModel.fromMap(doc.data(), doc.id))
          .toList();

      return employees;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Customer>> getCustomers() async {
    try {
      final snapshot = await _firestore.collection('customers').get();

      final customers = snapshot.docs
          .map((doc) => CustomerModel.fromMap(doc.data(), doc.id))
          .toList();

      return customers;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Customer> getCustomer(String customerId) async {
    try {
      final doc =
          await _firestore.collection('customers').doc(customerId).get();
      if (!doc.exists) {
        throw Exception('Customer not found');
      }

      final customer = CustomerModel.fromMap(doc.data()!, doc.id);

      return customer;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> createAppointment(Appointment appointment) async {
    final appointmentMap = {
      'customerId': appointment.customerId,
      'employeeId': appointment.employeeId,
      'time': Timestamp.fromDate(appointment.time),
      'duration': appointment.duration.inMinutes,
      'status': appointment.status,
    };

    if (appointment.id.isEmpty) {
      await _firestore.collection('appointments').add(appointmentMap);
    } else {
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .set(appointmentMap);
    }
  }

  @override
  Future<List<Appointment>> getAppointmentsForEmployee(
      String employeeId) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('employeeId', isEqualTo: employeeId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppointmentModel(
          id: doc.id,
          customerId: data['customerId'],
          employeeId: data['employeeId'],
          time: (data['time'] as Timestamp).toDate(),
          duration: Duration(minutes: data['duration']),
          status: data['status'] ?? 'scheduled',
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Appointment>> getAppointmentsForEmployeeOnDate(
      String employeeId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('appointments')
          .where('employeeId', isEqualTo: employeeId)
          .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('time', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppointmentModel(
          id: doc.id,
          customerId: data['customerId'],
          employeeId: data['employeeId'],
          time: (data['time'] as Timestamp).toDate(),
          duration: Duration(minutes: data['duration']),
          status: data['status'] ?? 'scheduled',
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateEmployeeLocation(
      String employeeId, double lat, double lng) async {
    await _firestore.collection('employees').doc(employeeId).update({
      'latitude': lat,
      'longitude': lng,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}
