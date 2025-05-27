import 'package:autoscheduler_assignment/presentation/viewmodels/map_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  String selectedEmployeeId = '';

  @override
  Widget build(BuildContext context) {
    final employeeAsync = ref.watch(employeeLocationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Employee Map')),
      body: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) {
          debugPrint('Error: $e');
          debugPrint('Stack: $stack');
          return Center(child: Text('Error: $e'));
        },
        data: (employees) {
          if (employees.isEmpty) {
            return const Center(child: Text('No employees found.'));
          }

          selectedEmployeeId =
              selectedEmployeeId.isEmpty
                  ? employees.first.id
                  : selectedEmployeeId;

          final selectedEmployee = employees.firstWhere(
            (e) => e.id == selectedEmployeeId,
            orElse: () => employees.first,
          );

          final markers =
              employees
                  .map(
                    (e) => Marker(
                      markerId: MarkerId(e.id),
                      position: LatLng(e.latitude, e.longitude),
                      infoWindow: InfoWindow(title: e.name),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        e.id == selectedEmployeeId
                            ? BitmapDescriptor.hueBlue
                            : BitmapDescriptor.hueGreen,
                      ),
                    ),
                  )
                  .toSet();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: selectedEmployeeId,
                  isExpanded: true,
                  items:
                      employees
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(
                                e.name,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedEmployeeId = val;
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(
                            LatLng(
                              selectedEmployee.latitude,
                              selectedEmployee.longitude,
                            ),
                          ),
                        );
                      });
                    }
                  },
                ),
              ),
              Expanded(
                child: GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      selectedEmployee.latitude,
                      selectedEmployee.longitude,
                    ),
                    zoom: 12,
                  ),
                  markers: markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
