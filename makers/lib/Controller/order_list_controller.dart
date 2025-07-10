import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderController extends GetxController {
  final RxList<QueryDocumentSnapshot> orders = <QueryDocumentSnapshot>[].obs;
  final RxList<QueryDocumentSnapshot> filteredOrders =
      <QueryDocumentSnapshot>[].obs;
  final String currentId = FirebaseAuth.instance.currentUser!.uid;

  // Filter variables
  final RxString selectedStatus = ''.obs;
  final RxString selectedPriority = ''.obs;
  final Rxn<DateTimeRange> selectedDateRange = Rxn<DateTimeRange>();

  @override
  void onInit() {
    super.onInit();
    debugPrint('Current user ID: $currentId');
    bindStream();

    // Listen to changes in orders and apply filters
    ever(orders, (_) => applyFiltersWithSearch());
    ever(selectedStatus, (_) => applyFiltersWithSearch());

    ever(selectedDateRange, (_) => applyFiltersWithSearch());
    ever(searchQuery, (_) => applyFiltersWithSearch());
  }

  void bindStream() {
    orders.bindStream(
      FirebaseFirestore.instance
          .collection('Orders')
          .where('makerId', isEqualTo: currentId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs),
    );
  }

  void applyFilters() {
    List<QueryDocumentSnapshot> filtered = List.from(orders);

    // Filter by status
    if (selectedStatus.value.isNotEmpty) {
      filtered = filtered.where((order) {
        final data = order.data() as Map<String, dynamic>;
        final status = data['order_status'] ?? '';
        return status.toLowerCase() == selectedStatus.value.toLowerCase();
      }).toList();
    }

    // Filter by date range
    if (selectedDateRange.value != null) {
      filtered = filtered.where((order) {
        final data = order.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt == null) return false;

        final orderDate = createdAt.toDate();
        final startDate = selectedDateRange.value!.start;
        final endDate = selectedDateRange.value!.end.add(
          const Duration(days: 1),
        ); // Include end date

        return orderDate.isAfter(startDate) && orderDate.isBefore(endDate);
      }).toList();
    }

    filteredOrders.value = filtered;
  }

  // Status filter methods
  void setStatusFilter(String status) {
    selectedStatus.value = status;
  }

  void clearStatusFilter() {
    selectedStatus.value = '';
  }

  void clearPriorityFilter() {
    selectedPriority.value = '';
  }

  // Date filter methods
  Future<void> selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: selectedDateRange.value,
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedDateRange.value = picked;
    }
  }

  void clearDateFilter() {
    selectedDateRange.value = null;
  }

  // Quick date filter methods
  void setTodayFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    selectedDateRange.value = DateTimeRange(start: today, end: today);
  }

  void setThisWeekFilter() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    selectedDateRange.value = DateTimeRange(
      start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day),
    );
  }

  void setThisMonthFilter() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    selectedDateRange.value = DateTimeRange(
      start: startOfMonth,
      end: endOfMonth,
    );
  }

  void setLast30DaysFilter() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    selectedDateRange.value = DateTimeRange(
      start: DateTime(
        thirtyDaysAgo.year,
        thirtyDaysAgo.month,
        thirtyDaysAgo.day,
      ),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  // Clear all filters
  void clearAllFilters() {
    selectedStatus.value = '';
    selectedPriority.value = '';
    selectedDateRange.value = null;
  }

  // Helper methods
  String getDateRangeText() {
    if (selectedDateRange.value == null) return '';

    final formatter = DateFormat('MMM d, y');
    final start = formatter.format(selectedDateRange.value!.start);
    final end = formatter.format(selectedDateRange.value!.end);

    if (selectedDateRange.value!.start == selectedDateRange.value!.end) {
      return start;
    }

    return '$start - $end';
  }

  // Get filter count for UI
  int get activeFilterCount {
    int count = 0;
    if (selectedStatus.value.isNotEmpty) count++;
    if (selectedPriority.value.isNotEmpty) count++;
    if (selectedDateRange.value != null) count++;
    return count;
  }

  // Get summary statistics
  Map<String, int> get orderStatusCounts {
    final counts = <String, int>{};
    for (final order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final status = data['order_status'] ?? 'pending';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get priorityCounts {
    final counts = <String, int>{};
    for (final order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final priority = data['status'] ?? 'MEDIUM';
      counts[priority] = (counts[priority] ?? 0) + 1;
    }
    return counts;
  }

  // Search functionality
  final RxString searchQuery = ''.obs;

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void applyFiltersWithSearch() {
    List<QueryDocumentSnapshot> filtered = List.from(orders);

    // Apply existing filters first
    if (selectedStatus.value.isNotEmpty) {
      filtered = filtered.where((order) {
        final data = order.data() as Map<String, dynamic>;
        final status = data['order_status'] ?? '';
        return status.toLowerCase() == selectedStatus.value.toLowerCase();
      }).toList();
    }

    if (selectedDateRange.value != null) {
      filtered = filtered.where((order) {
        final data = order.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt == null) return false;

        final orderDate = createdAt.toDate();
        final startDate = selectedDateRange.value!.start;
        final endDate = selectedDateRange.value!.end.add(
          const Duration(days: 1),
        );

        return orderDate.isAfter(startDate) && orderDate.isBefore(endDate);
      }).toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((order) {
        final data = order.data() as Map<String, dynamic>;
        final orderId = (data['orderId'] ?? '').toString().toLowerCase();
        final name = (data['name'] ?? '').toString().toLowerCase();
        final phone = (data['phone1'] ?? '').toString().toLowerCase();
        final productId = (data['productID'] ?? '').toString().toLowerCase();
        final address = (data['address'] ?? '').toString().toLowerCase();
        final place = (data['place'] ?? '').toString().toLowerCase();

        return orderId.contains(query) ||
            name.contains(query) ||
            phone.contains(query) ||
            productId.contains(query) ||
            address.contains(query) ||
            place.contains(query);
      }).toList();
    }

    filteredOrders.value = filtered;
    applySorting();
  }

  // Sort functionality
  final RxString sortBy = 'createdAt'.obs;
  final RxBool sortDescending = true.obs;

  void setSortBy(String field) {
    if (sortBy.value == field) {
      sortDescending.value = !sortDescending.value;
    } else {
      sortBy.value = field;
      sortDescending.value = true;
    }
    applySorting();
  }

  void applySorting() {
    final sorted = List<QueryDocumentSnapshot>.from(filteredOrders);

    sorted.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      dynamic valueA, valueB;

      switch (sortBy.value) {
        case 'createdAt':
          valueA = dataA['createdAt'] as Timestamp?;
          valueB = dataB['createdAt'] as Timestamp?;
          if (valueA == null || valueB == null) return 0;
          valueA = valueA.toDate();
          valueB = valueB.toDate();
          break;
        case 'deliveryDate':
          valueA = dataA['deliveryDate'] as Timestamp?;
          valueB = dataB['deliveryDate'] as Timestamp?;
          if (valueA == null && valueB == null) return 0;
          if (valueA == null) return 1;
          if (valueB == null) return -1;
          valueA = valueA.toDate();
          valueB = valueB.toDate();
          break;
        case 'orderId':
          valueA = dataA['orderId'] ?? '';
          valueB = dataB['orderId'] ?? '';
          break;
        case 'name':
          valueA = dataA['name'] ?? '';
          valueB = dataB['name'] ?? '';
          break;
        case 'status':
          valueA = dataA['order_status'] ?? '';
          valueB = dataB['order_status'] ?? '';
          break;

        default:
          return 0;
      }

      int comparison;
      if (valueA is DateTime && valueB is DateTime) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is String && valueB is String) {
        comparison = valueA.toLowerCase().compareTo(valueB.toLowerCase());
      } else if (valueA is int && valueB is int) {
        comparison = valueA.compareTo(valueB);
      } else {
        comparison = valueA.toString().compareTo(valueB.toString());
      }

      return sortDescending.value ? -comparison : comparison;
    });

    filteredOrders.value = sorted;
  }

  // // Export functionality
  // Future<void> exportFilteredOrders() async {
  //   try {
  //     // final data = filteredOrders.map((order) {
  //     //   final orderData = order.data() as Map<String, dynamic>;
  //     //   return {
  //     //     'Order ID': orderData['orderId'] ?? '',
  //     //     'Name': orderData['name'] ?? '',
  //     //     'Phone': orderData['phone1'] ?? '',
  //     //     'Product ID': orderData['productID'] ?? '',
  //     //     'Status': orderData['order_status'] ?? '',
  //     //     'Address': orderData['address'] ?? '',
  //     //     'Place': orderData['place'] ?? '',
  //     //     'Created At': orderData['createdAt'] != null
  //     //         ? DateFormat(
  //     //             'yyyy-MM-dd HH:mm',
  //     //           ).format((orderData['createdAt'] as Timestamp).toDate())
  //     //         : '',
  //     //     'Delivery Date': orderData['deliveryDate'] != null
  //     //         ? DateFormat(
  //     //             'yyyy-MM-dd',
  //     //           ).format((orderData['deliveryDate'] as Timestamp).toDate())
  //     //         : '',
  //     //     'Quantity': orderData['nos'] ?? 0,
  //     //     'Remark': orderData['remark'] ?? '',
  //     //   };
  //     // }).toList();

  //     // Here you would implement the actual export logic
  //     // For example, using csv package or sharing the data
  //     Get.snackbar(
  //       'Export',
  //       'Export functionality would be implemented here',
  //       snackPosition: SnackPosition.BOTTOM,
  //     );
  //   } catch (e) {
  //     Get.snackbar(
  //       'Error',
  //       'Failed to export orders: $e',
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: Colors.red[100],
  //     );
  //   }
  // }

  // Refresh orders
  Future<void> refreshOrders() async {
    try {
      // Force refresh by re-binding the stream
      bindStream();
      Get.snackbar(
        'Refreshed',
        'Orders updated successfully',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to refresh orders: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }

  // Get overdue orders (past delivery date)
  List<QueryDocumentSnapshot> get overdueOrders {
    final now = DateTime.now();
    return orders.where((order) {
      final data = order.data() as Map<String, dynamic>;
      final deliveryDate = data['deliveryDate'] as Timestamp?;
      final status = data['order_status'] ?? '';

      if (deliveryDate == null || status.toLowerCase() == 'delivered') {
        return false;
      }

      return deliveryDate.toDate().isBefore(now);
    }).toList();
  }

  // Get urgent orders (delivery date within next 2 days)
  List<QueryDocumentSnapshot> get urgentOrders {
    final now = DateTime.now();
    final twoDaysFromNow = now.add(const Duration(days: 2));

    return orders.where((order) {
      final data = order.data() as Map<String, dynamic>;
      final deliveryDate = data['deliveryDate'] as Timestamp?;
      final status = data['order_status'] ?? '';

      if (deliveryDate == null || status.toLowerCase() == 'delivered') {
        return false;
      }

      final delivery = deliveryDate.toDate();
      return delivery.isAfter(now) && delivery.isBefore(twoDaysFromNow);
    }).toList();
  }

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}
