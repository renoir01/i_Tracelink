import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class EarningsDashboardScreen extends StatelessWidget {
  const EarningsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings Dashboard'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('sellerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data?.docs ?? [];
          
          // Calculate statistics
          double totalEarnings = 0;
          double completedEarnings = 0;
          double pendingEarnings = 0;
          int totalTransactions = transactions.length;
          int completedTransactions = 0;

          Map<String, double> monthlyEarnings = {};

          for (var doc in transactions) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['totalAmount'] ?? 0).toDouble();
            final status = data['paymentStatus'] ?? 'pending';
            
            totalEarnings += amount;
            
            if (status == 'completed') {
              completedEarnings += amount;
              completedTransactions++;
            } else {
              pendingEarnings += amount;
            }

            // Group by month
            final date = (data['transactionDate'] as Timestamp?)?.toDate();
            if (date != null) {
              final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
              monthlyEarnings[monthKey] = (monthlyEarnings[monthKey] ?? 0) + amount;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                _buildSummaryCard(
                  'Total Earnings',
                  'RWF ${completedEarnings.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  Colors.green,
                  subtitle: 'From completed transactions',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallSummaryCard(
                        'Pending',
                        'RWF ${pendingEarnings.toStringAsFixed(0)}',
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSmallSummaryCard(
                        'Transactions',
                        '$completedTransactions/$totalTransactions',
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Average price
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('batches')
                      .where('farmerId', isEqualTo: userId)
                      .where('status', isEqualTo: 'sold')
                      .snapshots(),
                  builder: (context, batchSnapshot) {
                    final batches = batchSnapshot.data?.docs ?? [];
                    double totalQuantity = 0;
                    double totalRevenue = 0;

                    for (var doc in batches) {
                      final data = doc.data() as Map<String, dynamic>;
                      final qty = (data['quantity'] ?? 0).toDouble();
                      final price = (data['pricePerKg'] ?? 0).toDouble();
                      totalQuantity += qty;
                      totalRevenue += qty * price;
                    }

                    final avgPrice = totalQuantity > 0 ? totalRevenue / totalQuantity : 0;

                    return _buildSummaryCard(
                      'Average Price',
                      'RWF ${avgPrice.toStringAsFixed(0)}/kg',
                      Icons.trending_up,
                      Colors.purple,
                      subtitle: 'From ${batches.length} sold batches',
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Transaction History
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildTransactionList(transactions),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallSummaryCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<QueryDocumentSnapshot> transactions) {
    if (transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No transactions yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: transactions.take(10).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['transactionDate'] as Timestamp?)?.toDate();
        final paymentStatus = data['paymentStatus'] ?? 'pending';
        final amount = (data['totalAmount'] ?? 0).toDouble();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: paymentStatus == 'completed'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                paymentStatus == 'completed'
                    ? Icons.check_circle
                    : Icons.pending,
                color: paymentStatus == 'completed'
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            title: Text(
              data['buyerName'] ?? 'Transaction',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'No date',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RWF ${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: paymentStatus == 'completed'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                Text(
                  '${data['quantity']} kg',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
