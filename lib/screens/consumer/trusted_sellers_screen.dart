import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class TrustedSellersScreen extends StatelessWidget {
  const TrustedSellersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Sellers'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.consumerPurchasesCollection)
            .where('consumerId', isEqualTo: userId)
            .where('wasVerified', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final purchases = snapshot.data?.docs ?? [];

          // Group by seller
          final sellerMap = <String, Map<String, dynamic>>{};
          for (var doc in purchases) {
            final data = doc.data() as Map<String, dynamic>;
            final sellerId = data['sellerId'] ?? '';
            
            if (!sellerMap.containsKey(sellerId)) {
              sellerMap[sellerId] = {
                'sellerName': data['sellerName'],
                'sellerType': data['sellerType'],
                'sellerId': sellerId,
                'purchases': 1,
                'ratings': data['rating'] != null ? [data['rating']] : [],
                'lastPurchase': (data['scanDate'] as Timestamp?)?.toDate(),
              };
            } else {
              sellerMap[sellerId]!['purchases']++;
              if (data['rating'] != null) {
                (sellerMap[sellerId]!['ratings'] as List).add(data['rating']);
              }
              final currentLast = sellerMap[sellerId]!['lastPurchase'] as DateTime?;
              final newDate = (data['scanDate'] as Timestamp?)?.toDate();
              if (newDate != null && (currentLast == null || newDate.isAfter(currentLast))) {
                sellerMap[sellerId]!['lastPurchase'] = newDate;
              }
            }
          }

          final sellers = sellerMap.values.toList()
            ..sort((a, b) => b['purchases'].compareTo(a['purchases']));

          if (sellers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No trusted sellers yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start scanning products from verified sellers',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These sellers have been verified through your purchases',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sellers List
              ...sellers.map((seller) => _buildSellerCard(context, seller)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSellerCard(BuildContext context, Map<String, dynamic> seller) {
    final ratings = seller['ratings'] as List;
    final avgRating = ratings.isNotEmpty
        ? ratings.reduce((a, b) => a + b) / ratings.length
        : 0.0;
    final lastPurchase = seller['lastPurchase'] as DateTime?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Seller Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    seller['sellerType'] == 'farmer' 
                        ? Icons.agriculture 
                        : Icons.store,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),

                // Seller Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller['sellerName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  seller['sellerType']?.toString().toUpperCase() ?? 'TRADER',
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

                // Favorite Button
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Favorite feature coming soon!')),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 24),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.shopping_bag,
                    '${seller['purchases']} Purchases',
                  ),
                ),
                if (ratings.isNotEmpty)
                  Expanded(
                    child: _buildStatItem(
                      Icons.star,
                      '${avgRating.toStringAsFixed(1)} Rating',
                    ),
                  ),
              ],
            ),
            if (lastPurchase != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last purchase: ${lastPurchase.day}/${lastPurchase.month}/${lastPurchase.year}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showSellerDetails(context, seller);
                    },
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Details', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact feature coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Contact', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showSellerDetails(BuildContext context, Map<String, dynamic> seller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(
              seller['sellerName'] ?? 'Seller Details',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Type', seller['sellerType']?.toString().toUpperCase() ?? 'TRADER'),
            _buildDetailRow('Total Purchases', '${seller['purchases']}'),
            if ((seller['ratings'] as List).isNotEmpty)
              _buildDetailRow(
                'Average Rating',
                '${((seller['ratings'] as List).reduce((a, b) => a + b) / (seller['ratings'] as List).length).toStringAsFixed(1)} ⭐',
              ),
            if (seller['lastPurchase'] != null)
              _buildDetailRow(
                'Last Purchase',
                '${(seller['lastPurchase'] as DateTime).day}/${(seller['lastPurchase'] as DateTime).month}/${(seller['lastPurchase'] as DateTime).year}',
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
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
