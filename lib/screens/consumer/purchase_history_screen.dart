import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import 'product_information_screen.dart';

class PurchaseHistoryScreen extends StatelessWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase History'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.consumerPurchasesCollection)
            .where('consumerId', isEqualTo: userId)
            .orderBy('scanDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final purchases = snapshot.data?.docs ?? [];

          if (purchases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No purchase history yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start scanning products to build your history',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Group by date
          final groupedPurchases = <String, List<QueryDocumentSnapshot>>{};
          for (var doc in purchases) {
            final data = doc.data() as Map<String, dynamic>;
            final scanDate = (data['scanDate'] as Timestamp?)?.toDate();
            if (scanDate != null) {
              final dateKey = '${scanDate.day}/${scanDate.month}/${scanDate.year}';
              groupedPurchases.putIfAbsent(dateKey, () => []).add(doc);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card
              _buildSummaryCard(purchases),
              const SizedBox(height: 16),

              // Grouped Purchases
              ...groupedPurchases.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...entry.value.map((doc) => _buildPurchaseCard(context, doc)),
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(List<QueryDocumentSnapshot> purchases) {
    final totalScans = purchases.length;
    final verified = purchases.where((p) {
      final data = p.data() as Map<String, dynamic>;
      return data['wasVerified'] == true;
    }).length;
    final uniqueSellers = purchases.map((p) {
      final data = p.data() as Map<String, dynamic>;
      return data['sellerId'] ?? '';
    }).toSet().length;

    double totalSpent = 0;
    for (var doc in purchases) {
      final data = doc.data() as Map<String, dynamic>;
      totalSpent += (data['totalAmount'] ?? 0).toDouble();
    }

    return Card(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('Total Scans', '$totalScans', Icons.qr_code_scanner),
                ),
                Expanded(
                  child: _buildSummaryItem('Verified', '$verified', Icons.verified),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('Sellers', '$uniqueSellers', Icons.store),
                ),
                if (totalSpent > 0)
                  Expanded(
                    child: _buildSummaryItem(
                      'Spent',
                      'RWF ${totalSpent.toStringAsFixed(0)}',
                      Icons.attach_money,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPurchaseCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final scanDate = (data['scanDate'] as Timestamp?)?.toDate();
    final purchaseDate = (data['purchaseDate'] as Timestamp?)?.toDate();
    final wasVerified = data['wasVerified'] ?? false;
    final rating = data['rating'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          // Fetch batch data and navigate to product info
          final batchId = data['batchId'];
          final batchDoc = await FirebaseFirestore.instance
              .collection(AppConstants.batchesCollection)
              .doc(batchId)
              .get();

          if (batchDoc.exists && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductInformationScreen(
                  batchId: batchId,
                  batchData: batchDoc.data() as Map<String, dynamic>,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: wasVerified
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  wasVerified ? Icons.verified : Icons.warning,
                  color: wasVerified ? Colors.green : Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Purchase Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['sellerName'] ?? 'Unknown Seller',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['sellerType']?.toString().toUpperCase() ?? 'TRADER',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Right Side Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    scanDate != null
                        ? '${scanDate.hour}:${scanDate.minute.toString().padLeft(2, '0')}'
                        : '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  if (data['quantityPurchased'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${data['quantityPurchased']} kg',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (data['totalAmount'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'RWF ${data['totalAmount']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
