import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../viewmodels/scheduler_viewmodel.dart';
import '../../features/scheduler/scheduler_controller.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  final SchedulerViewModel _viewModel = Get.find<SchedulerViewModel>();
  final SchedulerController _controller = Get.find<SchedulerController>();
  DateTime selectedDate = DateTime.now();
  bool _showingDetails = false;

  @override
  void initState() {
    super.initState();
    _viewModel.loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Scheduler'),
        actions: [
          IconButton(
            icon: Icon(_showingDetails ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _showingDetails = !_showingDetails;
              });
            },
            tooltip: _showingDetails ? 'Show List View' : 'Show Details View',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selection
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
                  'Select Date for Scheduling:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 14)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _controller.assignAndSaveAppointments(selectedDate);
                      _viewModel.loadAppointments();
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Generate Appointments'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Appointments list
          Expanded(
            child: Obx(() {
              if (_viewModel.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_viewModel.error.value.isNotEmpty) {
                return Center(child: Text('Error: ${_viewModel.error.value}'));
              }

              final appointments = _viewModel.appointments.value;

              if (appointments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No appointments scheduled yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use the button above to generate appointments',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return _showingDetails
                  ? _buildDetailedView(appointments)
                  : _buildListView(appointments);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<dynamic> appointments) {
    // Group appointments by employee
    final Map<String, List<dynamic>> groupedAppointments = {};

    for (final appointment in appointments) {
      if (!groupedAppointments.containsKey(appointment.employeeId)) {
        groupedAppointments[appointment.employeeId] = [];
      }
      groupedAppointments[appointment.employeeId]!.add(appointment);
    }

    return ListView.builder(
      itemCount: groupedAppointments.length,
      itemBuilder: (context, index) {
        final employeeId = groupedAppointments.keys.elementAt(index);
        final employeeAppointments = groupedAppointments[employeeId]!;

        return ExpansionTile(
          title: FutureBuilder(
            future: _controller.getEmployees(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Text('Employee: $employeeId');
              }

              final employees = snapshot.data!;
              String employeeName = employeeId;
              for (var emp in employees) {
                if (emp.id == employeeId) {
                  employeeName = emp.name;
                  break;
                }
              }

              return Text('Employee: $employeeName');
            },
          ),
          subtitle: Text('${employeeAppointments.length} appointments'),
          children: employeeAppointments.map((appointment) {
            return ListTile(
              title: FutureBuilder(
                future: _controller.getCustomers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Text('Customer: ${appointment.customerId}');
                  }

                  final customers = snapshot.data!;
                  String customerName = appointment.customerId;
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
                'Time: ${DateFormat('h:mm a').format(appointment.time)}\n'
                'Duration: ${appointment.duration.inMinutes} minutes',
              ),
              leading: const Icon(Icons.schedule),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDetailedView(List<dynamic> appointments) {
    // Sort appointments by time
    appointments.sort((a, b) => a.time.compareTo(b.time));

    return ListView.builder(
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];

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
                      DateFormat('h:mm a').format(appointment.time),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appointment.status.toUpperCase(),
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                FutureBuilder(
                  future: _controller.getCustomers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text('Loading customer...');
                    }

                    final customers = snapshot.data!;
                    String customerName = appointment.customerId;
                    for (var cust in customers) {
                      if (cust.id == appointment.customerId) {
                        customerName = cust.name;
                        break;
                      }
                    }

                    return Row(
                      children: [
                        const Icon(Icons.person, color: Colors.grey),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                FutureBuilder(
                  future: _controller.getEmployees(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text('Loading employee...');
                    }

                    final employees = snapshot.data!;
                    String employeeName = appointment.employeeId;
                    for (var emp in employees) {
                      if (emp.id == appointment.employeeId) {
                        employeeName = emp.name;
                        break;
                      }
                    }

                    return Row(
                      children: [
                        const Icon(Icons.engineering, color: Colors.grey),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Employee',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              employeeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.grey),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duration',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${appointment.duration.inMinutes} minutes',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
