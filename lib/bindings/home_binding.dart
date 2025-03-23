import 'package:get/get.dart';

import '../controllers/sensor_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SensorController>(() => SensorController());
  }
}

