import 'package:get/get.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/assign_appointments.dart';
import '../../domain/repositories/scheduler_repository.dart';

class SchedulerViewModel extends GetxController {
  final AssignAppointmentsUseCase _assignUseCase = Get.find<AssignAppointmentsUseCase>();
  final SchedulerRepository _repository = Get.find<SchedulerRepository>();
  
  final RxBool isLoading = false.obs;
  final Rx<List<Appointment>> appointments = Rx<List<Appointment>>([]);
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final employees = await _repository.getEmployees();
      final List<Appointment> allAppointments = [];
      
      for (final employee in employees) {
        final employeeAppointments = await _repository.getAppointmentsForEmployee(employee.id);
        allAppointments.addAll(employeeAppointments);
      }
      
      appointments.value = allAppointments;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAndAssignAppointments(DateTime date) async {
    try {
      isLoading.value = true;
      error.value = '';

      final employees = await _repository.getEmployees();
      final customers = await _repository.getCustomers();

      final result = _assignUseCase.assign(
        customers: customers,
        employees: employees,
        date: date,
      );

      for (var appointment in result) {
        await _repository.createAppointment(appointment);
      }

      await loadAppointments();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}