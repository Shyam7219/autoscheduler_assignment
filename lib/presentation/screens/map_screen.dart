import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../viewmodels/map_viewmodel.dart';
import '../../features/map/map_controller.dart';
import '../../domain/repositories/scheduler_repository.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapViewModel _viewModel = Get.find<MapViewModel>();
  final MapController _mapController = Get.find<MapController>();
  final SchedulerRepository _repository = Get.find<SchedulerRepository>();
  GoogleMapController? _googleMapController;
  String selectedEmployeeId = '';
  DateTime selectedDate = DateTime.now();
  bool _showDateFilter = false;
  Timer? _locationUpdateTimer;
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _viewModel.fetchEmployees();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _simulateLocationUpdates();
    });
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }

  Future<void> _simulateLocationUpdates() async {
    if (_viewModel.employees.value.isEmpty) return;

    final random = DateTime.now().millisecondsSinceEpoch %
        _viewModel.employees.value.length;
    final employee = _viewModel.employees.value[random];
    final latChange = (DateTime.now().millisecondsSinceEpoch % 20 - 10) / 10000;
    final lngChange = (DateTime.now().millisecondsSinceEpoch % 20 - 10) / 10000;

    await _mapController.updateLocation(
      employeeId: employee.id,
      lat: employee.latitude + latChange,
      lng: employee.longitude + lngChange,
    );

    _viewModel.fetchEmployees();
  }

  // Draw directions between employee and customer
  Future<void> _drawDirections(String employeeId) async {
    try {
      final employees = _viewModel.employees.value;
      var selectedEmployee = employees.first;
      for (var emp in employees) {
        if (emp.id == employeeId) {
          selectedEmployee = emp;
          break;
        }
      }

      final customers = await _repository.getCustomers();
      if (customers.isEmpty) return;

      final customer = customers.first;

      // polyline points
      List<LatLng> polylineCoordinates = [];

      // Simple straight line for demo
      polylineCoordinates
          .add(LatLng(selectedEmployee.latitude, selectedEmployee.longitude));
      polylineCoordinates.add(LatLng(customer.latitude, customer.longitude));

      setState(() {
        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          points: polylineCoordinates,
          width: 5,
        ));
      });

      // customer marker
      setState(() {
        _customerMarkers.clear();
        _customerMarkers.add(
          Marker(
            markerId: MarkerId(customer.id),
            position: LatLng(customer.latitude, customer.longitude),
            infoWindow: InfoWindow(
              title: customer.name,
              snippet: 'Customer',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet),
          ),
        );
      });
    } catch (e) {
      throw Exception('Error drawing directions: $e');
    }
  }

  final Set<Marker> _customerMarkers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Tracking'),
        actions: [
          // Toggle between employee and date filters
          IconButton(
            icon: Icon(_showDateFilter ? Icons.person : Icons.calendar_today),
            onPressed: () {
              setState(() {
                _showDateFilter = !_showDateFilter;
              });
            },
            tooltip: _showDateFilter ? 'Filter by Employee' : 'Filter by Date',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter controls
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 60,
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                _showDateFilter ? _buildDateFilter() : _buildEmployeeFilter(),
          ),

          // Map view
          Expanded(
            child: Obx(() {
              if (_viewModel.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_viewModel.error.value.isNotEmpty) {
                return Center(child: Text('Error: ${_viewModel.error.value}'));
              }

              final employees = _viewModel.employees.value;

              if (employees.isEmpty) {
                return const Center(child: Text('No employees found.'));
              }

              if (selectedEmployeeId.isEmpty) {
                selectedEmployeeId = employees.first.id;
                // Draw directions when employee is selected
                _drawDirections(selectedEmployeeId);
              }

              // Find the selected employee
              var selectedEmployee = employees.first;
              for (var emp in employees) {
                if (emp.id == selectedEmployeeId) {
                  selectedEmployee = emp;
                  break;
                }
              }

              // markers for all employees
              final markers = employees
                  .map(
                    (e) => Marker(
                      markerId: MarkerId(e.id),
                      position: LatLng(e.latitude, e.longitude),
                      infoWindow: InfoWindow(
                        title: e.name,
                        snippet:
                            'Status: ${e.isAvailable ? 'Available' : 'Busy'}',
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        e.id == selectedEmployeeId
                            ? BitmapDescriptor.hueBlue
                            : (e.isAvailable
                                ? BitmapDescriptor.hueGreen
                                : BitmapDescriptor.hueRed),
                      ),
                    ),
                  )
                  .toSet();

              // Add customer markers
              markers.addAll(_customerMarkers);

              return Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) {
                      _googleMapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        selectedEmployee.latitude,
                        selectedEmployee.longitude,
                      ),
                      zoom: 12,
                    ),
                    markers: markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                  ),

                  // Live tracking indicator
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Live Tracking',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Legend
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLegendItem(
                            Colors.blue,
                            'Selected Employee',
                          ),
                          const SizedBox(height: 4),
                          _buildLegendItem(
                            Colors.green,
                            'Available',
                          ),
                          const SizedBox(height: 4),
                          _buildLegendItem(
                            Colors.red,
                            'Busy',
                          ),
                          const SizedBox(height: 4),
                          _buildLegendItem(
                            Colors.purple,
                            'Customer',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeFilter() {
    return Center(
      child: Obx(() {
        final employees = _viewModel.employees.value;
        return DropdownButton<String>(
          value: selectedEmployeeId.isEmpty ? null : selectedEmployeeId,
          hint: const Text('Select Employee'),
          isExpanded: true,
          items: employees
              .map(
                (e) => DropdownMenuItem<String>(
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
                var selectedEmployee = _viewModel.employees.value.first;
                for (var emp in _viewModel.employees.value) {
                  if (emp.id == selectedEmployeeId) {
                    selectedEmployee = emp;
                    break;
                  }
                }
                _drawDirections(selectedEmployeeId);
                _googleMapController?.animateCamera(
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
        );
      }),
    );
  }

  Widget _buildDateFilter() {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Row(
      children: [
        Expanded(
          child: Text(
            'Date: ${dateFormat.format(selectedDate)}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 7)),
              lastDate: DateTime.now().add(const Duration(days: 14)),
            );

            if (picked != null) {
              setState(() {
                selectedDate = picked;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
