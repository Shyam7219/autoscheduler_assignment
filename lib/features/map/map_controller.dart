import 'package:get/get.dart';
import '../../domain/repositories/scheduler_repository.dart';
import 'dart:math' as math;

class MapController extends GetxController {
  final SchedulerRepository _repository;

  MapController(this._repository);

  Future<List<dynamic>> fetchLiveEmployees() async {
    try {
      final employees = await _repository.getEmployees();
      return employees;
    } catch (e) {
      return [];
    }
  }

  Future<void> updateLocation({
    required String employeeId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _repository.updateEmployeeLocation(employeeId, lat, lng);
    } catch (e) {
      throw Exception('EError updating location: $e');
    }
  }

  Future<double> calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) async {
    const r = 6371;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);
}
