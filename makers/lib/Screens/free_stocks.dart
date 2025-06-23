import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:makers/Screens/home.dart';

// Defines the FreeStocks widget, a stateful widget for managing product inventory
class FreeStocks extends StatefulWidget {
  const FreeStocks({super.key});

  @override
  State<FreeStocks> createState() => _FreeStocksState();
}

// State class for FreeStocks widget, handling dynamic UI updates
class _FreeStocksState extends State<FreeStocks>
    with SingleTickerProviderStateMixin {
  // Reference to the 'products' collection in Firestore
  final CollectionReference _products = FirebaseFirestore.instance.collection(
    'products',
  );
  // Map to store TextEditingController for each product's stock input field
  final Map<String, TextEditingController> _stockControllers = {};
  // Animation controller for UI transitions (not currently used but included for future animations)
  late AnimationController _animationController;
  // Stores the current search query for filtering products
  String _searchQuery = '';
  // Tracks whether search mode is active (not currently used but reserved for future functionality)
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller with 300ms duration
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    // Dispose all text controllers to prevent memory leaks
    _stockControllers.values.forEach((controller) => controller.dispose());
    // Dispose animation controller
    _animationController.dispose();
    super.dispose();
  }

  // Updates the stock value for a product in Firestore and the UI
  Future<void> _updateStock(String productId, int newStock) async {
    // Prevent negative stock values
    if (newStock < 0) {
      _showErrorSnackBar('Stock cannot be negative');
      return;
    }

    // Optimistically update the TextEditingController for instant UI feedback
    _stockControllers[productId]?.text = newStock.toString();

    try {
      // Update the stock field in Firestore
      await _products.doc(productId).update({'stock': newStock});
      // Show success notification
      _showSuccessSnackBar('Stock updated successfully');
      // Provide haptic feedback for user interaction
      HapticFeedback.lightImpact();
    } catch (e) {
      // Revert the TextEditingController if the update fails
      // Fetch the current stock from Firestore to revert to the correct value
      final doc = await _products.doc(productId).get();
      final currentStock = (doc.data() as Map<String, dynamic>?)?['stock'] ?? 0;
      _stockControllers[productId]?.text = currentStock.toString();
      // Show error notification
      _showErrorSnackBar('Failed to update stock: $e');
    }
  }

  // Increments the stock of a product by 1
  Future<void> _incrementStock(String productId, int currentStock) async {
    await _updateStock(productId, currentStock + 1);
  }

  // Decrements the stock of a product by 1
  Future<void> _decrementStock(String productId, int currentStock) async {
    await _updateStock(productId, currentStock - 1);
  }

  // Updates stock based on user input from text field
  Future<void> _editStock(String productId, String stockText) async {
    // Parse the input text to an integer
    final newStock = int.tryParse(stockText);
    if (newStock == null) {
      // Show error if input is not a valid number
      _showErrorSnackBar('Please enter a valid number');
      return;
    }
    await _updateStock(productId, newStock);
  }

  // Displays a success SnackBar with a custom message
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Success icon
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        // Green background for success
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Displays an error SnackBar with a custom message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Error icon
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            // Allow text to wrap if too long
            Expanded(child: Text(message)),
          ],
        ),
        // Red background for error
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Builds the search bar widget for filtering products
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        // Update search query on text change
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // Builds a status indicator for stock levels
  Widget _buildStockStatus(int stock) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    // Determine status based on stock level
    if (stock == 0) {
      statusColor = const Color(0xFFE53E3E);
      statusText = 'Out of Stock';
      statusIcon = Icons.warning;
    } else if (stock <= 5) {
      statusColor = const Color(0xFFFF8C00);
      statusText = 'Low Stock';
      statusIcon = Icons.warning_amber;
    } else {
      statusColor = const Color(0xFF4CAF50);
      statusText = 'In Stock';
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // Builds a card widget for each product
  Widget _buildProductCard(Map<String, dynamic> product, String productId) {
    // Extract product details

    final currentStock = product['stock'] ?? 0;
    final productName = product['name'] ?? 'No name';
    final productId_display = product['id'] ?? '';

    // Initialize text controller for stock input if not already present
    _stockControllers.putIfAbsent(
      productId,
      () => TextEditingController(text: currentStock.toString()),
    );

    // Filter product based on search query
    if (_searchQuery.isNotEmpty &&
        !productName.toLowerCase().contains(_searchQuery) &&
        !productId_display.toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Product image and details row
            Row(
              children: [
                // Product image container
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: product['imageUrl'] ?? '',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      // Placeholder while image loads
                      placeholder: (context, url) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                      // Error widget if image fails to load
                      errorWidget: (context, url, error) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey.shade400,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Product ID
                      Text(
                        'ID: $productId_display',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Stock status indicator
                      _buildStockStatus(currentStock),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stock control section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Decrease stock button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _decrementStock(productId, currentStock),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53E3E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE53E3E).withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: Color(0xFFE53E3E),
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Stock input field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _stockControllers[productId],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          border: InputBorder.none,
                          hintText: '0',
                        ),
                        // Update stock on submit
                        onSubmitted: (value) => _editStock(productId, value),
                        // Allow only digits
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Increase stock button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _incrementStock(productId, currentStock),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF4CAF50),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Handle back button to navigate to Dashboard
      onWillPop: () async {
        Get.off(() => Dashboard());
        return false;
      },
      child: Scaffold(
        // Light background color for the scaffold
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          // Yellow background for app bar
          backgroundColor: Color(0xFFFFCC3E),
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Text(
            'Inventory Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          actions: [
            // Refresh button to reload data
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {});
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar for filtering products
            _buildSearchBar(),
            // Expanded list view for products
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Stream of product data from Firestore
                stream: _products.snapshots(),
                builder: (context, snapshot) {
                  // Handle error state
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Something went wrong',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // Handle loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF6366F1),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading products...',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Handle empty data state
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add some products to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Build list of product cards
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final product = doc.data() as Map<String, dynamic>;
                      final productId = doc.id;

                      return _buildProductCard(product, productId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
