import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:makers/Controller/Auth_Controller/individual_details_controller.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String docId;

  const OrderDetailPage({
    super.key,
    required this.orderData,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize GetX controller
    final controller = Get.put(
      OrderDetailController(orderData: orderData, docId: docId),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Order #${orderData['orderId'] ?? 'N/A'}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusSection(controller, context),
            const SizedBox(height: 20),
            _buildCustomerInfoSection(),
            const SizedBox(height: 20),
            _buildOrderDetailsSection(),
            const SizedBox(height: 20),
            _buildAddressSection(),
            const SizedBox(height: 20),
            _buildRemarksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(
    OrderDetailController controller,
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.currentStatus.value,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: controller.statusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          controller.getStatusIcon(status),
                          size: 20,
                          color: controller.getStatusColor(status),
                        ),
                        const SizedBox(width: 8),
                        Text(controller.getStatusText(status)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) async {
                  if (newValue != null &&
                      newValue != controller.currentStatus.value) {
                    if (newValue == 'sent out for delivery') {
                      // Show date picker when "sent out for delivery" is selected
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate:
                            controller.selectedDeliveryDate.value ??
                            DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (pickedDate != null) {
                        controller.setDeliveryDate(pickedDate);
                        await controller.updateOrderStatus(newValue);
                      } else {
                        // Revert to previous status if no date is selected
                        return;
                      }
                    } else {
                      controller.setDeliveryDate(null);
                      await controller.updateOrderStatus(newValue);
                    }
                  }
                },
              ),
            ),
            // Display and allow modification of delivery date
            Obx(
              () =>
                  controller.currentStatus.value == 'sent out for delivery' &&
                      controller.selectedDeliveryDate.value != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Delivery Date: ${DateFormat('dd MMM yyyy').format(controller.selectedDeliveryDate.value!)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              // Show date picker to modify the delivery date
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate:
                                    controller.selectedDeliveryDate.value ??
                                    DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 30),
                                ),
                              );
                              if (pickedDate != null) {
                                controller.setDeliveryDate(pickedDate);
                                await controller.updateOrderStatus(
                                  'sent out for delivery',
                                );
                              }
                            },
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Name', orderData['name']),
            _buildInfoRow(Icons.phone, 'Phone', orderData['phone1']),
            if (orderData['phone2'] != null &&
                orderData['phone2'].toString().isNotEmpty)
              _buildInfoRow(
                Icons.phone_outlined,
                'Phone 2',
                orderData['phone2'],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.confirmation_number,
              'Order ID',
              orderData['orderId'],
            ),
            _buildInfoRow(
              Icons.inventory_2,
              'Product ID',
              orderData['productID'],
            ),
            if (orderData['quantity'] != null)
              _buildInfoRow(
                Icons.numbers,
                'Quantity',
                orderData['quantity'].toString(),
              ),
            if (orderData['price'] != null)
              _buildInfoRow(
                Icons.currency_rupee,
                'Price',
                '₹${orderData['price']}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderData['address'] ?? 'N/A',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (orderData['place'] != null)
                    Text(
                      orderData['place'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Remarks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                orderData['remark'] == null ||
                        orderData['remark'].toString().isEmpty
                    ? 'No remarks'
                    : orderData['remark'].toString(),
                style: TextStyle(
                  fontSize: 14,
                  color:
                      orderData['remark'] == null ||
                          orderData['remark'].toString().isEmpty
                      ? Colors.grey[500]
                      : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value?.toString() ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
