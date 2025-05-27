import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/appointment.dart';

class ExportSummaryService {
  Future<String> exportAppointmentsToCsv(List<Appointment> appointments) async {
    List<List<String>> rows = [
      ['Employee ID', 'Customer ID', 'Time'],
    ];

    for (var a in appointments) {
      rows.add([a.employeeId, a.customerId, a.time.toIso8601String()]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/appointments.csv';
    final file = File(path);

    await file.writeAsString(csv);
    return path;
  }
}
