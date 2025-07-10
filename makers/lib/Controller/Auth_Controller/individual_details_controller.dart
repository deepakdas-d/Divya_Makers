import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderDetailController extends GetxController {
  final Map<String, dynamic> orderData;
  final String docId;
  final RxString currentStatus = ''.obs;
  final Rx<DateTime?> selectedDeliveryDate = Rx<DateTime?>(null);

  final List<String> statusOptions = [
    'pending',
    'accepted',
    'sent out for delivery',
    'delivered',
  ];

  OrderDetailController({required this.orderData, required this.docId}) {
    currentStatus.value = orderData['order_status'] ?? 'pending';

    if (orderData['deliveryDate'] != null) {
      selectedDeliveryDate.value = (orderData['deliveryDate'] as Timestamp?)
          ?.toDate();
    }

    // Auto-check delivery status when controller is initialized
    _checkAndAutoUpdateDeliveryStatus();
  }

  Future<void> updateOrderStatus(String newStatus) async {
    try {
      Map<String, dynamic> updateData = {'order_status': newStatus};

      if (newStatus == 'sent out for delivery' &&
          selectedDeliveryDate.value != null) {
        updateData['deliveryDate'] = Timestamp.fromDate(
          selectedDeliveryDate.value!,
        );
      } else {
        updateData['deliveryDate'] = null;
        selectedDeliveryDate.value = null;
      }

      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(docId)
          .update(updateData);

      currentStatus.value = newStatus;

      Get.snackbar(
        'Success',
        'Order status updated to ${getStatusText(newStatus)}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Check for auto-delivery condition
      _checkAndAutoUpdateDeliveryStatus();
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

  void setDeliveryDate(DateTime? date) {
    selectedDeliveryDate.value = date;
    if (currentStatus.value == 'sent out for delivery') {
      // If status is 'sent out for delivery', update Firestore immediately
      updateOrderStatus('sent out for delivery');
    }
  }

  Future<void> _checkAndAutoUpdateDeliveryStatus() async {
    if (currentStatus.value == 'sent out for delivery' &&
        selectedDeliveryDate.value != null) {
      DateTime now = DateTime.now();
      DateTime deliveryDate = selectedDeliveryDate.value!;

      if (!deliveryDate.isAfter(now)) {
        try {
          await FirebaseFirestore.instance
              .collection('Orders')
              .doc(docId)
              .update({'order_status': 'delivered'});

          currentStatus.value = 'delivered';

          Get.snackbar(
            'Info',
            'Order automatically marked as Delivered',
            backgroundColor: Colors.teal,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        } catch (e) {
          debugPrint("Auto-update delivery error: $e");
        }
      }
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
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
      case 'sent out for delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Pending';
    }
  }
}
