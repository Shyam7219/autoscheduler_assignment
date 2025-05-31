import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../data/datasources/firebase/firebase_service.dart';
import '../data/datasources/google_maps/maps_service.dart';
import '../data/repositories/scheduler_repository_impl.dart';
import '../domain/repositories/scheduler_repository.dart';
import '../domain/usecases/assign_appointments.dart';
import '../domain/usecases/calculate_route_cost.dart';
import '../features/map/map_controller.dart';
import '../features/scheduler/scheduler_controller.dart';
import '../presentation/viewmodels/map_viewmodel.dart';
import '../presentation/viewmodels/scheduler_viewmodel.dart';
import '../presentation/viewmodels/summary_viewmodel.dart';

class DependencyInjection {
  static final firestore = FirebaseFirestore.instance;
  static final mapsService =
      MapsService('AIzaSyAo7Q-K1jAJ7zQOw0wXHFKPlOy4WBsBwIY');
  static final firebaseService = FirebaseService(firestore);
  static final schedulerRepository = SchedulerRepositoryImpl(firestore);
  static final assignAppointmentsUseCase = AssignAppointmentsUseCase();
  static final calculateRouteCostUseCase = CalculateRouteCostUseCase();
  static final mapController = MapController(schedulerRepository);
  static final schedulerController =
      SchedulerController(schedulerRepository, assignAppointmentsUseCase);
  static final mapViewModel = MapViewModel();
  static final schedulerViewModel = SchedulerViewModel();
  static final summaryViewModel = SummaryViewModel();

  static void init() {
    try {
      // Register dependencies with GetX
      Get.put(firestore, permanent: true);
      Get.put(mapsService, permanent: true);
      Get.put(firebaseService, permanent: true);
      Get.put<SchedulerRepository>(schedulerRepository, permanent: true);
      Get.put(assignAppointmentsUseCase, permanent: true);
      Get.put(calculateRouteCostUseCase, permanent: true);
      Get.put(mapController, permanent: true);
      Get.put(schedulerController, permanent: true);
      Get.put(mapViewModel, permanent: true);
      Get.put(schedulerViewModel, permanent: true);
      Get.put(summaryViewModel, permanent: true);
    } catch (e) {
      throw Exception('Error initializing dependencies: $e');
    }
  }

  // Helper methods to get dependencies without using Get.find
  static MapController getMapController() => mapController;
  static SchedulerController getSchedulerController() => schedulerController;
  static MapViewModel getMapViewModel() => mapViewModel;
  static SummaryViewModel getSchedulerViewModel() => summaryViewModel;
  static SummaryViewModel getSummaryViewModel() => summaryViewModel;
}
