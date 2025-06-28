import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderDetailController extends GetxController {
  final Map<String, dynamic> orderData;
  final String docId;
  final RxString currentStatus = ''.obs;
  final Rx<DateTime?> selectedDeliveryDate = Rx<DateTime?>(
    null,
  ); // Added for delivery date
  final List<String> statusOptions = [
    'pending',
    'accepted',
    'inprogress',
    'sent out for delivery',
    'delivered',
  ];

  OrderDetailController({required this.orderData, required this.docId}) {
    currentStatus.value = orderData['order_status'] ?? 'pending';
    // Initialize delivery date if it exists in orderData
    if (orderData['deliveryDate'] != null) {
      selectedDeliveryDate.value = (orderData['deliveryDate'] as Timestamp?)
          ?.toDate();
    }
  }

  Future<void> updateOrderStatus(String newStatus) async {
    try {
      // Prepare data to update
      Map<String, dynamic> updateData = {'order_status': newStatus};

      // Include or clear delivery date based on status
      if (newStatus == 'sent out for delivery' &&
          selectedDeliveryDate.value != null) {
        updateData['deliveryDate'] = Timestamp.fromDate(
          selectedDeliveryDate.value!,
        );
      } else {
        updateData['deliveryDate'] =
            null; // Clear delivery date for other statuses
      }

      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(docId)
          .update(updateData);

      // Update local status
      currentStatus.value = newStatus;

      Get.snackbar(
        'Success',
        'Order status updated to ${getStatusText(newStatus)}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update status: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Set delivery date
  void setDeliveryDate(DateTime? date) {
    selectedDeliveryDate.value = date;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'inprogress':
        return Colors.orange;
      case 'sent out for delivery':
        return Colors.blue;
      case 'delivered':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle_outline;
      case 'inprogress':
        return Icons.build_circle_outlined;
      case 'sent out for delivery':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.done_all;
      default:
        return Icons.pending_outlined;
    }
  }

  String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'inprogress':
        return 'In Progress';
      case 'sent out for delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Pending';
    }
  }
}
