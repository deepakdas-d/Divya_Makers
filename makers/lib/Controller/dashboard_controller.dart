import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:makers/Auth/Screens/signin.dart';

class DashboardController extends GetxController {
  var stockData = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  final orderCount = (-1).obs; // -1 indicates loading
  final pendingCount = (-1).obs;
  final outForDeliveryCount = (-1).obs;
  final inProgressCount = (-1).obs;
  final acceptedCount = (-1).obs;
  DateTime? lastFetchedMonth;

  @override
  void onInit() {
    super.onInit();
    fetchOrderCounts();
    ever(orderCount, (_) {
      final now = DateTime.now();
      if (lastFetchedMonth == null ||
          now.month != lastFetchedMonth!.month ||
          now.year != lastFetchedMonth!.year) {
        fetchOrderCounts();
      }
    });
  }

  void fetchOrderCounts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(
          now.year,
          now.month + 1,
          1,
        ).subtract(Duration(seconds: 1));

        final querySnapshot = await FirebaseFirestore.instance
            .collection('Orders')
            .where('makerId', isEqualTo: user.uid)
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
            )
            .where(
              'createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
            )
            .get();

        int pending = 0, outForDelivery = 0, inProgress = 0, accepted = 0;
        for (var doc in querySnapshot.docs) {
          // Check if order_status field exists and is a valid string
          if (doc.data().containsKey('order_status') &&
              doc['order_status'] is String) {
            final status = doc['order_status'];
            switch (status) {
              case 'pending':
                pending++;
                break;
              case 'sent out for delivery':
                outForDelivery++;
                break;
              case 'inprogress':
                inProgress++;
                break;
              case 'accepted':
                accepted++;
                break;
              default:
                print('Unknown order_status: $status in document ${doc.id}');
              // Handle unexpected status values if needed
            }
          } else {
            print('Missing or invalid order_status in document ${doc.id}');
          }
        }

        orderCount.value = querySnapshot.docs.length;
        pendingCount.value = pending;
        outForDeliveryCount.value = outForDelivery;
        inProgressCount.value = inProgress;
        acceptedCount.value = accepted;
        lastFetchedMonth = now;
        isLoading.value = false;
      } else {
        orderCount.value = 0;
        pendingCount.value = 0;
        outForDeliveryCount.value = 0;
        inProgressCount.value = 0;
        acceptedCount.value = 0;
        isLoading.value = false;
      }
    } catch (e) {
      print('Error fetching order counts: $e');
      orderCount.value = 0;
      pendingCount.value = 0;
      outForDeliveryCount.value = 0;
      inProgressCount.value = 0;
      acceptedCount.value = 0;
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => Signin());
  }
}
