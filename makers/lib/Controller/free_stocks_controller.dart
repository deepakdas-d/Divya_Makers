// free_stocks_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

// GetX Controller for FreeStocks
class FreeStocksController extends GetxController {
  // Reference to the 'products' collection in Firestore
  final CollectionReference products = FirebaseFirestore.instance.collection(
    'products',
  );

  // Reactive map for TextEditingControllers
  final RxMap<String, TextEditingController> stockControllers =
      <String, TextEditingController>{}.obs;

  // Reactive search query
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    // Dispose all text controllers
    stockControllers.forEach((_, controller) => controller.dispose());
    super.onClose();
  }

  // Updates the stock value for a product in Firestore and the UI
  Future<void> updateStock(String productId, int newStock) async {
    // Prevent negative stock values
    if (newStock < 0) {
      Get.snackbar(
        'Error',
        'Stock cannot be negative',
        backgroundColor: const Color(0xFFE53E3E),
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        snackPosition: SnackPosition.TOP,
        borderRadius: 8,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    // Optimistically update the TextEditingController
    stockControllers[productId]?.text = newStock.toString();

    try {
      // Update the stock field in Firestore
      await products.doc(productId).update({'stock': newStock});
      HapticFeedback.lightImpact();
    } catch (e) {
      // Revert the TextEditingController if the update fails
      final doc = await products.doc(productId).get();
      final currentStock = (doc.data() as Map<String, dynamic>?)?['stock'] ?? 0;
      stockControllers[productId]?.text = currentStock.toString();
      Get.snackbar(
        'Error',
        'Failed to update stock: $e',
        backgroundColor: const Color(0xFFE53E3E),
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        snackPosition: SnackPosition.TOP,
        borderRadius: 8,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // Increments the stock of a product by 1
  Future<void> incrementStock(String productId, int currentStock) async {
    await updateStock(productId, currentStock + 1);
  }

  // Decrements the stock of a product by 1
  Future<void> decrementStock(String productId, int currentStock) async {
    await updateStock(productId, currentStock - 1);
  }

  // Updates stock based on user input from text field
  Future<void> editStock(String productId, String stockText) async {
    final newStock = int.tryParse(stockText);
    if (newStock == null) {
      Get.snackbar(
        'Error',
        'Please enter a valid number',
        backgroundColor: const Color(0xFFE53E3E),
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        snackPosition: SnackPosition.TOP,
        borderRadius: 8,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    await updateStock(productId, newStock);
  }
}
