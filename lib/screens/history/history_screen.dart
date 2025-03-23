import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../controllers/history_controller.dart';
import '../../widgets/app_drawer.dart';

class HistoryScreen extends StatelessWidget {
  final HistoryController _historyController = Get.find<HistoryController>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IAQ History'),
      ),
      drawer: AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () => _historyController.fetchIAQRecords(),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IAQ History',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: 8.h),
              Text(
                'View your past air quality records',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 24.h),
              _buildIAQChart(context),
              SizedBox(height: 24.h),
              Text(
                'Recent Records',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: _buildRecordsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildIAQChart(BuildContext context) {
    return Container(
      height: 240.h,
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
      child: Obx(() {
        if (_historyController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (_historyController.iaqRecords.isEmpty) {
          return Center(
            child: Text(
              'No IAQ records available',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        
        final chartData = _historyController.getChartData();
        if (chartData.length < 2) {
          return Center(
            child: Text(
              'Not enough data for chart',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        
        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 50,
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
                    if (value.toInt() >= chartData.length || value.toInt() < 0) {
                      return const SizedBox.shrink();
                    }
                    
                    final date = chartData[value.toInt()]['timestamp'] as DateTime;
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: Text(
                        DateFormat('MM/dd').format(date),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10.sp,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 50,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
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
            maxX: chartData.length.toDouble() - 1,
            minY: 0,
            maxY: 300,
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(chartData.length, (index) {
                  return FlSpot(
                    index.toDouble(),
                    (chartData[index]['iaqIndex'] as double),
                  );
                }),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Theme.of(context).primaryColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.3),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
  
  Widget _buildRecordsList() {
    return Obx(() {
      if (_historyController.isLoading.value && _historyController.iaqRecords.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }
      
      if (_historyController.iaqRecords.isEmpty) {
        return Center(
          child: Text(
            'No IAQ records available',
            style: TextStyle(fontSize: 16.sp),
          ),
        );
      }
      
      return ListView.builder(
        itemCount: _historyController.iaqRecords.length,
        itemBuilder: (context, index) {
          final record = _historyController.iaqRecords[index];
          return Card(
            margin: EdgeInsets.only(bottom: 12.h),
            child: ListTile(
              title: Text(
                'IAQ Index: ${record.iaqIndex.toStringAsFixed(1)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4.h),
                  Text('Category: ${record.iaqCategory}'),
                  SizedBox(height: 4.h),
                  Text(
                    'Temperature: ${record.temperature.toStringAsFixed(1)}°C | Humidity: ${record.humidity.toStringAsFixed(1)}%',
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'CO2: ${record.co2.toStringAsFixed(1)} ppm | VOC: ${record.voc.toStringAsFixed(1)} ppb',
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MM/dd/yyyy').format(record.timestamp),
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('HH:mm').format(record.timestamp),
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
}

