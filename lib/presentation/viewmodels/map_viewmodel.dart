import 'package:get/get.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/scheduler_repository.dart';

class MapViewModel extends GetxController {
  final SchedulerRepository _repository = Get.find<SchedulerRepository>();
  
  final RxBool isLoading = true.obs;
  final Rx<List<Employee>> employees = Rx<List<Employee>>([]);
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchEmployees();
  }
  
  Future<void> fetchEmployees() async {
    try {
      isLoading.value = true;
      final result = await _repository.getEmployees();
      employees.value = result;
      error.value = '';
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}