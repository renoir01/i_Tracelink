import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/cooperative_model.dart';
import '../../models/batch_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import 'place_order_screen.dart';

class FindFarmersScreen extends StatefulWidget {
  const FindFarmersScreen({super.key});

  @override
  State<FindFarmersScreen> createState() => _FindFarmersScreenState();
}

class _FindFarmersScreenState extends State<FindFarmersScreen> {
  final _searchController = TextEditingController();
  String? _selectedDistrict;
  double _minQuantity = 0;
  
  final List<String> _rwandaDistricts = [
    'Gasabo', 'Kicukiro', 'Nyarugenge', // Kigali
    'Bugesera', 'Gatsibo', 'Kayonza', 'Kirehe', 'Ngoma', 'Rwamagana', // Eastern
    'Gicumbi', 'Gakenke', 'Musanze', 'Rulindo', 'Burera', // Northern
    'Gisagara', 'Huye', 'Kamonyi', 'Muhanga', 'Nyamagabe', 'Nyanza', 'Nyaruguru', 'Ruhango', // Southern
    'Karongi', 'Ngororero', 'Nyabihu', 'Nyamasheke', 'Rubavu', 'Rusizi', 'Rutsiro', // Western
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Farmers'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search & Filter Cooperatives',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by name',
                    hintText: 'Search cooperative name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                
                // District filter
                DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Districts')),
                    ..._rwandaDistricts.map((district) => DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedDistrict = value);
                  },
                ),
                const SizedBox(height: 16),
                
                // Minimum quantity slider
                Text('Minimum Quantity: ${_minQuantity.round()} kg'),
                Slider(
                  value: _minQuantity,
                  min: 0,
                  max: 5000,
                  divisions: 50,
                  label: '${_minQuantity.round()} kg',
                  onChanged: (value) {
                    setState(() => _minQuantity = value);
                  },
                ),
              ],
            ),
          ),
          
          // Farmers list
          Expanded(
            child: StreamBuilder<List<CooperativeModel>>(
              stream: FirestoreService().getAvailableCooperatives(
                district: _selectedDistrict,
                minQuantity: _minQuantity,
              ),
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

                var cooperatives = snapshot.data ?? [];
                
                // Apply search filter
                if (_searchController.text.isNotEmpty) {
                  final searchLower = _searchController.text.toLowerCase();
                  cooperatives = cooperatives.where((coop) {
                    return coop.cooperativeName.toLowerCase().contains(searchLower);
                  }).toList();
                }

                if (cooperatives.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No cooperatives found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cooperatives.length,
                  itemBuilder: (context, index) {
                    final coop = cooperatives[index];
                    return _CooperativeCard(
                      cooperative: coop,
                      onPlaceOrder: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PlaceOrderScreen(
                              cooperative: coop,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _CooperativeCard extends StatelessWidget{
  final CooperativeModel cooperative;
  final VoidCallback onPlaceOrder;

  const _CooperativeCard({
    required this.cooperative,
    required this.onPlaceOrder,
  });

  Future<List<BatchModel>> _getAvailableBatches() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('batches')
          .where('farmerId', isEqualTo: cooperative.userId)
          .where('availableForSale', isEqualTo: true)
          .where('status', isEqualTo: 'available')
          .limit(5)
          .get();

      return snapshot.docs.map((doc) => BatchModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error loading batches: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final harvestInfo = cooperative.harvestInfo;
    final hasHarvest = harvestInfo != null && harvestInfo.actualQuantity != null;
    final agroDealerPurchase = cooperative.agroDealerPurchase;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showProvenanceDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.groups, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cooperative.cooperativeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${cooperative.location.district}, ${cooperative.location.sector}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (hasHarvest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Available',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(height: 24),

              // Basic Details
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.people,
                      label: 'Members',
                      value: '${cooperative.numberOfMembers}',
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.scale,
                      label: 'Available',
                      value: hasHarvest
                          ? '${harvestInfo.actualQuantity!.round()} kg'
                          : 'N/A',
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.attach_money,
                      label: 'Price',
                      value: cooperative.pricePerKg != null
                          ? '${cooperative.pricePerKg!.round()} RWF/kg'
                          : 'N/A',
                    ),
                  ),
                ],
              ),

              // Seed Source Information (if available)
              if (agroDealerPurchase != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.eco, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'Seed Source',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dealer: ${agroDealerPurchase.dealerName}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Batch: ${agroDealerPurchase.seedBatch}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Purchase: ${DateFormat('MMM dd, yyyy').format(agroDealerPurchase.purchaseDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],

              // Batch preview with FutureBuilder
              FutureBuilder<List<BatchModel>>(
                future: _getAvailableBatches(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  final batches = snapshot.data ?? [];
                  if (batches.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Available Batches (${batches.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...batches.take(2).map((batch) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getQualityColor(batch.quality).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                batch.quality.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getQualityColor(batch.quality),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              batch.beanVariety,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const Spacer(),
                            Icon(Icons.science, size: 12, color: Colors.orange.shade700),
                            const SizedBox(width: 2),
                            Text(
                              '${batch.ironContent.toStringAsFixed(0)}mg',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (batches.length > 2)
                        Text(
                          '+${batches.length - 2} more batches',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showProvenanceDetails(context),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onPlaceOrder,
                      icon: const Icon(Icons.shopping_cart, size: 18),
                      label: const Text('Place Order'),
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

  Color _getQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'a':
        return Colors.green;
      case 'b':
        return Colors.orange;
      case 'c':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showProvenanceDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => FutureBuilder<List<BatchModel>>(
          future: _getAvailableBatches(),
          builder: (context, snapshot) {
            final batches = snapshot.data ?? [];
            final agroDealerPurchase = cooperative.agroDealerPurchase;
            final harvestInfo = cooperative.harvestInfo;

            return SingleChildScrollView(
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
                    Text(
                      cooperative.cooperativeName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${cooperative.location.district}, ${cooperative.location.sector}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Seed Source Section
                    if (agroDealerPurchase != null) ...[
                      _buildSectionTitle('Seed Source & Origin', Icons.eco),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _buildDetailRow('Agro-Dealer', agroDealerPurchase.dealerName),
                        _buildDetailRow('Seed Batch', agroDealerPurchase.seedBatch),
                        _buildDetailRow('Quantity', '${agroDealerPurchase.quantity} kg'),
                        _buildDetailRow('Purchase Date', DateFormat('MMM dd, yyyy').format(agroDealerPurchase.purchaseDate)),
                      ]),
                      const SizedBox(height: 20),
                    ],

                    // Harvest Information
                    if (harvestInfo != null) ...[
                      _buildSectionTitle('Harvest Information', Icons.agriculture),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        if (harvestInfo.harvestDate != null)
                          _buildDetailRow('Harvest Date', DateFormat('MMM dd, yyyy').format(harvestInfo.harvestDate!)),
                        _buildDetailRow('Expected Quantity', '${harvestInfo.expectedQuantity} kg'),
                        if (harvestInfo.actualQuantity != null)
                          _buildDetailRow('Actual Quantity', '${harvestInfo.actualQuantity} kg'),
                        if (harvestInfo.storageLocation != null)
                          _buildDetailRow('Storage', harvestInfo.storageLocation!),
                      ]),
                      const SizedBox(height: 20),
                    ],

                    // Available Batches
                    if (batches.isNotEmpty) ...[
                      _buildSectionTitle('Available Batches', Icons.inventory_2),
                      const SizedBox(height: 12),
                      ...batches.map((batch) => _buildBatchCard(batch)),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onPlaceOrder();
                        },
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Place Order'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
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

  Widget _buildBatchCard(BatchModel batch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getQualityColor(batch.quality).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Grade ${batch.quality.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getQualityColor(batch.quality),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                batch.beanVariety,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${batch.quantity} kg',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.qr_code, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                batch.batchNumber,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const Spacer(),
              Icon(Icons.science, size: 14, color: Colors.orange.shade700),
              const SizedBox(width: 4),
              Text(
                '${batch.ironContent.toStringAsFixed(0)}mg Fe/100g',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
              ),
            ],
          ),
          if (batch.harvestDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Harvested: ${DateFormat('MMM dd, yyyy').format(batch.harvestDate!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
          if (batch.seedSource != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.eco, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Seed: ${batch.seedSource}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
