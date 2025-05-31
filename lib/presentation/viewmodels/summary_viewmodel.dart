import 'package:get/get.dart';
import '../../domain/entities/appointment_summary.dart';
import '../../domain/repositories/scheduler_repository.dart';

class SummaryViewModel extends GetxController {
  final SchedulerRepository _repository = Get.find<SchedulerRepository>();

  final RxBool isLoading = false.obs;
  final Rx<List<AppointmentSummary>> summaryData =
      Rx<List<AppointmentSummary>>([]);
  final RxString error = ''.obs;

  Future<List<AppointmentSummary>> getSummaryForEmployee(
      String employeeId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final appointments =
          await _repository.getAppointmentsForEmployee(employeeId);

      const mileageRate = 0.45; // £/km
      const hourlyRate = 15.0; // £/hour

      // Dummy calculations for summary
      final result = appointments.map((appointment) {
        const distance = 5.0; // in kilometers
        const duration = Duration(minutes: 30); // travel time
        final cost =
            (distance * mileageRate) + (duration.inMinutes / 60) * hourlyRate;

        return AppointmentSummary(
          appointment: appointment,
          distanceKm: distance,
          travelTime: duration,
          cost: cost,
        );
      }).toList();

      summaryData.value = result;
      return result;
    } catch (e) {
      error.value = e.toString();
      return [];
    } finally {
      isLoading.value = false;
    }
  }
}
