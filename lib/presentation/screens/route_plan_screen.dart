import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/route_plan.dart';
import '../../features/scheduler/scheduler_controller.dart';

class RoutePlanScreen extends StatefulWidget {
  const RoutePlanScreen({super.key});

  @override
  State<RoutePlanScreen> createState() => _RoutePlanScreenState();
}

class _RoutePlanScreenState extends State<RoutePlanScreen> {
  final SchedulerController _controller = Get.find<SchedulerController>();
  String selectedEmployeeId = '';
  DateTime selectedDate = DateTime.now();
  bool filterByEmployee =
      true; // true = filter by employee, false = filter by date
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _isLoading.value = true;
    try {
      final employees = await _controller.getEmployees();
      if (employees.isNotEmpty) {
        setState(() {
          selectedEmployeeId = employees.first.id;
        });
      }
      await _controller.generateWeeklyRoutePlans();
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('7-Day Route Plan'),
        actions: [
          // Toggle between employee and date filter
          IconButton(
            icon: Icon(filterByEmployee ? Icons.person : Icons.calendar_today),
            onPressed: () {
              setState(() {
                filterByEmployee = !filterByEmployee;
              });
            },
            tooltip: filterByEmployee ? 'Filter by Date' : 'Filter by Employee',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                filterByEmployee ? _buildEmployeeFilter() : _buildDateFilter(),
          ),

          // Route plans list
          Expanded(
            child: Obx(() {
              if (_isLoading.value || _controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_controller.error.value.isNotEmpty) {
                return Center(child: Text('Error: ${_controller.error.value}'));
              }

              final List<RoutePlan> plans = filterByEmployee
                  ? _controller.getRoutePlansForEmployee(selectedEmployeeId)
                  : _controller.getRoutePlansForDate(selectedDate);

              if (plans.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.route_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No route plans found for the selected filter',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          _isLoading.value = true;
                          await _controller.generateWeeklyRoutePlans();
                          _isLoading.value = false;
                        },
                        child: const Text('Generate Route Plans'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  return _buildRoutePlanCard(plan);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeFilter() {
    return FutureBuilder(
      future: _controller.getEmployees(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final employees = snapshot.data!;

        return DropdownButton<String>(
          value: selectedEmployeeId,
          isExpanded: true,
          hint: const Text('Select Employee'),
          items: employees
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.id,
                  child: Text(e.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedEmployeeId = value;
              });
            }
          },
        );
      },
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

  Widget _buildRoutePlanCard(RoutePlan plan) {
    final dateFormat = DateFormat('EEE, MMM d');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${dateFormat.format(plan.date)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                FutureBuilder(
                  future: _controller.getEmployees(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text('Loading...');
                    }

                    final employees = snapshot.data!;

                    String employeeName = "Unknown";
                    for (var emp in employees) {
                      if (emp.id == plan.employeeId) {
                        employeeName = emp.name;
                        break;
                      }
                    }

                    return Text(
                      'Employee: $employeeName',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            Text(
              'Appointments: ${plan.appointments.length}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Distance: ${plan.totalDistanceKm.toStringAsFixed(2)} km',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Travel Time: ${plan.totalTravelTime.inMinutes} minutes',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Total Cost: £${plan.totalCost.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text('View Appointments'),
              children: plan.appointments.map((appointment) {
                final timeFormat = DateFormat('h:mm a');
                return ListTile(
                  title: FutureBuilder(
                    future: _controller.getCustomers(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('Loading...');
                      }

                      final customers = snapshot.data!;
                      String customerName = "Unknown";
                      for (var cust in customers) {
                        if (cust.id == appointment.customerId) {
                          customerName = cust.name;
                          break;
                        }
                      }

                      return Text('Customer: $customerName');
                    },
                  ),
                  subtitle: Text(
                    'Time: ${timeFormat.format(appointment.time)}\n'
                    'Duration: ${appointment.duration.inMinutes} minutes',
                  ),
                  leading: const Icon(Icons.schedule),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
