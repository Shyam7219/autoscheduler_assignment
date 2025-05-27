import 'package:autoscheduler_assignment/presentation/viewmodels/scheduler_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SchedulerScreen extends ConsumerStatefulWidget {
  const SchedulerScreen({super.key});

  @override
  ConsumerState<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends ConsumerState<SchedulerScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(schedulerViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Appointments')),
      body: Column(
        children: [
          ListTile(
            title: Text(
              'Selected Date: ${selectedDate.toLocal().toIso8601String().split('T').first}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 7)),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(schedulerViewModelProvider.notifier)
                  .loadAndAssignAppointments(selectedDate);
            },
            child: const Text('Generate Appointments'),
          ),
          const Divider(),
          Expanded(
            child: appointments.when(
              loading:
                  () => const Center(child: Text('Loading appointments...')),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final a = list[index];
                    return ListTile(
                      title: Text('Employee: ${a.employeeId}'),
                      subtitle: Text(
                        'Customer: ${a.customerId}\nTime: ${a.time}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
