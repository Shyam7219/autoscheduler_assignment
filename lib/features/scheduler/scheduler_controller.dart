import 'package:get/get.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/route_plan.dart';
import '../../domain/usecases/assign_appointments.dart';
import '../../domain/repositories/scheduler_repository.dart';
import '../../features/map/map_controller.dart';

class SchedulerController extends GetxController {
  final SchedulerRepository _repository;
  final AssignAppointmentsUseCase _assignAppointments;
  late final MapController _mapController;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<List<RoutePlan>> weeklyRoutePlans = Rx<List<RoutePlan>>([]);
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  static const double mileageRate = 0.45;
  static const double hourlyRate = 15.0;

  SchedulerController(this._repository, this._assignAppointments) {
    try {
      _mapController = Get.find<MapController>();
    } catch (e) {
      throw Exception('MapController not found: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    generateWeeklyRoutePlans();
  }

  Future<List<Appointment>> assignAndSaveAppointments(DateTime date) async {
    try {
      isLoading.value = true;
      error.value = '';

      final employees = await _repository.getEmployees();
      final customers = await _repository.getCustomers();

      final appointments = _assignAppointments.assign(
        customers: customers,
        employees: employees,
        date: date,
      );

      final List<Appointment> allAppointments = [];

      for (final appointment in appointments) {
        final morningAppointment = appointment;
        await _repository.createAppointment(morningAppointment);
        allAppointments.add(morningAppointment);

        final afternoonTime = DateTime(
          appointment.time.year,
          appointment.time.month,
          appointment.time.day,
          13,
          0,
        );
        final afternoonAppointment = Appointment(
          id: '${appointment.id}_afternoon',
          customerId: appointment.customerId,
          employeeId: appointment.employeeId,
          time: afternoonTime,
          duration: appointment.duration,
          status: appointment.status,
        );
        await _repository.createAppointment(afternoonAppointment);
        allAppointments.add(afternoonAppointment);

        final eveningTime = DateTime(
          appointment.time.year,
          appointment.time.month,
          appointment.time.day,
          17,
          0,
        );
        final eveningAppointment = Appointment(
          id: '${appointment.id}_evening',
          customerId: appointment.customerId,
          employeeId: appointment.employeeId,
          time: eveningTime,
          duration: appointment.duration,
          status: appointment.status,
        );
        await _repository.createAppointment(eveningAppointment);
        allAppointments.add(eveningAppointment);
      }

      await generateWeeklyRoutePlans();

      return allAppointments;
    } catch (e) {
      error.value = e.toString();
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateWeeklyRoutePlans() async {
    try {
      isLoading.value = true;
      error.value = '';

      final employees = await _repository.getEmployees();
      final List<RoutePlan> plans = [];

      final today = DateTime.now();

      for (final employee in employees) {
        for (int i = 0; i < 7; i++) {
          final date = DateTime(today.year, today.month, today.day + i);
          final appointments =
              await _repository.getAppointmentsForEmployeeOnDate(
            employee.id,
            date,
          );

          if (appointments.isEmpty) continue;

          appointments.sort((a, b) => a.time.compareTo(b.time));

          double totalDistance = 0;
          Duration totalTravelTime = Duration.zero;

          double lastLat = employee.latitude;
          double lastLng = employee.longitude;

          for (final appointment in appointments) {
            final customer =
                await _repository.getCustomer(appointment.customerId);

            final distance = await calculateDistanceKm(
              lat1: lastLat,
              lon1: lastLng,
              lat2: customer.latitude,
              lon2: customer.longitude,
            );

            totalDistance += distance;

            final travelTimeMinutes = (distance / 50) * 60;
            totalTravelTime += Duration(minutes: travelTimeMinutes.round());

            lastLat = customer.latitude;
            lastLng = customer.longitude;
          }

          final mileageCost = totalDistance * mileageRate;
          final timeCost = totalTravelTime.inMinutes / 60 * hourlyRate;
          final totalCost = mileageCost + timeCost;

          plans.add(RoutePlan(
            employeeId: employee.id,
            date: date,
            appointments: appointments,
            totalDistanceKm: totalDistance,
            totalTravelTime: totalTravelTime,
            totalCost: totalCost,
          ));
        }
      }

      weeklyRoutePlans.value = plans;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Customer>> getCustomers() => _repository.getCustomers();

  Future<List<Employee>> getEmployees() => _repository.getEmployees();

  Future<List<Appointment>> getAppointments(String employeeId) {
    return _repository.getAppointmentsForEmployee(employeeId);
  }

  Future<List<Appointment>> getAppointmentsForDate(DateTime date) async {
    final employees = await _repository.getEmployees();
    final List<Appointment> allAppointments = [];

    for (final employee in employees) {
      final appointments = await _repository.getAppointmentsForEmployeeOnDate(
        employee.id,
        date,
      );
      allAppointments.addAll(appointments);
    }

    return allAppointments;
  }

  List<RoutePlan> getRoutePlansForEmployee(String employeeId) {
    return weeklyRoutePlans.value
        .where((plan) => plan.employeeId == employeeId)
        .toList();
  }

  List<RoutePlan> getRoutePlansForDate(DateTime date) {
    return weeklyRoutePlans.value
        .where((plan) =>
            plan.date.year == date.year &&
            plan.date.month == date.month &&
            plan.date.day == date.day)
        .toList();
  }

  Future<double> calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) async {
    try {
      if (_mapController != null) {
        return await _mapController.calculateDistanceKm(
            lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2);
      } else {
        const r = 6371;
        final dLat = _deg2rad(lat2 - lat1);
        final dLon = _deg2rad(lon2 - lon1);
        final a = (sin(dLat / 2) * sin(dLat / 2)) +
            cos(_deg2rad(lat1)) *
                cos(_deg2rad(lat2)) *
                sin(dLon / 2) *
                sin(dLon / 2);
        final c = 2 * atan2(sqrt(a), sqrt(1 - a));
        return r * c;
      }
    } catch (e) {
      return 5.0;
    }
  }

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180);

  double sin(double x) => _sin(x);
  double cos(double x) => _cos(x);
  double atan2(double y, double x) => _atan2(y, x);
  double sqrt(double x) => _sqrt(x);

  double _sin(double x) =>
      x -
      (x * x * x) / 6 +
      (x * x * x * x * x) / 120 -
      (x * x * x * x * x * x * x) / 5040;
  double _cos(double x) =>
      1 - (x * x) / 2 + (x * x * x * x) / 24 - (x * x * x * x * x * x) / 720;
  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 1.5707963267948966;
    if (x == 0 && y < 0) return -1.5707963267948966;
    return 0.0;
  }

  double _atan(double x) =>
      x -
      (x * x * x) / 3 +
      (x * x * x * x * x) / 5 -
      (x * x * x * x * x * x * x) / 7;
  double _sqrt(double x) => x / (1 + (1 - x / 4));
}
