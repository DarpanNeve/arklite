import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/sensor_model.dart';
import 'auth_controller.dart';

class SensorController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  RxList<SensorModel> sensors = <SensorModel>[].obs;
  RxBool isLoading = false.obs;

  // Current sensor readings
  RxDouble temperature = 0.0.obs;
  RxDouble humidity = 0.0.obs;
  RxDouble voc = 0.0.obs;
  RxDouble pm = 0.0.obs;

  // IAQ calculation result
  RxDouble iaqIndex = 0.0.obs;
  RxString iaqCategory = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSensors();
  }

  void loadSensors() {
    sensors.value = [
      SensorModel(
        id: 'temperature',
        name: 'Temperature',
        unit: '°C',
        icon: 'assets/icons/temperature.png',
      ),
      SensorModel(
        id: 'humidity',
        name: 'Humidity',
        unit: '%',
        icon: 'assets/icons/humidity.png',
      ),
      SensorModel(
        id: 'voc',
        name: 'VOC',
        unit: 'ppb',
        icon: 'assets/icons/voc.png',
      ),
      SensorModel(
        id: 'pm',
        name: 'PM',
        unit: 'μg/m³',
        icon: 'assets/icons/pm.png',
      ),
    ];

    fetchSensorData();
  }

  Future<void> fetchSensorData() async {
    try {
      isLoading.value = true;

      // Replace with your ThingSpeak channel and API key
      final String channelId = '2885210';
      final String apiKey = 'ZD6SM8ES78R0RG2W';

      final response = await http.get(
        Uri.parse('https://api.thingspeak.com/channels/$channelId/feeds.json?api_key=$apiKey&results=1'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final feeds = data['feeds'] as List;

        if (feeds.isNotEmpty) {
          final latestFeed = feeds[0];

          // Update sensor values (field1, field2, etc. depend on your ThingSpeak channel setup)
          temperature.value = double.parse(latestFeed['field1'] ?? '0');
          humidity.value = double.parse(latestFeed['field2'] ?? '0');
          voc.value = double.parse(latestFeed['field3'] ?? '0');
          pm.value = double.parse(latestFeed['field4'] ?? '0');

          // Update sensor models with current values
          sensors[0] = sensors[0].copyWith(currentValue: temperature.value);
          sensors[1] = sensors[1].copyWith(currentValue: humidity.value);
          sensors[2] = sensors[2].copyWith(currentValue: voc.value);
          sensors[3] = sensors[3].copyWith(currentValue: pm.value);
        }
      }
    } catch (e) {
      print('Error fetching sensor data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> calculateIAQ() async {
    try {
      isLoading.value = true;

      // Example IAQ calculation formula (replace with your actual formula)
      // This is a simplified example
      double tempScore = calculateTemperatureScore(temperature.value);
      double humidityScore = calculateHumidityScore(humidity.value);
      double vocScore = calculateVOCScore(voc.value);
      double pmScore = calculatePMScore(pm.value);

      // Calculate overall IAQ index (weighted average)
      double calculatedIndex = (tempScore * 0.25 + humidityScore * 0.25 + vocScore * 0.25 + pmScore * 0.25);
      iaqIndex.value = double.parse(calculatedIndex.toStringAsFixed(2));

      // Determine IAQ category
      if (iaqIndex.value >= 0 && iaqIndex.value <= 50) {
        iaqCategory.value = 'Good';
      } else if (iaqIndex.value <= 100) {
        iaqCategory.value = 'Moderate';
      } else if (iaqIndex.value <= 150) {
        iaqCategory.value = 'Unhealthy for Sensitive Groups';
      } else if (iaqIndex.value <= 200) {
        iaqCategory.value = 'Unhealthy';
      } else if (iaqIndex.value <= 300) {
        iaqCategory.value = 'Very Unhealthy';
      } else {
        iaqCategory.value = 'Hazardous';
      }

      // Save IAQ record to Firestore
      await saveIAQRecord();

      Get.snackbar(
        'IAQ Calculation',
        'IAQ Index: ${iaqIndex.value} - ${iaqCategory.value}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to calculate IAQ: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Example scoring functions (replace with your actual formulas)
  double calculateTemperatureScore(double temp) {
    // Optimal temperature is around 20-25°C
    if (temp >= 20 && temp <= 25) return 25;
    if (temp >= 18 && temp < 20) return 20;
    if (temp > 25 && temp <= 28) return 20;
    return 10; // Less optimal
  }

  double calculateHumidityScore(double humidity) {
    // Optimal humidity is around 40-60%
    if (humidity >= 40 && humidity <= 60) return 25;
    if (humidity >= 30 && humidity < 40) return 20;
    if (humidity > 60 && humidity <= 70) return 20;
    return 10; // Less optimal
  }

  double calculateVOCScore(double voc) {
    // VOC levels (ppb)
    if (voc < 200) return 25;
    if (voc < 500) return 20;
    if (voc < 1000) return 15;
    if (voc < 2000) return 10;
    return 5;
  }

  double calculatePMScore(double pm) {
    // PM levels (μg/m³)
    if (pm < 12) return 25;
    if (pm < 35) return 20;
    if (pm < 55) return 15;
    if (pm < 150) return 10;
    return 5;
  }

  Future<void> saveIAQRecord() async {
    try {
      IAQRecord record = IAQRecord(
        timestamp: DateTime.now(),
        temperature: temperature.value,
        humidity: humidity.value,
        voc: voc.value,
        pm: pm.value,
        iaqIndex: iaqIndex.value,
        iaqCategory: iaqCategory.value,
      );

      await _firestore
          .collection('users')
          .doc(_authController.firebaseUser.value!.uid)
          .collection('iaq_records')
          .add(record.toMap());
    } catch (e) {
      print('Error saving IAQ record: $e');
    }
  }
}

extension SensorModelExtension on SensorModel {
  SensorModel copyWith({
    String? id,
    String? name,
    String? unit,
    String? icon,
    double? currentValue,
  }) {
    return SensorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      icon: icon ?? this.icon,
      currentValue: currentValue ?? this.currentValue,
    );
  }
}

