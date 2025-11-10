import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/aggregator_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart';
import '../../utils/app_theme.dart';

class RequestPurchaseScreen extends StatefulWidget {
  const RequestPurchaseScreen({super.key});

  @override
  State<RequestPurchaseScreen> createState() => _RequestPurchaseScreenState();
}

class _RequestPurchaseScreenState extends State<RequestPurchaseScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<AggregatorModel> _aggregators = [];
  List<AggregatorModel> _filteredAggregators = [];

  @override
  void initState() {
    super.initState();
    _loadAggregators();
  }

  Future<void> _loadAggregators() async {
    setState(() => _isLoading = true);
    try {
      final aggregators = await FirestoreService().getAllAggregatorsOnce();
      setState(() {
        _aggregators = aggregators;
        _filteredAggregators = aggregators;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sellers: $e')),
        );
      }
    }
  }

  void _filterAggregators(String query) {
    setState(() {
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
    });
  }

  void _showPurchaseRequestDialog(AggregatorModel aggregator) {
    showDialog(
      context: context,
      builder: (context) => _PurchaseRequestDialog(aggregator: aggregator),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Purchase'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Sellers',
                hintText: 'Search by name or location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterAggregators('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _filterAggregators,
            ),
          ),

          // Info Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select a seller and specify the quantity you want to purchase. They will receive your request via SMS.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Aggregators List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAggregators.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No sellers found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredAggregators.length,
                        itemBuilder: (context, index) {
                          final aggregator = _filteredAggregators[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: const Icon(Icons.store, color: Colors.green),
                              ),
                              title: Text(
                                aggregator.businessName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${aggregator.location.district}, ${aggregator.location.sector}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  if (aggregator.phone.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          aggregator.phone,
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _showPurchaseRequestDialog(aggregator),
                                child: const Text('Request'),
                              ),
                            ),
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

// Purchase Request Dialog
class _PurchaseRequestDialog extends StatefulWidget {
  final AggregatorModel aggregator;

  const _PurchaseRequestDialog({required this.aggregator});

  @override
  State<_PurchaseRequestDialog> createState() => _PurchaseRequestDialogState();
}

class _PurchaseRequestDialogState extends State<_PurchaseRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userModel = authProvider.userModel;
      
      if (userModel == null) {
        throw Exception('User not logged in');
      }

      final quantity = double.parse(_quantityController.text);
      final notes = _notesController.text.isNotEmpty ? _notesController.text : null;

      // Create purchase request record
      await FirebaseFirestore.instance.collection('consumer_purchase_requests').add({
        'consumerId': userModel.id,
        'consumerName': userModel.name,
        'consumerEmail': userModel.email,
        'consumerPhone': userModel.phone,
        'aggregatorId': widget.aggregator.userId,
        'aggregatorName': widget.aggregator.businessName,
        'quantityRequested': quantity,
        'notes': notes,
        'requestDate': Timestamp.now(),
        'status': 'pending',
      });

      // Send SMS to aggregator
      if (widget.aggregator.phone.isNotEmpty) {
        try {
          await SMSService().sendNotification(
            phoneNumber: widget.aggregator.phone,
            title: 'New Purchase Request',
            body: '${userModel.name} wants to buy $quantity kg of beans. '
                  'Contact: ${userModel.phone}. ${notes != null ? "Note: $notes" : ""}',
          );
          debugPrint('✅ SMS sent to aggregator: ${widget.aggregator.phone}');
        } catch (smsError) {
          debugPrint('⚠️ SMS failed: $smsError');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent to ${widget.aggregator.businessName}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
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
                // Header
                Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Purchase Request',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.aggregator.businessName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Quantity Field
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity (kg) *',
                    hintText: 'How many kg do you want?',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.scale),
                    suffixText: 'kg',
                  ),
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

                // Notes Field
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    hintText: 'Any special requirements or preferences...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 16),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'The seller will receive your request via SMS and can contact you to arrange purchase.',
                          style: TextStyle(fontSize: 12),
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
                        onPressed: _isSending ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendRequest,
                        icon: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isSending ? 'Sending...' : 'Send Request'),
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

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
