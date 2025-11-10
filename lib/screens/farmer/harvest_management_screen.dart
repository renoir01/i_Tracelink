import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cooperative_model.dart';
import '../../models/aggregator_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/pdf_generator.dart';
import 'update_harvest_screen.dart';
import 'batch_qr_screen.dart';

class HarvestManagementScreen extends StatelessWidget {
  const HarvestManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Harvest Management'),
        centerTitle: true,
      ),
      body: FutureBuilder<CooperativeModel?>(
        future: FirestoreService().getCooperativeByUserId(userId),
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

          final cooperative = snapshot.data;

          if (cooperative == null || cooperative.plantingInfo == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.agriculture, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No planting registered yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Register a planting to track harvest',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            );
          }

          final plantingInfo = cooperative.plantingInfo!;
          final harvestInfo = cooperative.harvestInfo;
          final hasHarvested = harvestInfo?.actualQuantity != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Planting Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.eco, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Current Planting',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          label: 'Planting Date',
                          value: '${plantingInfo.plantingDate.day}/${plantingInfo.plantingDate.month}/${plantingInfo.plantingDate.year}',
                        ),
                        _InfoRow(
                          label: 'Land Area',
                          value: '${plantingInfo.landArea} hectares',
                        ),
                        _InfoRow(
                          label: 'Expected Harvest',
                          value: '${plantingInfo.expectedHarvestDate.day}/${plantingInfo.expectedHarvestDate.month}/${plantingInfo.expectedHarvestDate.year}',
                        ),
                        if (harvestInfo != null)
                          _InfoRow(
                            label: 'Expected Yield',
                            value: '${harvestInfo.expectedQuantity} kg',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Seed Purchase Info
                if (cooperative.agroDealerPurchase != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.store, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                'Seed Source',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            label: 'Agro-Dealer',
                            value: cooperative.agroDealerPurchase!.dealerName,
                          ),
                          _InfoRow(
                            label: 'Batch Number',
                            value: cooperative.agroDealerPurchase!.seedBatch,
                          ),
                          _InfoRow(
                            label: 'Quantity',
                            value: '${cooperative.agroDealerPurchase!.quantity} kg',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Harvest Status Card
                Card(
                  color: hasHarvested ? Colors.green.shade50 : Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasHarvested ? Icons.check_circle : Icons.schedule,
                              color: hasHarvested ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hasHarvested ? 'Harvest Recorded' : 'Pending Harvest',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: hasHarvested ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        if (hasHarvested) ...[
                          const Divider(height: 24),
                          _InfoRow(
                            label: 'Harvest Date',
                            value: harvestInfo?.harvestDate != null
                                ? '${harvestInfo!.harvestDate!.day}/${harvestInfo.harvestDate!.month}/${harvestInfo.harvestDate!.year}'
                                : 'N/A',
                          ),
                          _InfoRow(
                            label: 'Actual Yield',
                            value: '${harvestInfo?.actualQuantity ?? 0} kg',
                            isHighlighted: true,
                          ),
                          if (harvestInfo?.storageLocation != null)
                            _InfoRow(
                              label: 'Storage',
                              value: harvestInfo!.storageLocation!,
                            ),
                        ] else ...[
                          const SizedBox(height: 12),
                          Text(
                            'Update harvest information once you complete harvesting',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UpdateHarvestScreen(
                            cooperative: cooperative,
                          ),
                        ),
                      );
                    },
                    icon: Icon(hasHarvested ? Icons.edit : Icons.add),
                    label: Text(hasHarvested ? 'Update Harvest' : 'Record Harvest'),
                  ),
                ),
                
                // Notify Aggregators Button (only show if harvested)
                if (hasHarvested && cooperative.availableForSale) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showNotifyAggregatorsDialog(context, cooperative),
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Notify Aggregators'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
                
                // Generate QR Codes Button (only show if harvested)
                if (hasHarvested) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const BatchQRScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Generate QR Codes'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _generateCertificate(context, cooperative),
                      icon: const Icon(Icons.description),
                      label: const Text('Generate Quality Certificate'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNotifyAggregatorsDialog(BuildContext context, CooperativeModel cooperative) {
    showDialog(
      context: context,
      builder: (context) => _NotifyAggregatorsDialog(cooperative: cooperative),
    );
  }

  Future<void> _generateCertificate(BuildContext context, CooperativeModel cooperative) async {
    try {
      await PDFGenerator.generateQualityCertificate(
        cooperativeName: cooperative.cooperativeName,
        batchId: cooperative.id,
        variety: cooperative.agroDealerPurchase?.seedBatch ?? 'Unknown',
        quantity: cooperative.harvestInfo!.actualQuantity ?? 0,
        quality: 'A', // Could be dynamic based on harvest data
        harvestDate: cooperative.harvestInfo!.harvestDate ?? DateTime.now(),
        location: '${cooperative.location.district}, ${cooperative.location.sector}',
        certificationNumber: 'CERT-${cooperative.id.substring(0, 8).toUpperCase()}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating certificate: $e')),
        );
      }
    }
  }
}

// New Dialog for Notifying Aggregators
class _NotifyAggregatorsDialog extends StatefulWidget {
  final CooperativeModel cooperative;

  const _NotifyAggregatorsDialog({required this.cooperative});

  @override
  State<_NotifyAggregatorsDialog> createState() => _NotifyAggregatorsDialogState();
}

class _NotifyAggregatorsDialogState extends State<_NotifyAggregatorsDialog> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isSending = false;
  List<AggregatorModel> _aggregators = [];
  List<AggregatorModel> _filteredAggregators = [];
  final Set<String> _selectedAggregatorIds = {};

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
          SnackBar(content: Text('Error loading aggregators: $e')),
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

  Future<void> _sendNotifications() async {
    if (_selectedAggregatorIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one aggregator')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final quantity = widget.cooperative.harvestInfo?.actualQuantity ?? 0;
      final price = widget.cooperative.pricePerKg ?? 0;
      
      int successCount = 0;
      for (final aggregatorId in _selectedAggregatorIds) {
        final aggregator = _aggregators.firstWhere((a) => a.userId == aggregatorId);
        
        // Send SMS
        if (aggregator.phone.isNotEmpty) {
          try {
            await SMSService().sendNotification(
              phoneNumber: aggregator.phone,
              title: 'New Harvest Available',
              body: '${widget.cooperative.cooperativeName} has ${quantity.toStringAsFixed(0)} kg '
                    'of beans available at ${price.toStringAsFixed(0)} RWF/kg. '
                    'Location: ${widget.cooperative.location.district}. '
                    'Contact to place order.',
            );
            successCount++;
            debugPrint('✅ SMS sent to: ${aggregator.businessName}');
          } catch (e) {
            debugPrint('⚠️ SMS failed for ${aggregator.businessName}: $e');
          }
        }

        // Create notification record
        await FirebaseFirestore.instance.collection('harvest_notifications').add({
          'farmerId': widget.cooperative.userId,
          'farmerName': widget.cooperative.cooperativeName,
          'aggregatorId': aggregator.userId,
          'aggregatorName': aggregator.businessName,
          'quantity': quantity,
          'pricePerKg': price,
          'location': {
            'district': widget.cooperative.location.district,
            'sector': widget.cooperative.location.sector,
          },
          'notificationDate': Timestamp.now(),
          'status': 'sent',
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notifications sent to $successCount aggregator(s)!'),
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
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Notify Aggregators',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search aggregators...',
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

            // Aggregators List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredAggregators.isEmpty
                      ? Center(
                          child: Text(
                            'No aggregators found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredAggregators.length,
                          itemBuilder: (context, index) {
                            final aggregator = _filteredAggregators[index];
                            final isSelected = _selectedAggregatorIds.contains(aggregator.userId);
                            
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedAggregatorIds.add(aggregator.userId);
                                  } else {
                                    _selectedAggregatorIds.remove(aggregator.userId);
                                  }
                                });
                              },
                              title: Text(aggregator.businessName),
                              subtitle: Text(
                                '${aggregator.location.district}, ${aggregator.location.sector}',
                              ),
                              secondary: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: const Icon(Icons.business, color: Colors.green),
                              ),
                            );
                          },
                        ),
            ),

            // Send Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedAggregatorIds.length} selected',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSending ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendNotifications,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSending ? 'Sending...' : 'Send Notifications'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighlighted ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
