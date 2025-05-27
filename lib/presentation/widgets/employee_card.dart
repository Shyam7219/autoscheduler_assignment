import 'package:flutter/material.dart';
import '../../domain/entities/employee.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employee;

  const EmployeeCard({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(employee.name),
        subtitle: Text('Available: ${employee.isAvailable}'),
      ),
    );
  }
}
