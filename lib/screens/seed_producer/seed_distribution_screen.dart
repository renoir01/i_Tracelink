import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart';
import '../../models/agro_dealer_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class SeedDistributionScreen extends StatelessWidget {
  const SeedDistributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Distribution'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => _showRecordDistributionDialog(context, userId),
            tooltip: 'Record Distribution',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('seed_distributions')
            .where('seedProducerId', isEqualTo: userId)
            .orderBy('distributionDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final distributions = snapshot.data?.docs ?? [];

          if (distributions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.agriculture, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No distributions yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to record seed distribution',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Calculate stats
          double totalQuantity = 0;
          int recipientCount = distributions.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['recipientId'];
          }).toSet().length;

          for (var doc in distributions) {
            final data = doc.data() as Map<String, dynamic>;
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
                        'Total Distributed',
                        '${totalQuantity.toStringAsFixed(0)} kg',
                        Icons.agriculture,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Recipients',
                        '$recipientCount',
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Distributions',
                        '${distributions.length}',
                        Icons.inventory_2,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              // Distribution List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: distributions.length,
                  itemBuilder: (context, index) {
                    return _buildDistributionCard(context, distributions[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordDistributionDialog(context, userId),
        icon: const Icon(Icons.add),
        label: const Text('Record Distribution'),
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
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

  Widget _buildDistributionCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['distributionDate'] as Timestamp?)?.toDate();
    final quantity = (data['quantity'] ?? 0).toDouble();
    final status = data['status'] ?? 'distributed';

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
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['recipientName'] ?? 'Recipient',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        data['recipientType']?.toString().toUpperCase() ?? 'FARMER',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.eco,
                    'Variety',
                    data['seedVariety'] ?? 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.scale,
                    'Quantity',
                    '${quantity.toStringAsFixed(0)} kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.verified,
                    'Quality',
                    data['quality']?.toString().toUpperCase() ?? 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.calendar_today,
                    'Date',
                    date != null ? '${date.day}/${date.month}/${date.year}' : 'N/A',
                  ),
                ),
              ],
            ),
            if (data['certificationNumber'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.badge, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Cert: ${data['certificationNumber']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'distributed':
        return Colors.blue;
      case 'planted':
        return Colors.orange;
      case 'harvested':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'distributed':
        return Icons.local_shipping;
      case 'planted':
        return Icons.agriculture;
      case 'harvested':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  void _showRecordDistributionDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => _RecordDistributionDialog(seedProducerId: userId),
    );
  }
}

class _RecordDistributionDialog extends StatefulWidget {
  final String seedProducerId;

  const _RecordDistributionDialog({required this.seedProducerId});

  @override
  State<_RecordDistributionDialog> createState() => _RecordDistributionDialogState();
}

class _RecordDistributionDialogState extends State<_RecordDistributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _recipientNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _certificationController = TextEditingController();
  String _selectedVariety = AppConstants.ironBeanVarieties[0];
  String _recipientType = 'agro_dealer';
  String _quality = 'certified';
  bool _isSubmitting = false;
  bool _isLoadingDealers = false;
  List<AgroDealerModel> _agroDealers = [];
  AgroDealerModel? _selectedAgroDealer;

  @override
  void initState() {
    super.initState();
    _loadAgroDealers();
  }

  Future<void> _loadAgroDealers() async {
    setState(() => _isLoadingDealers = true);
    try {
      final dealers = await FirestoreService().getAllAgroDealersOnce();
      setState(() {
        _agroDealers = dealers;
        _isLoadingDealers = false;
      });
    } catch (e) {
      setState(() => _isLoadingDealers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading agro-dealers: $e')),
        );
      }
    }
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
                  'Record Seed Distribution',
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

                // Agro-Dealer Selector
                _isLoadingDealers
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : DropdownButtonFormField<AgroDealerModel>(
                        value: _selectedAgroDealer,
                        decoration: const InputDecoration(
                          labelText: 'Select Agro-Dealer',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.store),
                          helperText: 'Distribution will update dealer\'s inventory',
                        ),
                        items: _agroDealers.map((dealer) {
                          return DropdownMenuItem(
                            value: dealer,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dealer.businessName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${dealer.location.district}, ${dealer.location.sector}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (dealer) {
                          setState(() => _selectedAgroDealer = dealer);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select an agro-dealer';
                          }
                          return null;
                        },
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

                // Quality
                DropdownButtonFormField<String>(
                  value: _quality,
                  decoration: const InputDecoration(
                    labelText: 'Quality',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.star),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'certified', child: Text('Certified')),
                    DropdownMenuItem(value: 'foundation', child: Text('Foundation')),
                    DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                  ],
                  onChanged: (value) {
                    setState(() => _quality = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Certification Number
                TextFormField(
                  controller: _certificationController,
                  decoration: const InputDecoration(
                    labelText: 'Certification Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter certification number';
                    }
                    return null;
                  },
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
                        onPressed: _isSubmitting ? null : _submitDistribution,
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

  Future<void> _submitDistribution() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedAgroDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an agro-dealer')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final quantity = double.parse(_quantityController.text);
      final dealer = _selectedAgroDealer!;

      // 1. Record the distribution
      await FirebaseFirestore.instance
          .collection('seed_distributions')
          .add({
        'seedProducerId': widget.seedProducerId,
        'seedVariety': _selectedVariety,
        'quantity': quantity,
        'recipientId': dealer.userId,
        'recipientName': dealer.businessName,
        'recipientType': 'agro_dealer',
        'distributionDate': Timestamp.now(),
        'distributionMethod': 'direct',
        'certificationNumber': _certificationController.text,
        'ironContent': 80.0,
        'quality': _quality,
        'status': 'distributed',
        'followUpRequired': false,
      });

      // 2. Automatically update Agro-Dealer's inventory
      await _updateAgroDealerInventory(
        dealerUserId: dealer.userId,
        seedVariety: _selectedVariety,
        quantity: quantity,
        certificationNumber: _certificationController.text,
        quality: _quality,
      );

      // 3. Send SMS notification to Agro-Dealer
      if (dealer.phone.isNotEmpty) {
        try {
          await SMSService().sendNotification(
            phoneNumber: dealer.phone,
            title: 'New Seed Stock Received',
            body: 'You received $quantity kg of $_selectedVariety seeds. '
                'Check iTraceLink app to view your updated inventory.',
          );
          debugPrint('✅ SMS sent to agro-dealer: ${dealer.phone}');
        } catch (smsError) {
          debugPrint('⚠️ SMS failed: $smsError');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Distribution recorded! ${dealer.businessName}\'s inventory updated.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording distribution: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateAgroDealerInventory({
    required String dealerUserId,
    required String seedVariety,
    required double quantity,
    required String certificationNumber,
    required String quality,
  }) async {
    // Check if dealer already has this variety in inventory
    final existingInventory = await FirebaseFirestore.instance
        .collection('agro_dealer_inventory')
        .where('agroDealerId', isEqualTo: dealerUserId)
        .where('seedVariety', isEqualTo: seedVariety)
        .get();

    if (existingInventory.docs.isNotEmpty) {
      // Update existing inventory - add to quantity
      final doc = existingInventory.docs.first;
      final currentQuantity = (doc.data()['quantity'] ?? 0).toDouble();
      await doc.reference.update({
        'quantity': currentQuantity + quantity,
        'lastUpdated': Timestamp.now(),
        'certificationNumber': certificationNumber,
        'quality': quality,
      });
    } else {
      // Create new inventory entry
      await FirebaseFirestore.instance
          .collection('agro_dealer_inventory')
          .add({
        'agroDealerId': dealerUserId,
        'seedVariety': seedVariety,
        'quantity': quantity,
        'certificationNumber': certificationNumber,
        'quality': quality,
        'pricePerKg': 1000.0, // Default price, dealer can update
        'dateAdded': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
        'status': 'in_stock',
      });
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _quantityController.dispose();
    _certificationController.dispose();
    super.dispose();
  }
}
