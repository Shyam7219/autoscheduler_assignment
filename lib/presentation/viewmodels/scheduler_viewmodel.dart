import 'package:autoscheduler_assignment/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/assign_appointments.dart';
import '../../domain/repositories/scheduler_repository.dart';

final schedulerViewModelProvider =
    StateNotifierProvider<SchedulerViewModel, AsyncValue<List<Appointment>>>((
      ref,
    ) {
      final assigner = ref.watch(assignAppointmentsProvider);
      final repository = ref.watch(schedulerRepositoryProvider);
      return SchedulerViewModel(assigner, repository);
    });

class SchedulerViewModel extends StateNotifier<AsyncValue<List<Appointment>>> {
  final AssignAppointmentsUseCase assignUseCase;
  final SchedulerRepository repository;

  SchedulerViewModel(this.assignUseCase, this.repository)
    : super(const AsyncLoading());

  Future<void> loadAndAssignAppointments(DateTime date) async {
    try {
      state = const AsyncLoading();

      final employees = await repository.getEmployees();
      final customers = await repository.getCustomers();

      final appointments = assignUseCase.assign(
        customers: customers,
        employees: employees,
        date: date,
      );

      for (var appointment in appointments) {
        await repository.createAppointment(appointment);
      }

      state = AsyncData(appointments);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
