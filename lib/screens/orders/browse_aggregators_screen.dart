import 'package:flutter/material.dart';
import '../../models/aggregator_model.dart';
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onPlaceOrder,
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
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onPlaceOrder,
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Place Order'),
                ),
              ),
            ],
          ),
        ),
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
