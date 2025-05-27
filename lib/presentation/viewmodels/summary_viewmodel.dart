import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autoscheduler_assignment/domain/entities/appointment.dart';
import 'package:autoscheduler_assignment/providers.dart';

class SummaryData {
  final Appointment appointment;
  final double distanceKm;
  final Duration travelTime;
  final double cost;

  SummaryData({
    required this.appointment,
    required this.distanceKm,
    required this.travelTime,
    required this.cost,
  });
}

// Currently uses dummy distance, time, and cost values.
// logic will be replace with real Google Directions API calls if needed.
final summaryViewModelProvider =
    FutureProvider.family<List<SummaryData>, String>((ref, employeeId) async {
      final repo = ref.watch(schedulerRepositoryProvider);
      final appointments = await repo.getAppointmentsForEmployee(employeeId);

      const mileageRate = 0.45; // £/km
      const hourlyRate = 15.0; // £/hour

      // Dummy calculations for summary
      return appointments.map((appointment) {
        const distance = 5.0; // in kilometers
        const duration = Duration(minutes: 30); // travel time
        final cost =
            (distance * mileageRate) + (duration.inMinutes / 60) * hourlyRate;

        return SummaryData(
          appointment: appointment,
          distanceKm: distance,
          travelTime: duration,
          cost: cost,
        );
      }).toList();
    });
