import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/agro_dealer_sale_model.dart';
import '../../models/agro_dealer_model.dart';
import '../../utils/app_theme.dart';

class SeedPurchaseHistoryScreen extends StatefulWidget {
  const SeedPurchaseHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SeedPurchaseHistoryScreen> createState() => _SeedPurchaseHistoryScreenState();
}

class _SeedPurchaseHistoryScreenState extends State<SeedPurchaseHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _cooperativeId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCooperativeId();
  }

  Future<void> _loadCooperativeId() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final coopDoc = await _firestore
            .collection('cooperatives')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (coopDoc.docs.isNotEmpty) {
          setState(() {
            _cooperativeId = coopDoc.docs.first.id;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<AgroDealerModel?> _getAgroDealerDetails(String dealerId) async {
    try {
      final doc = await _firestore.collection('agro_dealers').doc(dealerId).get();
      if (doc.exists) {
        return AgroDealerModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error loading agro-dealer: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Purchase History'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cooperativeId == null
              ? const Center(child: Text('Cooperative not found'))
              : StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('agro_dealer_sales')
                      .where('customerId', isEqualTo: _cooperativeId)
                      .orderBy('saleDate', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final purchases = snapshot.data?.docs ?? [];

                    if (purchases.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No seed purchases found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your seed purchase history will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: purchases.length,
                      itemBuilder: (context, index) {
                        final sale = AgroDealerSaleModel.fromFirestore(
                            purchases[index]);
                        return _buildPurchaseCard(sale);
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildPurchaseCard(AgroDealerSaleModel sale) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPurchaseDetails(sale),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy').format(sale.saleDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sale.paymentStatus == 'completed'
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sale.paymentStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: sale.paymentStatus == 'completed'
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Seed variety
              Text(
                sale.seedVariety,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Agro-dealer info
              FutureBuilder<AgroDealerModel?>(
                future: _getAgroDealerDetails(sale.agroDealerId),
                builder: (context, dealerSnapshot) {
                  final dealerName = dealerSnapshot.data?.businessName ??
                      'Loading...';
                  return Row(
                    children: [
                      Icon(Icons.store, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dealerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // Quantity and batch info
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.scale,
                    label: '${sale.quantity.toStringAsFixed(1)} kg',
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  if (sale.batchNumber != null)
                    _buildInfoChip(
                      icon: Icons.qr_code,
                      label: sale.batchNumber!,
                      color: Colors.blue,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Quality indicators
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQualityBadge(
                    label: sale.quality,
                    icon: Icons.verified,
                    color: Colors.green,
                  ),
                  _buildQualityBadge(
                    label: '${sale.ironContent.toStringAsFixed(0)}mg Fe/100g',
                    icon: Icons.science,
                    color: Colors.orange,
                  ),
                  if (sale.certificationNumber != null)
                    _buildQualityBadge(
                      label: 'Certified',
                      icon: Icons.certificate,
                      color: Colors.purple,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RWF ${sale.pricePerKg.toStringAsFixed(0)}/kg',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Total: RWF ${sale.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityBadge({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDetails(AgroDealerSaleModel sale) {
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                const Text(
                  'Purchase Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Details
                _buildDetailRow('Seed Variety', sale.seedVariety),
                _buildDetailRow('Quantity', '${sale.quantity} kg'),
                _buildDetailRow('Price per kg',
                    'RWF ${sale.pricePerKg.toStringAsFixed(0)}'),
                _buildDetailRow('Total Amount',
                    'RWF ${sale.totalAmount.toStringAsFixed(0)}'),
                _buildDetailRow('Purchase Date',
                    DateFormat('MMM dd, yyyy').format(sale.saleDate)),
                _buildDetailRow('Payment Status', sale.paymentStatus),
                if (sale.paymentMethod != null)
                  _buildDetailRow('Payment Method', sale.paymentMethod!),
                if (sale.batchNumber != null)
                  _buildDetailRow('Batch Number', sale.batchNumber!),
                if (sale.certificationNumber != null)
                  _buildDetailRow(
                      'Certification Number', sale.certificationNumber!),
                _buildDetailRow('Quality Grade', sale.quality),
                _buildDetailRow('Iron Content',
                    '${sale.ironContent.toStringAsFixed(1)}mg/100g'),
                if (sale.receiptNumber != null)
                  _buildDetailRow('Receipt Number', sale.receiptNumber!),
                if (sale.notes != null && sale.notes!.isNotEmpty)
                  _buildDetailRow('Notes', sale.notes!),

                const SizedBox(height: 20),

                // Agro-dealer info
                FutureBuilder<AgroDealerModel?>(
                  future: _getAgroDealerDetails(sale.agroDealerId),
                  builder: (context, dealerSnapshot) {
                    if (!dealerSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final dealer = dealerSnapshot.data!;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.store,
                                  color: AppTheme.primaryColor),
                              SizedBox(width: 8),
                              Text(
                                'Agro-Dealer Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildDetailRow('Business Name', dealer.businessName),
                          _buildDetailRow('Contact Person', dealer.contactPerson),
                          _buildDetailRow('Phone', dealer.phone),
                          _buildDetailRow('License Number', dealer.licenseNumber),
                          if (dealer.location != null)
                            _buildDetailRow(
                              'Location',
                              '${dealer.location!.district}, ${dealer.location!.sector}',
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
