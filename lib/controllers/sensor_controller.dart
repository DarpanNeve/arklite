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
  RxList<Map<String, dynamic>> thingSpeakHistory = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;
  RxBool isLoadingHistory = false.obs;

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
    print("load sensor called");
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
        print("response body is $data");
        final feeds = data['feeds'] as List;

        if (feeds.isNotEmpty) {
          final latestFeed = feeds[0];

          // Update sensor values based on your ThingSpeak field configuration.
          temperature.value = double.parse(latestFeed['field1'] ?? '0');
          humidity.value = double.parse(latestFeed['field2'] ?? '0');
          voc.value = double.parse(latestFeed['field3'] ?? '0');
          pm.value = double.parse(latestFeed['field4'] ?? '0');

          // Update sensor models with current values.
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

  Future<void> fetchThingSpeakHistory(String sensorId) async {
    try {
      isLoadingHistory.value = true;
      thingSpeakHistory.clear();

      // Replace with your ThingSpeak channel and API key
      final String channelId = '2885210';
      final String apiKey = 'ZD6SM8ES78R0RG2W';

      // Get the field number based on sensorId
      int fieldNumber = _getFieldNumber(sensorId);

      final response = await http.get(
        Uri.parse('https://api.thingspeak.com/channels/$channelId/feeds.json?api_key=$apiKey&results=20'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("response data is $data");
        final feeds = data['feeds'] as List;

        List<Map<String, dynamic>> history = [];

        for (var feed in feeds.reversed) {
          // Skip entries with null or empty values
          if (feed['field$fieldNumber'] == null || feed['field$fieldNumber'] == '') {
            continue;
          }

          try {
            double value = double.parse(feed['field$fieldNumber']);
            DateTime timestamp = DateTime.parse(feed['created_at']);

            history.add({
              'value': value,
              'timestamp': timestamp,
            });
          } catch (e) {
            print('Error parsing feed data: $e');
          }
        }

        thingSpeakHistory.value = history;
      }
    } catch (e) {
      print('Error fetching ThingSpeak history: $e');
      Get.snackbar(
        'Error',
        'Failed to load sensor history: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingHistory.value = false;
    }
  }

  int _getFieldNumber(String sensorId) {
    switch (sensorId) {
      case 'temperature':
        return 1;
      case 'humidity':
        return 2;
      case 'voc':
        return 3;
      case 'pm':
        return 4;
      default:
        return 1;
    }
  }

  /// New IAQ calculation using PM and VOC values only.
  Future<void> calculateIAQ() async {
    try {
      isLoading.value = true;

      // Calculate AQI for PM and VOC using breakpoint-based functions.
      int aqiPM = calculatePM25AQI(pm.value);
      int aqiVOC = calculateVOCAQI(voc.value);

      // Choose the higher AQI as the final IAQ value.
      int finalAQI = aqiPM > aqiVOC ? aqiPM : aqiVOC;
      iaqIndex.value = finalAQI.toDouble();
      iaqCategory.value = getAQICategory(finalAQI);

      // Save IAQ record to Firestore.
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

  /// --- New AQI Calculation Functions ---

  /// Calculates the AQI based on PM2.5 concentration (μg/m³).
  int calculatePM25AQI(double pmValue) {
    if (pmValue <= 12.0) {
      // Scale 0–50 for 0–12 µg/m³.
      return ((50 / 12.0) * pmValue).round();
    } else if (pmValue <= 35.4) {
      // Scale 51–100 for 12.1–35.4 µg/m³.
      return (((100 - 51) / (35.4 - 12.1)) * (pmValue - 12.1) + 51).round();
    } else if (pmValue <= 55.4) {
      // Scale 101–150 for 35.5–55.4 µg/m³.
      return (((150 - 101) / (55.4 - 35.5)) * (pmValue - 35.5) + 101).round();
    } else if (pmValue <= 150.4) {
      // Scale 151–200 for 55.5–150.4 µg/m³.
      return (((200 - 151) / (150.4 - 55.5)) * (pmValue - 55.5) + 151).round();
    } else {
      // For values beyond 150.4.
      return 201;
    }
  }

  /// Calculates the AQI based on VOC concentration (ppb).
  int calculateVOCAQI(double vocValue) {
    if (vocValue <= 220) {
      // Scale 0–50 for 0–220 ppb.
      return ((50 / 220) * vocValue).round();
    } else if (vocValue <= 660) {
      // Scale 51–100 for 221–660 ppb.
      return (((100 - 51) / (660 - 221)) * (vocValue - 221) + 51).round();
    } else if (vocValue <= 2200) {
      // Scale 101–150 for 661–2200 ppb.
      return (((150 - 101) / (2200 - 661)) * (vocValue - 661) + 101).round();
    } else if (vocValue <= 5500) {
      // Scale 151–200 for 2201–5500 ppb.
      return (((200 - 151) / (5500 - 2201)) * (vocValue - 2201) + 151).round();
    } else {
      // For values beyond 5500.
      return 201;
    }
  }

  /// Returns an AQI category string based on the AQI value.
  String getAQICategory(int aqi) {
    if (aqi <= 50)
      return "Good";
    else if (aqi <= 100)
      return "Moderate";
    else if (aqi <= 150)
      return "Unhealthy for Sensitive Groups";
    else if (aqi <= 200)
      return "Unhealthy";
    else if (aqi <= 300)
      return "Very Unhealthy";
    else
      return "Hazardous";
  }

  /// --- End of AQI Calculation Functions ---

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

  double getSensorValue(String sensorId) {
    switch (sensorId) {
      case 'temperature':
        return temperature.value;
      case 'humidity':
        return humidity.value;
      case 'voc':
        return voc.value;
      case 'pm':
        return pm.value;
      default:
        return 0.0;
    }
  }

  String getSensorUnit(String sensorId) {
    SensorModel sensor = sensors.firstWhere((s) => s.id == sensorId);
    return sensor.unit;
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
