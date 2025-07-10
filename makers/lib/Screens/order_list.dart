import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:makers/Controller/order_list_controller.dart';
import 'package:makers/Screens/individual_details.dart';

class OrderList extends StatelessWidget {
  const OrderList({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    Get.put(OrderController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          _buildSortOptions(),
          Expanded(
            child: Obx(() {
              final controller = Get.find<OrderController>();

              if (controller.filteredOrders.isEmpty &&
                  controller.orders.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No orders match your filters',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            Get.find<OrderController>().clearAllFilters(),
                        child: const Text('Clear Filters'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No orders found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your orders will appear here',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await Get.find<OrderController>().refreshOrders();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: controller.filteredOrders.length,
                  itemBuilder: (context, index) {
                    final data =
                        controller.filteredOrders[index].data()
                            as Map<String, dynamic>;
                    final docId = controller.filteredOrders[index].id;
                    return _buildOrderCard(context, data, docId);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => Get.find<OrderController>().setSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Search orders by ID, name, phone, product...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() {
            final controller = Get.find<OrderController>();
            return controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => controller.setSearchQuery(''),
                  )
                : const SizedBox.shrink();
          }),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[600]!),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Sort by:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(() {
                final controller = Get.find<OrderController>();
                return Row(
                  children: [
                    _buildSortChip('Date', 'createdAt', controller),
                    const SizedBox(width: 8),
                    _buildSortChip('Delivery', 'deliveryDate', controller),
                    const SizedBox(width: 8),
                    _buildSortChip('Order ID', 'orderId', controller),
                    const SizedBox(width: 8),
                    _buildSortChip('Name', 'name', controller),
                    const SizedBox(width: 8),
                    _buildSortChip('Status', 'status', controller),
                    const SizedBox(width: 8),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(
    String label,
    String field,
    OrderController controller,
  ) {
    final isSelected = controller.sortBy.value == field;
    return GestureDetector(
      onTap: () => controller.setSortBy(field),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.blue[700] : Colors.grey[700],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                controller.sortDescending.value
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                size: 14,
                color: Colors.blue[700],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Obx(() {
      final controller = Get.find<OrderController>();
      final activeFilters = <Widget>[];

      if (controller.selectedStatus.value.isNotEmpty) {
        activeFilters.add(
          Chip(
            label: Text(
              'Status: ${_getStatusText(controller.selectedStatus.value)}',
            ),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () => controller.clearStatusFilter(),
            backgroundColor: _getStatusColor(
              controller.selectedStatus.value,
            ).withOpacity(0.1),
          ),
        );
      }

      if (controller.selectedDateRange.value != null) {
        activeFilters.add(
          Chip(
            label: Text('Date: ${controller.getDateRangeText()}'),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () => controller.clearDateFilter(),
            backgroundColor: Colors.blue.withOpacity(0.1),
          ),
        );
      }

      if (activeFilters.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ...activeFilters,
            if (activeFilters.length > 1)
              ActionChip(
                label: const Text('Clear All'),
                onPressed: () => controller.clearAllFilters(),
                backgroundColor: Colors.red.withOpacity(0.1),
              ),
          ],
        ),
      );
    });
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) =>
            _buildFilterContent(scrollController),
      ),
    );
  }

  Widget _buildFilterContent(ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => Get.find<OrderController>().clearAllFilters(),
                child: const Text('Clear All'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                _buildStatusFilter(),
                const SizedBox(height: 20),

                _buildDateFilter(),
                const SizedBox(height: 20),
                _buildQuickDateFilters(),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = [
      'pending',
      'accepted',

      'sent out for delivery',
      'delivered',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final controller = Get.find<OrderController>();
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses.map((status) {
              final isSelected = controller.selectedStatus.value == status;
              return FilterChip(
                label: Text(_getStatusText(status)),
                selected: isSelected,
                onSelected: (selected) =>
                    controller.setStatusFilter(selected ? status : ''),
                backgroundColor: Colors.grey[100],
                selectedColor: _getStatusColor(status).withOpacity(0.2),
                checkmarkColor: _getStatusColor(status),
                avatar: isSelected
                    ? null
                    : Icon(_getStatusIcon(status), size: 16),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final controller = Get.find<OrderController>();
          return InkWell(
            onTap: () => controller.selectDateRange(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.selectedDateRange.value != null
                          ? controller.getDateRangeText()
                          : 'Select date range',
                      style: TextStyle(
                        color: controller.selectedDateRange.value != null
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                  if (controller.selectedDateRange.value != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => controller.clearDateFilter(),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickDateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Filters',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickDateChip(
              'Today',
              () => Get.find<OrderController>().setTodayFilter(),
            ),
            _buildQuickDateChip(
              'This Week',
              () => Get.find<OrderController>().setThisWeekFilter(),
            ),
            _buildQuickDateChip(
              'This Month',
              () => Get.find<OrderController>().setThisMonthFilter(),
            ),
            _buildQuickDateChip(
              'Last 30 Days',
              () => Get.find<OrderController>().setLast30DaysFilter(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickDateChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.blue[50],
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    final orderStatus = data['order_status'] ?? 'pending';
    final priority = data['status'] ?? '';
    final statusColor = _getStatusColor(orderStatus);
    final statusIcon = _getStatusIcon(orderStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Get.to(() => OrderDetailPage(orderData: data, docId: docId));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${data['orderId'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (priority.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusText(orderStatus),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data['name'] ?? 'N/A',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    data['phone1'] ?? 'N/A',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data['productID'] ?? 'N/A',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.blue[600],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  IconData _getStatusIcon(String status) {
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

  String _getStatusText(String status) {
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
