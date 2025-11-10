import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class SalesTrackingScreen extends StatelessWidget {
  const SalesTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Tracking'),
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
            .collection(AppConstants.transactionsCollection)
            .where('sellerId', isEqualTo: userId)
            .where('type', isEqualTo: 'sale')
            .orderBy('transactionDate', descending: true)
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
          int completedSales = 0;

          for (var doc in sales) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['paymentStatus'] == 'completed') {
              totalRevenue += (data['totalAmount'] ?? 0).toDouble();
              completedSales++;
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
                fontSize: 14,
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
    final date = (data['transactionDate'] as Timestamp?)?.toDate();
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
                        data['buyerName'] ?? 'Customer',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (date != null)
                        Text(
                          '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
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
                Icon(Icons.inventory_2, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  data['batchNumber'] ?? 'No batch',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const Spacer(),
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
      builder: (context) => _RecordSaleDialog(traderId: userId),
    );
  }
}

class _RecordSaleDialog extends StatefulWidget {
  final String traderId;

  const _RecordSaleDialog({required this.traderId});

  @override
  State<_RecordSaleDialog> createState() => _RecordSaleDialogState();
}

class _RecordSaleDialogState extends State<_RecordSaleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _buyerNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedInventoryId;
  String _paymentStatus = 'completed';
  bool _isSubmitting = false;

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
                  'Record Sale',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),

                // Select Inventory
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('inventory')
                      .where('traderId', isEqualTo: widget.traderId)
                      .where('quantityAvailable', isGreaterThan: 0)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final inventory = snapshot.data?.docs ?? [];

                    if (inventory.isEmpty) {
                      return const Text(
                        'No inventory available for sale',
                        style: TextStyle(color: Colors.red),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedInventoryId,
                      decoration: const InputDecoration(
                        labelText: 'Select Batch',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2),
                      ),
                      items: inventory.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(
                            '${data['batchNumber']} (${data['quantityAvailable']} kg)',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedInventoryId = value);
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a batch';
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Buyer Name
                TextFormField(
                  controller: _buyerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Buyer Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter buyer name';
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

  Future<void> _submitSale() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final quantity = double.parse(_quantityController.text);
      final pricePerKg = double.parse(_priceController.text);
      final totalAmount = quantity * pricePerKg;

      // Get inventory data
      final inventoryDoc = await FirebaseFirestore.instance
          .collection('inventory')
          .doc(_selectedInventoryId)
          .get();

      final inventoryData = inventoryDoc.data() as Map<String, dynamic>;

      // Record transaction
      await FirebaseFirestore.instance
          .collection(AppConstants.transactionsCollection)
          .add({
        'type': 'sale',
        'sellerId': widget.traderId,
        'sellerName': 'Trader',
        'buyerId': '',
        'buyerName': _buyerNameController.text,
        'batchId': inventoryData['batchId'],
        'batchNumber': inventoryData['batchNumber'],
        'quantity': quantity,
        'pricePerKg': pricePerKg,
        'totalAmount': totalAmount,
        'transactionDate': Timestamp.now(),
        'paymentStatus': _paymentStatus,
        'location': {},
        'status': 'completed',
      });

      // Update inventory
      await FirebaseFirestore.instance
          .collection('inventory')
          .doc(_selectedInventoryId)
          .update({
        'quantityAvailable': FieldValue.increment(-quantity),
        'quantitySold': FieldValue.increment(quantity),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale recorded successfully!'),
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

  @override
  void dispose() {
    _buyerNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
