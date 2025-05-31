import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:autoscheduler_assignment/presentation/screens/home_screen.dart';
import 'di/dependency_injection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await _updateMissingNames();
  } catch (e) {
    throw Exception('Error initializing Firebase: $e');
  }

  DependencyInjection.init();

  runApp(const AutoSchedulerApp());
}

Future<void> _updateMissingNames() async {
  final firestore = FirebaseFirestore.instance;

  await firestore
      .collection('employees')
      .doc('e1')
      .update({'name': 'shyam patil'}).catchError(
          (e) => debugPrint('Error updating e1: $e'));

  await firestore.collection('employees').doc('e2').update(
      {'name': 'rock'}).catchError((e) => debugPrint('Error updating e2: $e'));

  await firestore
      .collection('customers')
      .doc('c1')
      .update({'name': 'dr. patel'}).catchError(
          (e) => debugPrint('Error updating c1: $e'));
}

class AutoSchedulerApp extends StatelessWidget {
  const AutoSchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Auto Scheduler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
