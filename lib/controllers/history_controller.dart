import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sensor_model.dart';
import 'auth_controller.dart';

class HistoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  RxList<IAQRecord> iaqRecords = <IAQRecord>[].obs;
  RxBool isLoading = false.obs;
  RxBool isUpdatingLocation = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchIAQRecords();
  }

  Future<void> fetchIAQRecords() async {
    try {
      isLoading.value = true;

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(_authController.firebaseUser.value!.uid)
          .collection('iaq_records')
          .orderBy('timestamp', descending: true)
          .get();

      iaqRecords.value = snapshot.docs
          .map((doc) => IAQRecord.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();
    } catch (e) {
      print('Error fetching IAQ records: $e');
      Get.snackbar(
        'Error',
        'Failed to load history: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateLocation(String recordId, String location) async {
    try {
      isUpdatingLocation.value = true;

      await _firestore
          .collection('users')
          .doc(_authController.firebaseUser.value!.uid)
          .collection('iaq_records')
          .doc(recordId)
          .update({'location': location});

      // Update the local record
      int index = iaqRecords.indexWhere((record) => record.id == recordId);
      if (index != -1) {
        IAQRecord updatedRecord = iaqRecords[index].copyWith(location: location);
        iaqRecords[index] = updatedRecord;
      }

      Get.snackbar(
        'Success',
        'Location updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error updating location: $e');
      Get.snackbar(
        'Error',
        'Failed to update location: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUpdatingLocation.value = false;
    }
  }

  List<Map<String, dynamic>> getChartData() {
    // Reverse the list to get chronological order for the chart
    List<IAQRecord> chronologicalRecords = iaqRecords.reversed.toList();

    return chronologicalRecords.map((record) {
      return {
        'timestamp': record.timestamp,
        'iaqIndex': record.iaqIndex,
      };
    }).toList();
  }
}

