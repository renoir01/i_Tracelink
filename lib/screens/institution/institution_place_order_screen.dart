import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/aggregator_model.dart';
import '../../models/cooperative_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/sms_service.dart';
import '../../utils/app_theme.dart';

class InstitutionPlaceOrderScreen extends StatefulWidget {
  const InstitutionPlaceOrderScreen({super.key});

  @override
  State<InstitutionPlaceOrderScreen> createState() => _InstitutionPlaceOrderScreenState();
}

class _InstitutionPlaceOrderScreenState extends State<InstitutionPlaceOrderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isLoadingAggregators = false;
  bool _isLoadingFarmers = false;
  List<AggregatorModel> _aggregators = [];
  List<AggregatorModel> _filteredAggregators = [];
  List<CooperativeModel> _farmers = [];
  List<CooperativeModel> _filteredFarmers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAggregators();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 0 && _aggregators.isEmpty) {
      _loadAggregators();
    } else if (_tabController.index == 1 && _farmers.isEmpty) {
      _loadFarmers();
    }
    _searchController.clear();
    setState(() {
      _filteredAggregators = _aggregators;
      _filteredFarmers = _farmers;
    });
  }

  Future<void> _loadAggregators() async {
    setState(() => _isLoadingAggregators = true);
    try {
      final aggregators = await FirestoreService().getAllAggregatorsOnce();
      setState(() {
        _aggregators = aggregators;
        _filteredAggregators = aggregators;
        _isLoadingAggregators = false;
      });
    } catch (e) {
      setState(() => _isLoadingAggregators = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading aggregators: $e')),
        );
      }
    }
  }

  Future<void> _loadFarmers() async {
    setState(() => _isLoadingFarmers = true);
    try {
      final farmers = await FirestoreService().getAllCooperativesOnce();
      setState(() {
        _farmers = farmers;
        _filteredFarmers = farmers;
        _isLoadingFarmers = false;
      });
    } catch (e) {
      setState(() => _isLoadingFarmers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading farmers: $e')),
        );
      }
    }
  }

  void _filterResults(String query) {
    setState(() {
      if (_tabController.index == 0) {
        // Filter aggregators
        if (query.isEmpty) {
          _filteredAggregators = _aggregators;
        } else {
          _filteredAggregators = _aggregators.where((agg) {
            final nameLower = agg.businessName.toLowerCase();
            final districtLower = agg.location.district.toLowerCase();
            final queryLower = query.toLowerCase();
            return nameLower.contains(queryLower) || districtLower.contains(queryLower);
          }).toList();
        }
      } else {
        // Filter farmers
        if (query.isEmpty) {
          _filteredFarmers = _farmers;
        } else {
          _filteredFarmers = _farmers.where((farmer) {
            final nameLower = farmer.cooperativeName.toLowerCase();
            final districtLower = farmer.location.district.toLowerCase();
            final queryLower = query.toLowerCase();
            return nameLower.contains(queryLower) || districtLower.contains(queryLower);
          }).toList();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Order'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aggregators'),
            Tab(text: 'Farmers'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search by name or location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterResults('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _filterResults,
            ),
          ),

          // Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAggregatorsList(),
                _buildFarmersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAggregatorsList() {
    if (_isLoadingAggregators) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredAggregators.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty ? 'No aggregators found' : 'No aggregators available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredAggregators.length,
      itemBuilder: (context, index) {
        final aggregator = _filteredAggregators[index];
        return _buildAggregatorCard(aggregator);
      },
    );
  }

  Widget _buildFarmersList() {
    if (_isLoadingFarmers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredFarmers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty ? 'No farmers found' : 'No farmers available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredFarmers.length,
      itemBuilder: (context, index) {
        final farmer = _filteredFarmers[index];
        return _buildFarmerCard(farmer);
      },
    );
  }

  Widget _buildAggregatorCard(AggregatorModel aggregator) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showOrderDialog(
          sellerId: aggregator.userId,
          sellerName: aggregator.businessName,
          sellerType: 'aggregator',
        ),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
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
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${aggregator.location.district}, ${aggregator.location.sector}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showOrderDialog(
                  sellerId: aggregator.userId,
                  sellerName: aggregator.businessName,
                  sellerType: 'aggregator',
                ),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Place Order'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmerCard(CooperativeModel farmer) {
    final harvestInfo = farmer.harvestInfo;
    final availableQuantity = harvestInfo?.actualQuantity ?? 0.0;
    final pricePerKg = farmer.pricePerKg ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showOrderDialog(
          sellerId: farmer.userId,
          sellerName: farmer.cooperativeName,
          sellerType: 'farmer',
        ),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.agriculture,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmer.cooperativeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${farmer.location.district}, ${farmer.location.sector}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${availableQuantity.toStringAsFixed(0)} kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'RWF ${pricePerKg.toStringAsFixed(0)}/kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showOrderDialog(
                  sellerId: farmer.userId,
                  sellerName: farmer.cooperativeName,
                  sellerType: 'farmer',
                ),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Place Order'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDialog({
    required String sellerId,
    required String sellerName,
    required String sellerType,
  }) {
    showDialog(
      context: context,
      builder: (context) => _OrderDialog(
        sellerId: sellerId,
        sellerName: sellerName,
        sellerType: sellerType,
      ),
    );
  }
}

class _OrderDialog extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String sellerType;

  const _OrderDialog({
    required this.sellerId,
    required this.sellerName,
    required this.sellerType,
  });

  @override
  State<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<_OrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDeliveryDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDeliveryDate = picked);
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.id ?? '';

      final quantity = double.parse(_quantityController.text);
      final pricePerKg = double.parse(_priceController.text);

      final order = OrderModel(
        id: '',
        orderType: 'institution_to_${widget.sellerType}',
        buyerId: userId,
        sellerId: widget.sellerId,
        quantity: quantity,
        pricePerKg: pricePerKg,
        totalAmount: quantity * pricePerKg,
        requestDate: DateTime.now(),
        expectedDeliveryDate: _selectedDeliveryDate,
        status: 'pending',
        paymentStatus: 'pending',
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await FirestoreService().createOrder(order);

      // Notify seller
      try {
        final institution = await FirestoreService().getInstitutionByUserId(userId);
        if (institution != null) {
          await NotificationService().notifyOrderPlaced(
            userId: widget.sellerId,
            aggregatorName: institution.name,
            orderId: order.id,
            quantity: quantity,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Notification error: $e');
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(); // Go back to dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Order from ${widget.sellerName}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per kg (RWF)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expected Delivery Date'),
                subtitle: Text(
                  '${_selectedDeliveryDate.day}/${_selectedDeliveryDate.month}/${_selectedDeliveryDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDeliveryDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitOrder,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Place Order'),
        ),
      ],
    );
  }
}
