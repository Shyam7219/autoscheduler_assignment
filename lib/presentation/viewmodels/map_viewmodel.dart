import 'package:autoscheduler_assignment/data/models/employee_model.dart';
import 'package:autoscheduler_assignment/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final employeeLocationProvider = FutureProvider<List<EmployeeModel>>((
  ref,
) async {
  final repo = ref.watch(schedulerRepositoryProvider);
  return await repo.getEmployees();
});
