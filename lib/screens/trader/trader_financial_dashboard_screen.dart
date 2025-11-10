import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class TraderFinancialDashboardScreen extends StatelessWidget {
  const TraderFinancialDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Dashboard'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.transactionsCollection)
            .where('sellerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, salesSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.transactionsCollection)
                .where('buyerId', isEqualTo: userId)
                .where('type', isEqualTo: 'purchase')
                .snapshots(),
            builder: (context, purchaseSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('inventory')
                    .where('traderId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, inventorySnapshot) {
                  // Calculate financial metrics
                  final sales = salesSnapshot.data?.docs ?? [];
                  final purchases = purchaseSnapshot.data?.docs ?? [];
                  final inventory = inventorySnapshot.data?.docs ?? [];

                  double totalRevenue = 0;
                  double totalCost = 0;
                  double inventoryValue = 0;
                  int completedSales = 0;

                  // Calculate revenue from sales
                  for (var doc in sales) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['paymentStatus'] == 'completed') {
                      totalRevenue += (data['totalAmount'] ?? 0).toDouble();
                      completedSales++;
                    }
                  }

                  // Calculate costs from purchases
                  for (var doc in purchases) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalCost += (data['totalAmount'] ?? 0).toDouble();
                  }

                  // Calculate inventory value
                  for (var doc in inventory) {
                    final data = doc.data() as Map<String, dynamic>;
                    final qty = (data['quantityAvailable'] ?? 0).toDouble();
                    final price = (data['sellingPricePerKg'] ?? 
                                  data['purchasePricePerKg'] ?? 0).toDouble();
                    inventoryValue += qty * price;
                  }

                  final grossProfit = totalRevenue - totalCost;
                  final profitMargin = totalRevenue > 0 
                      ? (grossProfit / totalRevenue * 100) 
                      : 0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Key Metrics
                        _buildMetricCard(
                          'Gross Profit',
                          'RWF ${grossProfit.toStringAsFixed(0)}',
                          grossProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                          grossProfit >= 0 ? Colors.green : Colors.red,
                          subtitle: '${profitMargin.toStringAsFixed(1)}% margin',
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildSmallMetricCard(
                                'Revenue',
                                'RWF ${totalRevenue.toStringAsFixed(0)}',
                                Icons.arrow_upward,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSmallMetricCard(
                                'Costs',
                                'RWF ${totalCost.toStringAsFixed(0)}',
                                Icons.arrow_downward,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildSmallMetricCard(
                                'Inventory Value',
                                'RWF ${inventoryValue.toStringAsFixed(0)}',
                                Icons.inventory_2,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSmallMetricCard(
                                'Sales Count',
                                '$completedSales',
                                Icons.shopping_cart,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Revenue Breakdown
                        Text(
                          'Revenue Breakdown',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildRevenueBreakdown(sales),
                        const SizedBox(height: 24),

                        // Cost Analysis
                        Text(
                          'Cost Analysis',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildCostAnalysis(purchases),
                        const SizedBox(height: 24),

                        // Inventory Overview
                        Text(
                          'Inventory Overview',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildInventoryOverview(inventory),
                        const SizedBox(height: 24),

                        // Performance Insights
                        Text(
                          'Performance Insights',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildPerformanceInsights(
                          totalRevenue,
                          totalCost,
                          inventoryValue,
                          completedSales,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdown(List<QueryDocumentSnapshot> sales) {
    double completed = 0;
    double pending = 0;

    for (var doc in sales) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['totalAmount'] ?? 0).toDouble();
      if (data['paymentStatus'] == 'completed') {
        completed += amount;
      } else {
        pending += amount;
      }
    }

    final total = completed + pending;
    final completedPercent = total > 0 ? (completed / total * 100) : 0;
    final pendingPercent = total > 0 ? (pending / total * 100) : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBreakdownRow(
              'Completed Payments',
              'RWF ${completed.toStringAsFixed(0)}',
              completedPercent,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildBreakdownRow(
              'Pending Payments',
              'RWF ${pending.toStringAsFixed(0)}',
              pendingPercent,
              Colors.orange,
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Revenue',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'RWF ${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostAnalysis(List<QueryDocumentSnapshot> purchases) {
    double totalCost = 0;
    int purchaseCount = purchases.length;

    for (var doc in purchases) {
      final data = doc.data() as Map<String, dynamic>;
      totalCost += (data['totalAmount'] ?? 0).toDouble();
    }

    final avgCostPerPurchase = purchaseCount > 0 ? totalCost / purchaseCount : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAnalysisRow('Total Purchases', '$purchaseCount'),
            _buildAnalysisRow(
              'Total Cost',
              'RWF ${totalCost.toStringAsFixed(0)}',
            ),
            _buildAnalysisRow(
              'Avg Cost per Purchase',
              'RWF ${avgCostPerPurchase.toStringAsFixed(0)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryOverview(List<QueryDocumentSnapshot> inventory) {
    double totalStock = 0;
    double totalValue = 0;
    int itemCount = inventory.length;
    int lowStockItems = 0;

    for (var doc in inventory) {
      final data = doc.data() as Map<String, dynamic>;
      final qty = (data['quantityAvailable'] ?? 0).toDouble();
      final purchased = (data['quantityPurchased'] ?? 0).toDouble();
      final price = (data['sellingPricePerKg'] ?? data['purchasePricePerKg'] ?? 0).toDouble();
      
      totalStock += qty;
      totalValue += qty * price;
      
      if (qty < purchased * 0.2) {
        lowStockItems++;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAnalysisRow('Total Items', '$itemCount'),
            _buildAnalysisRow('Total Stock', '${totalStock.toStringAsFixed(0)} kg'),
            _buildAnalysisRow('Inventory Value', 'RWF ${totalValue.toStringAsFixed(0)}'),
            _buildAnalysisRow(
              'Low Stock Items',
              '$lowStockItems',
              color: lowStockItems > 0 ? Colors.orange : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceInsights(
    double revenue,
    double cost,
    double inventoryValue,
    int salesCount,
  ) {
    final insights = <Map<String, dynamic>>[];

    // Profit insight
    final profit = revenue - cost;
    if (profit > 0) {
      insights.add({
        'icon': Icons.trending_up,
        'color': Colors.green,
        'title': 'Profitable Business',
        'message': 'Your business is generating positive profit margins',
      });
    } else if (profit < 0) {
      insights.add({
        'icon': Icons.trending_down,
        'color': Colors.red,
        'title': 'Operating at Loss',
        'message': 'Consider adjusting your pricing strategy',
      });
    }

    // Inventory insight
    if (inventoryValue > revenue * 2) {
      insights.add({
        'icon': Icons.warning,
        'color': Colors.orange,
        'title': 'High Inventory Value',
        'message': 'Consider increasing sales to move inventory',
      });
    }

    // Sales volume insight
    if (salesCount < 5) {
      insights.add({
        'icon': Icons.info,
        'color': Colors.blue,
        'title': 'Low Sales Volume',
        'message': 'Focus on marketing to increase sales',
      });
    } else {
      insights.add({
        'icon': Icons.check_circle,
        'color': Colors.green,
        'title': 'Good Sales Activity',
        'message': 'You have healthy sales volume',
      });
    }

    return Column(
      children: insights.map((insight) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (insight['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    insight['icon'] as IconData,
                    color: insight['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        insight['message'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String value,
    double percentage,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
