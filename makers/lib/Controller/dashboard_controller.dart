import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:makers/Auth/Screens/signin.dart';

class DashboardController extends GetxController {
  var stockData = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStockData();
  }

  Future<void> fetchStockData() async {
    try {
      isLoading.value = true;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('name')
          .get();

      List<Map<String, dynamic>> data = [];
      for (var doc in snapshot.docs) {
        var docData = doc.data() as Map<String, dynamic>;
        data.add({
          'name': docData['name'] ?? 'Unknown',
          'stock': docData['stock'] is num ? docData['stock'] : 0,
          'price': docData['price'] is num ? docData['price'] : 0,
          'imageUrl': docData['imageUrl'] ?? '',
          'description': docData['description'] ?? '',
          'color': _getRandomColor(doc.id),
        });
      }

      stockData.assignAll(data);
      isLoading.value = false;
    } catch (e) {
      print('Error fetching stock data: $e');
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to fetch stock data: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Color _getRandomColor(String docId) {
    List<Color> colors = [
      Color(0xFF3F51B5),
      Color(0xFFE91E63),
      Color(0xFF009688),
      Color(0xFFFF5722),
      Color(0xFF4CAF50),
      Color(0xFF673AB7),
      Color(0xFF2196F3),
      Color(0xFFF44336),
      Color(0xFFFFC107),
      Color(0xFF795548),
    ];
    return colors[docId.hashCode.abs() % colors.length];
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => Signin());
  }
}
