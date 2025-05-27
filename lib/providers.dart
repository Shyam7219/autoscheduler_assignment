import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/datasources/firebase/firebase_service.dart';
import 'data/datasources/google_maps/maps_service.dart';
import 'data/repositories/scheduler_repository_impl.dart';
import 'domain/usecases/assign_appointments.dart';
import 'domain/usecases/calculate_route_cost.dart';
import 'domain/repositories/scheduler_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final mapsServiceProvider = Provider<MapsService>((ref) {
  const apiKey = 'AIzaSyAo7Q-K1jAJ7zQOw0wXHFKPlOy4WBsBwIY';
  return MapsService(apiKey);
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseService(firestore);
});

final schedulerRepositoryProvider = Provider<SchedulerRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return SchedulerRepositoryImpl(firestore);
});

final assignAppointmentsProvider = Provider<AssignAppointmentsUseCase>((ref) {
  return AssignAppointmentsUseCase();
});

final routeCostCalculatorProvider = Provider<CalculateRouteCostUseCase>((ref) {
  return CalculateRouteCostUseCase();
});
