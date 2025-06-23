import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:makers/Controller/dashboard_controller.dart';
import 'package:makers/Screens/free_stocks.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Roboto',
          ),
        ),
        backgroundColor: Color(0xFFFFD700),
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.all(size.width * 0.02),
            child: IconButton(
              onPressed: controller.logout,
              icon: Icon(
                Icons.logout_outlined,
                size: size.width * 0.07,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: controller.fetchStockData,
        color: Color(0xFFFFD700),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStockChart(controller, size),
              SizedBox(height: size.height * 0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.02),
              _buildMenuTile(
                title: 'Free Stocks',
                icon: Icons.inventory_2,
                iconColor: Colors.green,
                onTap: () => Get.offAll(() => FreeStocks()),
                size: size,
              ),
              _buildMenuTile(
                title: 'Order List',
                icon: Icons.list_alt,
                iconColor: Colors.blue,
                onTap: () => print('Navigate to Order List'),
                size: size,
              ),
              _buildMenuTile(
                title: 'Complaints',
                icon: Icons.report_problem,
                iconColor: Colors.orange,
                onTap: () => print('Navigate to Complaints'),
                size: size,
              ),
              SizedBox(height: size.height * 0.02),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.fetchStockData,
        backgroundColor: Color(0xFFFFD700),
        child: Icon(Icons.refresh, color: Colors.black87),
      ),
    );
  }

  Widget _buildStockChart(DashboardController controller, Size size) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          height: size.height * 0.3,
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFD700),
              strokeWidth: 10,
            ),
          ),
        );
      }

      if (controller.stockData.isEmpty) {
        return Container(
          height: size.height * 0.3,
          child: Center(
            child: Text(
              'No stock data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Roboto',
              ),
            ),
          ),
        );
      }

      double maxStock = controller.stockData
          .map((e) => e['stock'] as int)
          .reduce((a, b) => a > b ? a : b)
          .toDouble();

      return Container(
        height: size.height * 0.5,
        margin: EdgeInsets.all(size.width * 0.04),
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Levels',
              style: TextStyle(
                fontSize: size.width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: size.height * 0.02),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxStock + (maxStock * 0.15),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipMargin: 10,
                      tooltipPadding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.03,
                        vertical: size.height * 0.01,
                      ),
                      getTooltipColor: (group) =>
                          Colors.black87.withOpacity(0.9),
                      tooltipBorder: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = controller.stockData[group.x];
                        return BarTooltipItem(
                          '${data['name']}\n${rod.toY.round()} units\n${data['description']}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: size.width * 0.035,
                            fontFamily: 'Roboto',
                          ),
                          children: [
                            TextSpan(
                              text: '\nTap to view details',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: size.width * 0.03,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: size.height * 0.07,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < controller.stockData.length) {
                            String productName =
                                controller.stockData[value.toInt()]['name'];
                            if (productName.length > 10) {
                              productName =
                                  productName.substring(0, 10) + '...';
                            }
                            return Transform.rotate(
                              angle: -45 * (3.14159 / 180),
                              child: Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text(
                                  productName,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: size.width * 0.03,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxStock > 2
                            ? (maxStock / 5).ceilToDouble()
                            : 1,
                        reservedSize: size.width * 0.1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: size.width * 0.03,
                              fontFamily: 'Roboto',
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      left: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    ),
                  ),
                  barGroups: _generateBarChartGroups(controller, size),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxStock > 10
                        ? (maxStock / 5).ceilToDouble()
                        : 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200]!.withOpacity(0.5),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.stockData.map((data) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.02,
                      vertical: size.height * 0.005,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        print('Tapped on ${data['name']}');
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: size.width * 0.04,
                            height: size.width * 0.04,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  data['color'],
                                  data['color'].withOpacity(0.6),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: size.width * 0.02),
                          Text(
                            '${data['name']} (${data['stock']})',
                            style: TextStyle(
                              fontSize: size.width * 0.032,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    });
  }

  List<BarChartGroupData> _generateBarChartGroups(
    DashboardController controller,
    Size size,
  ) {
    return controller.stockData.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> data = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data['stock'].toDouble(),
            gradient: LinearGradient(
              colors: [data['color'], data['color'].withOpacity(0.6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            // width: controller.stockData.length > 10 ? 12 : 20,
            width: (size.width / controller.stockData.length) * 0.4,

            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              color: Colors.grey.withOpacity(0.2),
              toY: data['stock'].toDouble(),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildMenuTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Size size,
    Color? iconColor,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.01,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(size.width * 0.02),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.blue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Colors.blue,
            size: size.width * 0.05,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: size.width * 0.04,
            fontWeight: FontWeight.w500,
            fontFamily: 'Roboto',
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: size.width * 0.04,
          color: Colors.grey[600],
        ),
        onTap: onTap,
      ),
    );
  }
}
