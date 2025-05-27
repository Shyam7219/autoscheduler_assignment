import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/scheduler_repository.dart';
import '../../providers.dart';

final mapControllerProvider = Provider<MapController>((ref) {
  final repository = ref.watch(schedulerRepositoryProvider);
  return MapController(repository);
});

class MapController {
  final SchedulerRepository _repository;

  MapController(this._repository);

  Future<List<Employee>> fetchLiveEmployees() {
    return _repository.getEmployees();
  }

  Future<void> updateLocation({
    required String employeeId,
    required double lat,
    required double lng,
  }) async {
    await _repository.updateEmployeeLocation(employeeId, lat, lng);
  }

  // for letter use
  Future<double> calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) async {
    const r = 6371; // Radius of Earth in km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180);
}
