import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart';
import '../../models/cooperative_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class AgroDealerSalesScreen extends StatelessWidget {
  const AgroDealerSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Sales'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => _showRecordSaleDialog(context, userId),
            tooltip: 'Record Sale',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('agro_dealer_sales')
            .where('agroDealerId', isEqualTo: userId)
            .orderBy('saleDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sales = snapshot.data?.docs ?? [];

          if (sales.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.point_of_sale, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No sales recorded yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to record your first sale',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Calculate stats
          double totalRevenue = 0;
          double totalQuantity = 0;

          for (var doc in sales) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['paymentStatus'] == 'completed') {
              totalRevenue += (data['totalAmount'] ?? 0).toDouble();
            }
            totalQuantity += (data['quantity'] ?? 0).toDouble();
          }

          return Column(
            children: [
              // Stats Summary
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.green.shade50,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Sales',
                        '${sales.length}',
                        Icons.receipt,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Revenue',
                        'RWF ${totalRevenue.toStringAsFixed(0)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Quantity',
                        '${totalQuantity.toStringAsFixed(0)} kg',
                        Icons.scale,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              // Sales List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    return _buildSaleCard(context, sales[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordSaleDialog(context, userId),
        icon: const Icon(Icons.add),
        label: const Text('Record Sale'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['saleDate'] as Timestamp?)?.toDate();
    final paymentStatus = data['paymentStatus'] ?? 'pending';
    final amount = (data['totalAmount'] ?? 0).toDouble();
    final quantity = (data['quantity'] ?? 0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: paymentStatus == 'completed'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    paymentStatus == 'completed'
                        ? Icons.check_circle
                        : Icons.pending,
                    color: paymentStatus == 'completed'
                        ? Colors.green
                        : Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['customerName'] ?? 'Customer',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (date != null)
                        Text(
                          '${date.day}/${date.month}/${date.year}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RWF ${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: paymentStatus == 'completed'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    Text(
                      '$quantity kg',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.eco, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data['seedVariety'] ?? 'Seed',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: paymentStatus == 'completed'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    paymentStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: paymentStatus == 'completed'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordSaleDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => _RecordSaleDialog(agroDealerId: userId),
    );
  }
}

class _RecordSaleDialog extends StatefulWidget {
  final String agroDealerId;

  const _RecordSaleDialog({required this.agroDealerId});

  @override
  State<_RecordSaleDialog> createState() => _RecordSaleDialogState();
}

class _RecordSaleDialogState extends State<_RecordSaleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedVariety = AppConstants.ironBeanVarieties[0];
  String _paymentStatus = 'completed';
  bool _isSubmitting = false;
  bool _isLoadingCustomers = false;
  List<CooperativeModel> _cooperatives = [];
  List<CooperativeModel> _filteredCooperatives = [];
  CooperativeModel? _selectedCooperative;

  @override
  void initState() {
    super.initState();
    _loadCooperatives();
  }

  Future<void> _loadCooperatives() async {
    setState(() => _isLoadingCustomers = true);
    try {
      final cooperatives = await FirestoreService().getAllCooperativesOnce();
      setState(() {
        _cooperatives = cooperatives;
        _filteredCooperatives = cooperatives;
        _isLoadingCustomers = false;
      });
    } catch (e) {
      setState(() => _isLoadingCustomers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading farmers: $e')),
        );
      }
    }
  }

  void _filterCooperatives(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCooperatives = _cooperatives;
      } else {
        _filteredCooperatives = _cooperatives.where((coop) {
          final nameLower = coop.cooperativeName.toLowerCase();
          final districtLower = coop.location.district.toLowerCase();
          final sectorLower = coop.location.sector.toLowerCase();
          final queryLower = query.toLowerCase();
          
          return nameLower.contains(queryLower) ||
                 districtLower.contains(queryLower) ||
                 sectorLower.contains(queryLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record Seed Sale',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),

                // Seed Variety
                DropdownButtonFormField<String>(
                  value: _selectedVariety,
                  decoration: const InputDecoration(
                    labelText: 'Seed Variety',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.eco),
                  ),
                  items: AppConstants.ironBeanVarieties.map((variety) {
                    return DropdownMenuItem(
                      value: variety,
                      child: Text(variety),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedVariety = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Search Farmer/Cooperative
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Farmer/Cooperative',
                    hintText: 'Search by name or location...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterCooperatives('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _filterCooperatives,
                ),
                const SizedBox(height: 12),

                // Selected Cooperative Display
                if (_selectedCooperative != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCooperative!.cooperativeName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_selectedCooperative!.location.district}, ${_selectedCooperative!.location.sector}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => setState(() => _selectedCooperative = null),
                        ),
                      ],
                    ),
                  ),
                
                // Filtered Results List
                if (_searchController.text.isNotEmpty && _selectedCooperative == null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isLoadingCustomers
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredCooperatives.isEmpty
                            ? Center(
                                child: Text(
                                  'No farmers found',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredCooperatives.length,
                                itemBuilder: (context, index) {
                                  final coop = _filteredCooperatives[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green.shade100,
                                      child: const Icon(Icons.agriculture, color: Colors.green),
                                    ),
                                    title: Text(coop.cooperativeName),
                                    subtitle: Text(
                                      '${coop.location.district}, ${coop.location.sector}',
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () {
                                      setState(() {
                                        _selectedCooperative = coop;
                                        _searchController.clear();
                                      });
                                    },
                                  );
                                },
                              ),
                  ),
                const SizedBox(height: 16),

                // Quantity
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity (kg)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.scale),
                    suffixText: 'kg',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    final qty = double.tryParse(value);
                    if (qty == null || qty <= 0) {
                      return 'Enter valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Price per kg
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price per kg (RWF)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                    suffixText: 'RWF',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Enter valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Payment Status
                DropdownButtonFormField<String>(
                  value: _paymentStatus,
                  decoration: const InputDecoration(
                    labelText: 'Payment Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  ],
                  onChanged: (value) {
                    setState(() => _paymentStatus = value!);
                  },
                ),
                const SizedBox(height: 24),

                // Total Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'RWF ${_calculateTotal()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitSale,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Record'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _calculateTotal() {
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return (qty * price).toStringAsFixed(0);
  }

  Future<void> _submitSale() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCooperative == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a farmer/cooperative')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final quantity = double.parse(_quantityController.text);
      final pricePerKg = double.parse(_priceController.text);
      final totalAmount = quantity * pricePerKg;
      final cooperative = _selectedCooperative!;

      // 1. Record the sale
      await FirebaseFirestore.instance.collection('agro_dealer_sales').add({
        'agroDealerId': widget.agroDealerId,
        'seedVariety': _selectedVariety,
        'quantity': quantity,
        'pricePerKg': pricePerKg,
        'totalAmount': totalAmount,
        'customerId': cooperative.userId,
        'customerName': cooperative.cooperativeName,
        'customerType': 'cooperative',
        'saleDate': Timestamp.now(),
        'paymentStatus': _paymentStatus,
        'paymentMethod': 'cash',
      });

      // 2. Reduce dealer's inventory
      await _reduceAgroDealerInventory(
        dealerUserId: widget.agroDealerId,
        seedVariety: _selectedVariety,
        quantity: quantity,
      );

      // 3. Add to farmer's purchase history
      await _recordFarmerPurchase(
        farmerId: cooperative.userId,
        agroDealerId: widget.agroDealerId,
        seedVariety: _selectedVariety,
        quantity: quantity,
        pricePerKg: pricePerKg,
        totalAmount: totalAmount,
      );

      // 4. Send SMS to farmer
      if (cooperative.phone.isNotEmpty) {
        try {
          await SMSService().sendNotification(
            phoneNumber: cooperative.phone,
            title: 'Seed Purchase Recorded',
            body: 'You purchased $quantity kg of $_selectedVariety seeds '
                  'for ${totalAmount.toStringAsFixed(0)} RWF. '
                  'Check iTraceLink app for details.',
          );
          debugPrint('✅ SMS sent to farmer: ${cooperative.phone}');
        } catch (smsError) {
          debugPrint('⚠️ SMS failed: $smsError');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sale recorded! ${cooperative.cooperativeName}\'s purchase history updated.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording sale: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _reduceAgroDealerInventory({
    required String dealerUserId,
    required String seedVariety,
    required double quantity,
  }) async {
    final inventory = await FirebaseFirestore.instance
        .collection('agro_dealer_inventory')
        .where('agroDealerId', isEqualTo: dealerUserId)
        .where('seedVariety', isEqualTo: seedVariety)
        .get();

    if (inventory.docs.isNotEmpty) {
      final doc = inventory.docs.first;
      final currentQuantity = (doc.data()['quantity'] ?? 0).toDouble();
      final newQuantity = currentQuantity - quantity;

      if (newQuantity < 0) {
        throw Exception('Insufficient inventory! Only ${currentQuantity}kg available.');
      }

      await doc.reference.update({
        'quantity': newQuantity,
        'lastUpdated': Timestamp.now(),
        'status': newQuantity == 0 ? 'out_of_stock' : 'in_stock',
      });
    } else {
      throw Exception('Seed variety not found in inventory');
    }
  }

  Future<void> _recordFarmerPurchase({
    required String farmerId,
    required String agroDealerId,
    required String seedVariety,
    required double quantity,
    required double pricePerKg,
    required double totalAmount,
  }) async {
    await FirebaseFirestore.instance.collection('farmer_purchases').add({
      'farmerId': farmerId,
      'agroDealerId': agroDealerId,
      'seedVariety': seedVariety,
      'quantity': quantity,
      'pricePerKg': pricePerKg,
      'totalAmount': totalAmount,
      'purchaseDate': Timestamp.now(),
      'paymentStatus': _paymentStatus,
      'source': 'agro_dealer_sale',
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
