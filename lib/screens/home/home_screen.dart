import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/sensor_controller.dart';
import '../../routes/app_pages.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/sensor_card.dart';

class HomeScreen extends StatelessWidget {
  final SensorController _sensorController = Get.find<SensorController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Image.asset('assets/images/logo.png', height: 40.h),
        ],
        title: Row(
          children: [
            Text('IAQ Monitoring'),
          ],
        ),
      ),
      drawer: AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () => _sensorController.fetchSensorData(),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sensor Readings',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: 8.h),
              Text(
                'Monitor your indoor air quality in real-time',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 24.h),
              Expanded(
                child: Obx(() {
                  if (_sensorController.isLoading.value && _sensorController.sensors.isEmpty) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _sensorController.sensors.length,
                    itemBuilder: (context, index) {
                      final sensor = _sensorController.sensors[index];
                      return SensorCard(
                        sensor: sensor,
                        onTap: () => Get.toNamed(
                          Routes.SENSOR_DETAIL,
                          arguments: {'sensorId': sensor.id},
                        ),
                      );
                    },
                  );
                }),
              ),
              SizedBox(height: 16.h),
              Obx(() => ElevatedButton(
                onPressed: _sensorController.isLoading.value
                    ? null
                    : () => _sensorController.calculateIAQ(),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50.h),
                ),
                child: _sensorController.isLoading.value
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Calculate Air Quality Index'),
              )),
              SizedBox(height: 16.h),
              Obx(() {
                if (_sensorController.iaqIndex.value > 0) {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IAQ Index: ${_sensorController.iaqIndex.value}',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Category: ${_sensorController.iaqCategory.value}',
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: _getCategoryColor(_sensorController.iaqCategory.value),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Good':
        return Colors.green;
      case 'Moderate':
        return Colors.yellow.shade800;
      case 'Unhealthy for Sensitive Groups':
        return Colors.orange;
      case 'Unhealthy':
        return Colors.red;
      case 'Very Unhealthy':
        return Colors.purple;
      case 'Hazardous':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}

