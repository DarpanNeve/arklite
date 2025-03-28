import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../controllers/sensor_controller.dart';
import '../../models/sensor_model.dart';

class SensorDetailScreen extends StatefulWidget {
  @override
  _SensorDetailScreenState createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  final SensorController _sensorController = Get.find<SensorController>();
  late String sensorId;
  late SensorModel sensor;

  @override
  void initState() {
    super.initState();
    sensorId = Get.arguments['sensorId'];
    sensor = _sensorController.sensors.firstWhere((s) => s.id == sensorId);

    // Fetch ThingSpeak history data
    _sensorController.fetchThingSpeakHistory(sensorId);

    // Start periodic updates for current value
    _startPeriodicUpdates();
  }

  void _startPeriodicUpdates() {
    // Update sensor data every 10 seconds
    Future.delayed(Duration(seconds: 10), () {
      if (mounted) {
        _sensorController.fetchSensorData();
        _startPeriodicUpdates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${sensor.name} Sensor'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _sensorController.fetchSensorData();
          await _sensorController.fetchThingSpeakHistory(sensorId);
        },
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentValueCard(),
              SizedBox(height: 24.h),
              Text(
                'Historical Data',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: _buildThingSpeakHistoryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentValueCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensor.name,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Current Reading',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Icon(
                  _getSensorIcon(),
                  size: 48.sp,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Obx(() {
              double value = _sensorController.getSensorValue(sensorId);
              return Text(
                '${value.toStringAsFixed(1)} ${sensor.unit}',
                style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildThingSpeakHistoryList() {
    return Obx(() {
      if (_sensorController.isLoadingHistory.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (_sensorController.thingSpeakHistory.isEmpty) {
        return Center(
          child: Text(
            'No historical data available',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      }

      return ListView.builder(
        itemCount: _sensorController.thingSpeakHistory.length,
        itemBuilder: (context, index) {
          final historyItem = _sensorController.thingSpeakHistory[index];
          final double value = historyItem['value'];
          final DateTime timestamp = historyItem['timestamp'];

          return Card(
            margin: EdgeInsets.only(bottom: 12.h),
            child: ListTile(
              title: Text(
                '${value.toStringAsFixed(1)} ${sensor.unit}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              subtitle: Text(
                'ThingSpeak Data',
                style: TextStyle(fontSize: 12.sp),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MM/dd/yyyy').format(timestamp),
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('HH:mm:ss').format(timestamp),
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ],
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
          );
        },
      );
    });
  }

  IconData _getSensorIcon() {
    switch (sensor.id) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'voc':
        return Icons.air;
      case 'pm':
        return Icons.blur_on;
      default:
        return Icons.sensors;
    }
  }
}

