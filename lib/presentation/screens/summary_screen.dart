import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:open_file/open_file.dart';
import '../../domain/entities/appointment_summary.dart';
import '../../features/map/map_controller.dart';
import '../viewmodels/summary_viewmodel.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final MapController _mapController = Get.find<MapController>();
  final SummaryViewModel _summaryViewModel = Get.find<SummaryViewModel>();
  String selectedEmployeeId = '';
  final RxBool _isLoading = false.obs;
  final RxList<dynamic> _employees = <dynamic>[].obs;
  bool _showChart = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    _isLoading.value = true;
    try {
      final employees = await _mapController.fetchLiveEmployees();

      _employees.value = employees;
      if (employees.isNotEmpty && selectedEmployeeId.isEmpty) {
        selectedEmployeeId = employees.first.id;
        _loadSummaryData();
      }
    } catch (e) {
      throw Exception('Failed to load employees: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadSummaryData() async {
    if (selectedEmployeeId.isNotEmpty) {
      await _summaryViewModel.getSummaryForEmployee(selectedEmployeeId);
    }
  }

  Future<void> exportToCSV(List<AppointmentSummary> data) async {
    if (data.isEmpty) {
      Get.snackbar(
        'Export Error',
        'No data to export',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
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

      final now = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'appointment_summary_$now.csv';

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';
      final file = File(path);

      await file.writeAsString(csv);

      Get.defaultDialog(
        title: 'Export Success',
        middleText: 'CSV file has been saved successfully.',
        textConfirm: 'Open File',
        textCancel: 'Close',
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back();
          OpenFile.open(path);
        },
        onCancel: () => Get.back(),
      );
    } catch (e) {
      Get.snackbar(
        'Export Error',
        'Error exporting CSV: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cost Summary'),
        actions: [
          IconButton(
            icon: Icon(_showChart ? Icons.list : Icons.bar_chart),
            onPressed: () {
              setState(() {
                _showChart = !_showChart;
              });
            },
            tooltip: _showChart ? 'Show List' : 'Show Chart',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export as CSV',
            onPressed: () async {
              if (selectedEmployeeId.isNotEmpty) {
                await exportToCSV(_summaryViewModel.summaryData.value);
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final employees = _employees;

        if (employees.isEmpty) {
          return const Center(child: Text('No employees found'));
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Employee:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: selectedEmployeeId,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.black),
                    items: List<DropdownMenuItem<String>>.from(
                      employees.map(
                        (e) => DropdownMenuItem<String>(
                          value: e.id as String,
                          child: Text(
                            e.name as String,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedEmployeeId = val;
                          _loadSummaryData();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_summaryViewModel.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_summaryViewModel.error.value.isNotEmpty) {
                  return Center(
                      child: Text('Error: ${_summaryViewModel.error.value}'));
                }

                final summaryList = _summaryViewModel.summaryData.value;

                if (summaryList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.summarize_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No summary data available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadSummaryData,
                          child: const Text('Load Summary Data'),
                        ),
                      ],
                    ),
                  );
                }

                double totalDistance = 0;
                int totalMinutes = 0;
                double totalCost = 0;

                for (final summary in summaryList) {
                  totalDistance += summary.distanceKm;
                  totalMinutes += summary.travelTime.inMinutes;
                  totalCost += summary.cost;
                }

                return _showChart
                    ? _buildChartView(
                        summaryList, totalDistance, totalMinutes, totalCost)
                    : _buildListView(
                        summaryList, totalDistance, totalMinutes, totalCost);
              }),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildListView(List<AppointmentSummary> summaryList,
      double totalDistance, int totalMinutes, double totalCost) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildSummaryCard(
                'Total Distance',
                '${totalDistance.toStringAsFixed(2)} km',
                Icons.route,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Travel Time',
                '${totalMinutes} min',
                Icons.timer,
                Colors.orange,
              ),
              _buildSummaryCard(
                'Total Cost',
                '£${totalCost.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: summaryList.length,
            itemBuilder: (context, index) {
              final s = summaryList[index];
              final timeFormat = DateFormat('h:mm a, MMM d');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text(
                            timeFormat.format(s.appointment.time),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(
                        'Customer ID: ${s.appointment.customerId}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildDetailItem(
                            'Distance',
                            '${s.distanceKm.toStringAsFixed(2)} km',
                            Icons.straighten,
                          ),
                          _buildDetailItem(
                            'Travel Time',
                            '${s.travelTime.inMinutes} min',
                            Icons.timer,
                          ),
                          _buildDetailItem(
                            'Cost',
                            '£${s.cost.toStringAsFixed(2)}',
                            Icons.attach_money,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChartView(List<AppointmentSummary> summaryList,
      double totalDistance, int totalMinutes, double totalCost) {
    final Map<String, double> costByDay = {};
    final Map<String, double> distanceByDay = {};

    for (final summary in summaryList) {
      final day = DateFormat('E').format(summary.appointment.time);

      if (!costByDay.containsKey(day)) {
        costByDay[day] = 0;
        distanceByDay[day] = 0;
      }

      costByDay[day] = costByDay[day]! + summary.cost;
      distanceByDay[day] = distanceByDay[day]! + summary.distanceKm;
    }

    final List<String> days = costByDay.keys.toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildSummaryCard(
                'Total Distance',
                '${totalDistance.toStringAsFixed(2)} km',
                Icons.route,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Travel Time',
                '${totalMinutes} min',
                Icons.timer,
                Colors.orange,
              ),
              _buildSummaryCard(
                'Total Cost',
                '£${totalCost.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Cost Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: costByDay.values.isEmpty
                          ? 10
                          : costByDay.values.reduce((a, b) => a > b ? a : b) *
                              1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '£${costByDay.values.elementAt(groupIndex).toStringAsFixed(2)}',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 && value < days.length) {
                                return Text(days[value.toInt()]);
                              }
                              return const Text('');
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text('£${value.toInt()}');
                            },
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        days.length,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: costByDay.values.elementAt(index),
                              color: Colors.green,
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Daily Distance Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: distanceByDay.values.isEmpty
                          ? 10
                          : distanceByDay.values
                                  .reduce((a, b) => a > b ? a : b) *
                              1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${distanceByDay.values.elementAt(groupIndex).toStringAsFixed(2)} km',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 && value < days.length) {
                                return Text(days[value.toInt()]);
                              }
                              return const Text('');
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()} km');
                            },
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        days.length,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: distanceByDay.values.elementAt(index),
                              color: Colors.blue,
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
