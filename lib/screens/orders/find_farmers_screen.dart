import 'package:flutter/material.dart';
import '../../models/cooperative_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final harvestInfo = cooperative.harvestInfo;
    final hasHarvest = harvestInfo != null && harvestInfo.actualQuantity != null;

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
              
              // Details
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
