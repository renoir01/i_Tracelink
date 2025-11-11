import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/aggregator_model.dart';
import '../../models/order_model.dart';
import '../../models/cooperative_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import 'place_institution_order_screen.dart';

class BrowseAggregatorsScreen extends StatefulWidget {
  const BrowseAggregatorsScreen({super.key});

  @override
  State<BrowseAggregatorsScreen> createState() => _BrowseAggregatorsScreenState();
}

class _BrowseAggregatorsScreenState extends State<BrowseAggregatorsScreen> {
  final _searchController = TextEditingController();
  String? _selectedDistrict;
  
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
        title: const Text('Browse Aggregators'),
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
                  'Search & Filter Aggregators',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by name',
                    hintText: 'Search business name...',
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
                    labelText: 'Service Area',
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
              ],
            ),
          ),
          
          // Aggregators list
          Expanded(
            child: StreamBuilder<List<AggregatorModel>>(
              stream: FirestoreService().getAllAggregators(),
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

                var aggregators = snapshot.data ?? [];

                // Apply search filter
                if (_searchController.text.isNotEmpty) {
                  final searchLower = _searchController.text.toLowerCase();
                  aggregators = aggregators.where((agg) {
                    return agg.businessName.toLowerCase().contains(searchLower);
                  }).toList();
                }

                // Filter by district if selected
                if (_selectedDistrict != null) {
                  aggregators = aggregators.where((agg) => 
                    agg.serviceAreas.contains(_selectedDistrict)
                  ).toList();
                }

                if (aggregators.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No aggregators found',
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
                  itemCount: aggregators.length,
                  itemBuilder: (context, index) {
                    final aggregator = aggregators[index];
                    return _AggregatorCard(
                      aggregator: aggregator,
                      onPlaceOrder: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PlaceInstitutionOrderScreen(
                              aggregator: aggregator,
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

class _AggregatorCard extends StatelessWidget {
  final AggregatorModel aggregator;
  final VoidCallback onPlaceOrder;

  const _AggregatorCard({
    required this.aggregator,
    required this.onPlaceOrder,
  });

  Future<Map<String, dynamic>> _getSupplyChainInfo() async {
    try {
      // Get recent orders from this aggregator to farmers
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: aggregator.userId)
          .where('orderType', isEqualTo: 'aggregator_to_farmer')
          .where('status', whereIn: ['accepted', 'delivered'])
          .orderBy('orderDate', descending: true)
          .limit(5)
          .get();

      final orders = ordersSnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      // Get unique farmer IDs
      final farmerIds = orders.map((o) => o.sellerId).toSet().toList();

      // Get farmer cooperative details
      final farmers = <CooperativeModel>[];
      for (var farmerId in farmerIds.take(3)) {
        try {
          final coopDoc = await FirebaseFirestore.instance
              .collection('cooperatives')
              .where('userId', isEqualTo: farmerId)
              .limit(1)
              .get();

          if (coopDoc.docs.isNotEmpty) {
            farmers.add(CooperativeModel.fromFirestore(coopDoc.docs.first));
          }
        } catch (e) {
          debugPrint('Error loading farmer: $e');
        }
      }

      double totalQuantity = orders.fold(0, (sum, order) => sum + order.quantity);

      return {
        'orders': orders,
        'farmers': farmers,
        'totalQuantity': totalQuantity,
        'farmerCount': farmerIds.length,
      };
    } catch (e) {
      debugPrint('Error loading supply chain info: $e');
      return {
        'orders': <OrderModel>[],
        'farmers': <CooperativeModel>[],
        'totalQuantity': 0.0,
        'farmerCount': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showSupplyChainDetails(context),
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
                    child: const Icon(Icons.local_shipping, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aggregator.businessName,
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
                              '${aggregator.location.district}, ${aggregator.location.sector}',
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Active',
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

              // Details
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.map,
                      label: 'Service Areas',
                      value: '${aggregator.serviceAreas.length} districts',
                    ),
                  ),
                  if (aggregator.storageInfo != null)
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.warehouse,
                        label: 'Storage',
                        value: '${aggregator.storageInfo!.capacityInTons.round()} tons',
                      ),
                    ),
                  if (aggregator.transportInfo != null)
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.local_shipping,
                        label: 'Transport',
                        value: '${aggregator.transportInfo!.numberOfVehicles} vehicles',
                      ),
                    ),
                ],
              ),

              // Supply Chain Preview
              FutureBuilder<Map<String, dynamic>>(
                future: _getSupplyChainInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final data = snapshot.data!;
                  final farmers = data['farmers'] as List<CooperativeModel>;
                  final farmerCount = data['farmerCount'] as int;

                  if (farmers.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.agriculture, size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'Farmer Suppliers ($farmerCount cooperatives)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...farmers.take(2).map((farmer) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.groups, size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${farmer.cooperativeName} - ${farmer.location.district}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            if (farmers.length > 2)
                              Text(
                                '+${farmers.length - 2} more suppliers',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Service areas chips
              if (aggregator.serviceAreas.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: aggregator.serviceAreas.take(5).map((area) {
                    return Chip(
                      label: Text(area),
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: const TextStyle(fontSize: 11),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                if (aggregator.serviceAreas.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${aggregator.serviceAreas.length - 5} more',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSupplyChainDetails(context),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Supply Chain'),
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

  void _showSupplyChainDetails(BuildContext context) {
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
        builder: (context, scrollController) => FutureBuilder<Map<String, dynamic>>(
          future: _getSupplyChainInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data ?? {};
            final farmers = data['farmers'] as List<CooperativeModel>? ?? [];
            final orders = data['orders'] as List<OrderModel>? ?? [];
            final totalQuantity = data['totalQuantity'] as double? ?? 0.0;
            final farmerCount = data['farmerCount'] as int? ?? 0;

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
                      aggregator.businessName,
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
                          '${aggregator.location.district}, ${aggregator.location.sector}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Supply Chain Overview
                    _buildSectionTitle('Supply Chain Overview', Icons.link),
                    const SizedBox(height: 12),
                    _buildInfoCard([
                      _buildDetailRow('Total Suppliers', '$farmerCount cooperatives'),
                      _buildDetailRow('Recent Volume', '${totalQuantity.toStringAsFixed(0)} kg'),
                      _buildDetailRow('Active Orders', '${orders.length}'),
                    ]),
                    const SizedBox(height: 20),

                    // Farmer Suppliers
                    if (farmers.isNotEmpty) ...[
                      _buildSectionTitle('Farmer Suppliers', Icons.agriculture),
                      const SizedBox(height: 12),
                      ...farmers.map((farmer) => _buildFarmerCard(farmer)),
                      const SizedBox(height: 20),
                    ],

                    // Recent Orders
                    if (orders.isNotEmpty) ...[
                      _buildSectionTitle('Recent Orders', Icons.receipt_long),
                      const SizedBox(height: 12),
                      ...orders.take(3).map((order) => _buildOrderCard(order)),
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

  Widget _buildFarmerCard(CooperativeModel farmer) {
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
              const Icon(Icons.groups, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  farmer.cooperativeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${farmer.location.district}, ${farmer.location.sector}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.people, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${farmer.numberOfMembers} members',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
          if (farmer.agroDealerPurchase != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.eco, size: 12, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Seed Source',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dealer: ${farmer.agroDealerPurchase!.dealerName}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    'Batch: ${farmer.agroDealerPurchase!.seedBatch}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(order.orderDate),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(order.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.scale, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${order.quantity} kg',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const Spacer(),
              Text(
                'RWF ${order.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'accepted':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
