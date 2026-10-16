import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class ProductInformationScreen extends StatelessWidget {
  final String batchId;
  final Map<String, dynamic> batchData;

  const ProductInformationScreen({
    super.key,
    required this.batchId,
    required this.batchData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Information'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final batchNumber = batchData['batchNumber'] ?? batchId;
              final variety = batchData['beanVariety'] ?? batchData['variety'] ?? 'Not specified';
              final status = batchData['status'] ?? 'Not specified';
              Share.share(
                'iTraceLink product information\n'
                'Batch: $batchNumber\n'
                'Variety: $variety\n'
                'Status: $status\n'
                'Traceability ID: $batchId',
                subject: 'iTraceLink product $batchNumber',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verification Badge
            _buildVerificationBadge(context),
            const SizedBox(height: 24),

            // Product Details
            _buildProductDetails(context),
            const SizedBox(height: 16),

            // Iron Content
            _buildIronContentCard(context),
            const SizedBox(height: 16),

            // Supply Chain Journey
            Text(
              'Supply Chain Journey',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildSupplyChain(context),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✓ Verified Product',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Authentic Iron-Biofortified Beans',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            _buildDetailRow('Batch Number', batchData['batchNumber'] ?? 'N/A'),
            _buildDetailRow('Bean Variety', batchData['beanVariety'] ?? 'N/A'),
            _buildDetailRow('Quantity', '${batchData['quantity']} kg'),
            _buildDetailRow('Quality Grade', (batchData['quality'] ?? 'N/A').toString().toUpperCase()),
            _buildDetailRow('Status', _getStatusText(batchData['status'])),
            if (batchData['harvestDate'] != null)
              _buildDetailRow(
                'Harvest Date',
                _formatDate((batchData['harvestDate'] as Timestamp).toDate()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIronContentCard(BuildContext context) {
    final ironContent = batchData['ironContent'] ?? 80.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Iron-Biofortified',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Iron Content: $ironContent mg per 100g',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Helps combat iron deficiency & anemia',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplyChain(BuildContext context) {
    return Column(
      children: [
        // Farmer/Cooperative
        _buildSupplyChainActor(
          'Farmer Cooperative',
          batchData['cooperativeName'] ?? 'Unknown',
          Icons.agriculture,
          Colors.green,
          'Origin',
          true,
        ),
        
        // Agro-Dealer (if seed source available)
        if (batchData['seedSource'] != null)
          _buildSupplyChainActor(
            'Agro-Dealer',
            batchData['seedSource'],
            Icons.store,
            Colors.orange,
            'Certified Seeds Provider',
            true,
          ),

        // Current Location
        _buildSupplyChainActor(
          'Current Status',
          _getStatusText(batchData['status']),
          Icons.location_on,
          Colors.blue,
          batchData['storageLocation'] ?? 'In transit',
          false,
        ),
      ],
    );
  }

  Widget _buildSupplyChainActor(
    String role,
    String name,
    IconData icon,
    Color color,
    String details,
    bool showConnector,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            role,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '✓ Verified',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showConnector)
          Container(
            width: 2,
            height: 30,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _addToTrustedSellers(context),
            icon: const Icon(Icons.favorite),
            label: const Text('Add Seller to Trusted List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Rate product
                  _showRatingDialog(context);
                },
                icon: const Icon(Icons.star),
                label: const Text('Rate'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final phone = batchData['sellerPhone'] ??
                      batchData['phoneNumber'] ??
                      batchData['phone'];
                  if (phone == null || phone.toString().trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Seller contact information is not available.')),
                    );
                    return;
                  }
                  final uri = Uri(scheme: 'tel', path: phone.toString().trim());
                  if (!await launchUrl(uri) && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open the phone dialer.')),
                    );
                  }
                },
                icon: const Icon(Icons.phone),
                label: const Text('Contact'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addToTrustedSellers(BuildContext context) async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userModel?.id;
    final sellerId = (batchData['farmerId'] ??
            batchData['sellerId'] ??
            batchData['producerId'] ??
            '')
        .toString()
        .trim();
    final sellerName = (batchData['cooperativeName'] ??
            batchData['sellerName'] ??
            batchData['farmerName'] ??
            'Verified seller')
        .toString();

    if (userId == null || userId.isEmpty || sellerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller details are not available for this batch.')),
      );
      return;
    }

    final reference = FirebaseFirestore.instance
        .collection('trusted_sellers')
        .doc('${userId}_${sellerId}');
    try {
      final existing = await reference.get();
      if (existing.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This seller is already in your trusted list.')),
          );
        }
        return;
      }
      await reference.set({
        'consumerId': userId,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerType': (batchData['sellerType'] ?? 'farmer').toString(),
        'createdAt': Timestamp.now(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller added to your trusted list.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save trusted seller: $error')),
        );
      }
    }
  }

  void _showRatingDialog(BuildContext context) {
    int rating = 5;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate This Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How would you rate this product?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    rating = index + 1;
                    (context as Element).markNeedsBuild();
                  },
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Rated $rating stars!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'growing':
        return 'Currently Growing';
      case 'harvested':
        return 'Harvested';
      case 'available':
        return 'Available for Sale';
      case 'sold':
        return 'Sold';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
