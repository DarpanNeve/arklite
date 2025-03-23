import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';

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
  final List<Color> gradientColors = [
    const Color(0xFF1976D2),
    const Color(0xFF64B5F6),
  ];
  
  @override
  void initState() {
    super.initState();
    sensorId = Get.arguments['sensorId'];
    sensor = _sensorController.sensors.firstWhere((s) => s.id == sensorId);
    
    // Start periodic updates
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
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentValueCard(),
            SizedBox(height: 24.h),
            Text(
              'Real-time Data',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: _buildChart(),
            ),
          ],
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
              double value = _getCurrentValue();
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
  
  Widget _buildChart() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: _getChartInterval(),
            verticalInterval: 1,
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      '${value.toInt()}m',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.sp,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _getChartInterval(),
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    space: 8,
                    meta: meta,
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.sp,
                      ),
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          minX: 0,
          maxX: 10,
          minY: _getMinY(),
          maxY: _getMaxY(),
          lineBarsData: [
            LineChartBarData(
              spots: _generateRandomSpots(),
              isCurved: true,
              gradient: LinearGradient(
                colors: gradientColors,
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: false,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: gradientColors
                      .map((color) => color.withOpacity(0.3))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getSensorIcon() {
    switch (sensor.id) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'co2':
        return Icons.cloud;
      case 'voc':
        return Icons.air;
      default:
        return Icons.sensors;
    }
  }
  
  double _getCurrentValue() {
    switch (sensor.id) {
      case 'temperature':
        return _sensorController.temperature.value;
      case 'humidity':
        return _sensorController.humidity.value;
      case 'co2':
        return _sensorController.co2.value;
      case 'voc':
        return _sensorController.voc.value;
      default:
        return 0.0;
    }
  }
  
  double _getMinY() {
    switch (sensor.id) {
      case 'temperature':
        return 15.0;
      case 'humidity':
        return 0.0;
      case 'co2':
        return 300.0;
      case 'voc':
        return 0.0;
      default:
        return 0.0;
    }
  }
  
  double _getMaxY() {
    switch (sensor.id) {
      case 'temperature':
        return 35.0;
      case 'humidity':
        return 100.0;
      case 'co2':
        return 2000.0;
      case 'voc':
        return 1000.0;
      default:
        return 100.0;
    }
  }
  
  double _getChartInterval() {
    switch (sensor.id) {
      case 'temperature':
        return 5.0;
      case 'humidity':
        return 20.0;
      case 'co2':
        return 500.0;
      case 'voc':
        return 200.0;
      default:
        return 20.0;
    }
  }
  
  List<FlSpot> _generateRandomSpots() {
    final currentValue = _getCurrentValue();
    final spots = <FlSpot>[];
    
    for (int i = 0; i <= 10; i++) {
      // Generate random variations around the current value
      final random = (i % 2 == 0 ? 1 : -1) * (0.05 * currentValue * i / 10);
      spots.add(FlSpot(i.toDouble(), currentValue + random));
    }
    
    return spots;
  }
}

