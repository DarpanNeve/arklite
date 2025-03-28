import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/sensor_model.dart';

class SensorCard extends StatelessWidget {
  final SensorModel sensor;
  final VoidCallback onTap;

  const SensorCard({
    required this.sensor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sensor.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _getSensorIcon(),
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              Spacer(),
              Text(
                sensor.currentValue != null
                    ? '${sensor.currentValue!.toStringAsFixed(1)} ${sensor.unit}'
                    : 'No data',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Tap to view details',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
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
      case 'voc':
        return Icons.air;
      case 'pm':
        return Icons.blur_on;
      default:
        return Icons.sensors;
    }
  }
}

