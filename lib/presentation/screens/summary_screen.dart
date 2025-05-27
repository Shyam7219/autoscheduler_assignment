import 'dart:io';
import 'package:autoscheduler_assignment/domain/entities/appointment_summary.dart';
import 'package:autoscheduler_assignment/features/map/map_controller.dart';
import 'package:autoscheduler_assignment/presentation/viewmodels/summary_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  String selectedEmployeeId = '';

  Future<void> exportToCSV(List<AppointmentSummary> data) async {
    final List<List<dynamic>> csvData = [
      [
        'Employee ID',
        'Customer ID',
        'Time',
        'Distance (km)',
        'Travel Time (min)',
        'Cost (£)',
      ],
      ...data.map(
        (item) => [
          item.appointment.employeeId,
          item.appointment.customerId,
          item.appointment.time.toIso8601String(),
          item.distanceKm.toStringAsFixed(2),
          item.travelTime.inMinutes,
          item.cost.toStringAsFixed(2),
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    final dir = await getExternalStorageDirectory();
    final path = '${dir!.path}/appointment_summary.csv';

    final file = File(path);
    await file.writeAsString(csv);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV exported to: $path')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeFuture =
        ref.watch(mapControllerProvider).fetchLiveEmployees();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export as CSV',
            onPressed: () async {
              if (selectedEmployeeId.isNotEmpty) {
                final list = await ref.read(
                  summaryViewModelProvider(selectedEmployeeId).future,
                );
                await exportToCSV(list.cast<AppointmentSummary>());
              }
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: employeeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final employees = snapshot.data ?? [];

          if (employees.isEmpty) {
            return const Center(child: Text('No employees found'));
          }

          selectedEmployeeId =
              selectedEmployeeId.isEmpty
                  ? employees.first.id
                  : selectedEmployeeId;

          final summaryAsync = ref.watch(
            summaryViewModelProvider(selectedEmployeeId),
          );

          return Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<String>(
                  value: selectedEmployeeId,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.black),
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
                      });
                    }
                  },
                ),
              ),
              const Divider(),
              Expanded(
                child: summaryAsync.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (summaryList) {
                    if (summaryList.isEmpty) {
                      return const Center(
                        child: Text('No appointments found.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: summaryList.length,
                      itemBuilder: (context, index) {
                        final s = summaryList[index];
                        return ListTile(
                          title: Text(
                            'Employee: ${s.appointment.employeeId} | Customer: ${s.appointment.customerId}',
                          ),
                          subtitle: Text(
                            'DateTime: ${s.appointment.time}\n'
                            'Distance: ${s.distanceKm.toStringAsFixed(2)} km\n'
                            'Travel Time: ${s.travelTime.inMinutes} minutes\n'
                            'Cost: £${s.cost.toStringAsFixed(2)}',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
