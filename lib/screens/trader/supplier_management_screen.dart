import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class SupplierManagementScreen extends StatelessWidget {
  const SupplierManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Management'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('inventory')
            .where('traderId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final inventory = snapshot.data?.docs ?? [];

          // Group by supplier
          final supplierMap = <String, Map<String, dynamic>>{};
          for (var doc in inventory) {
            final data = doc.data() as Map<String, dynamic>;
            final supplierId = data['supplierId'] ?? '';
            
            if (!supplierMap.containsKey(supplierId)) {
              supplierMap[supplierId] = {
                'supplierName': data['supplierName'],
                'supplierId': supplierId,
                'totalPurchases': 1,
                'totalQuantity': (data['quantityPurchased'] ?? 0).toDouble(),
                'totalSpent': (data['quantityPurchased'] ?? 0).toDouble() * 
                             (data['purchasePricePerKg'] ?? 0).toDouble(),
                'lastPurchase': (data['purchaseDate'] as Timestamp?)?.toDate(),
                'batches': [data['batchNumber']],
              };
            } else {
              supplierMap[supplierId]!['totalPurchases']++;
              supplierMap[supplierId]!['totalQuantity'] += 
                  (data['quantityPurchased'] ?? 0).toDouble();
              supplierMap[supplierId]!['totalSpent'] += 
                  (data['quantityPurchased'] ?? 0).toDouble() * 
                  (data['purchasePricePerKg'] ?? 0).toDouble();
              
              final currentLast = supplierMap[supplierId]!['lastPurchase'] as DateTime?;
              final newDate = (data['purchaseDate'] as Timestamp?)?.toDate();
              if (newDate != null && (currentLast == null || newDate.isAfter(currentLast))) {
                supplierMap[supplierId]!['lastPurchase'] = newDate;
              }
              
              (supplierMap[supplierId]!['batches'] as List).add(data['batchNumber']);
            }
          }

          final suppliers = supplierMap.values.toList()
            ..sort((a, b) => b['totalPurchases'].compareTo(a['totalPurchases']));

          if (suppliers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No suppliers yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start purchasing from farmers to build your supplier network',
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Supplier Network',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${suppliers.length} active suppliers',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Suppliers List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    return _buildSupplierCard(context, suppliers[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSupplierCard(BuildContext context, Map<String, dynamic> supplier) {
    final totalPurchases = supplier['totalPurchases'] as int;
    final totalQuantity = supplier['totalQuantity'] as double;
    final totalSpent = supplier['totalSpent'] as double;
    final lastPurchase = supplier['lastPurchase'] as DateTime?;
    final avgPrice = totalQuantity > 0 ? totalSpent / totalQuantity : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSupplierDetails(context, supplier),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.agriculture,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier['supplierName'] ?? 'Unknown Supplier',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$totalPurchases purchases',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.star_border),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Favorite feature coming soon!'),
                        ),
                      );
                    },
                    tooltip: 'Add to favorites',
                  ),
                ],
              ),
              const Divider(height: 24),
              
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      Icons.scale,
                      'Total Qty',
                      '${totalQuantity.toStringAsFixed(0)} kg',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      Icons.attach_money,
                      'Total Spent',
                      'RWF ${totalSpent.toStringAsFixed(0)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      Icons.trending_up,
                      'Avg Price',
                      'RWF ${avgPrice.toStringAsFixed(0)}/kg',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      Icons.calendar_today,
                      'Last Purchase',
                      lastPurchase != null
                          ? '${lastPurchase.day}/${lastPurchase.month}/${lastPurchase.year}'
                          : 'N/A',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSupplierDetails(BuildContext context, Map<String, dynamic> supplier) {
    final batches = supplier['batches'] as List;
    final uniqueBatches = batches.toSet().toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.agriculture,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier['supplierName'] ?? 'Supplier Details',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Farmer Cooperative',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              
              _buildDetailRow('Total Purchases', '${supplier['totalPurchases']}'),
              _buildDetailRow(
                'Total Quantity',
                '${(supplier['totalQuantity'] as double).toStringAsFixed(0)} kg',
              ),
              _buildDetailRow(
                'Total Spent',
                'RWF ${(supplier['totalSpent'] as double).toStringAsFixed(0)}',
              ),
              _buildDetailRow(
                'Average Price',
                'RWF ${((supplier['totalSpent'] as double) / (supplier['totalQuantity'] as double)).toStringAsFixed(0)}/kg',
              ),
              if (supplier['lastPurchase'] != null)
                _buildDetailRow(
                  'Last Purchase',
                  '${(supplier['lastPurchase'] as DateTime).day}/${(supplier['lastPurchase'] as DateTime).month}/${(supplier['lastPurchase'] as DateTime).year}',
                ),
              
              const SizedBox(height: 24),
              const Text(
                'Batches Purchased',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: uniqueBatches.map((batch) {
                  return Chip(
                    label: Text(
                      batch.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contact feature coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Contact'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
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
    );
  }
}
