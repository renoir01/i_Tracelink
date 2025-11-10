import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';
import '../utils/app_localizations.dart';

class TraceabilityScreen extends StatefulWidget {
  const TraceabilityScreen({super.key});

  @override
  State<TraceabilityScreen> createState() => _TraceabilityScreenState();
}

class _TraceabilityScreenState extends State<TraceabilityScreen> {
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _traceabilityData;
  String? _errorMessage;

  @override
  void dispose() {
    _batchController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _verifyTraceability() async {
    final batchNumber = _batchController.text.trim();
    final orderId = _orderController.text.trim();

    if (batchNumber.isEmpty && orderId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter either a batch number or order ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _traceabilityData = null;
    });

    try {
      Map<String, dynamic>? data;

      if (batchNumber.isNotEmpty) {
        // Verify by batch number
        data = await FirestoreService().getTraceabilityByBatch(batchNumber);
      } else {
        // Verify by order ID
        data = await FirestoreService().getTraceabilityByOrder(orderId);
      }

      if (data == null) {
        setState(() {
          _errorMessage = 'No traceability data found for the provided information';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _traceabilityData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error retrieving traceability data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traceability Verification'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify Product Origin',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter a batch number or order ID to view the complete supply chain from seed to institution.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Input Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Parameters',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _batchController,
                      decoration: const InputDecoration(
                        labelText: 'Batch Number (Optional)',
                        hintText: 'e.g., MB-2025-034',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'OR',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _orderController,
                      decoration: const InputDecoration(
                        labelText: 'Order ID (Optional)',
                        hintText: 'e.g., ORDER-123456',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyTraceability,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Verify Traceability'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: AppTheme.errorColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: AppTheme.errorColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Traceability Results
            if (_traceabilityData != null) ...[
              const SizedBox(height: 16),
              _buildTraceabilityChain(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTraceabilityChain() {
    final data = _traceabilityData!;
    final chain = data['chain'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Traceability Verified',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Product Journey',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Chain Visualization
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chain.length,
              itemBuilder: (context, index) {
                final step = chain[index] as Map<String, dynamic>;
                final isLast = index == chain.length - 1;

                return _buildChainStep(step, isLast, index + 1);
              },
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Summary
            _buildSummaryCard(data),
          ],
        ),
      ),
    );
  }

  Widget _buildChainStep(Map<String, dynamic> step, bool isLast, int stepNumber) {
    final actorType = step['actorType'] as String;
    final actorName = step['actorName'] as String;
    final date = step['date'] as String;
    final location = step['location'] as String?;

    IconData getIcon() {
      switch (actorType) {
        case 'seed_producer':
          return Icons.eco;
        case 'agro_dealer':
          return Icons.store;
        case 'farmer':
          return Icons.agriculture;
        case 'aggregator':
          return Icons.local_shipping;
        case 'institution':
          return Icons.school;
        default:
          return Icons.business;
      }
    }

    String getActorLabel() {
      switch (actorType) {
        case 'seed_producer':
          return 'Seed Producer';
        case 'agro_dealer':
          return 'Agro-Dealer';
        case 'farmer':
          return 'Farmer Cooperative';
        case 'aggregator':
          return 'Aggregator';
        case 'institution':
          return 'Institution';
        default:
          return actorType;
      }
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Number Circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  stepNumber.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Step Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(getIcon(), color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        getActorLabel(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    actorName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Connecting Arrow
        if (!isLast) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(width: 20),
              Icon(Icons.arrow_downward, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ] else ...[
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> data) {
    final quantity = data['quantity']?.toString() ?? 'N/A';
    final variety = data['variety'] ?? 'N/A';
    final quality = data['quality'] ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Summary',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildSummaryRow('Quantity', '$quantity kg'),
        _buildSummaryRow('Variety', variety),
        _buildSummaryRow('Quality Grade', quality),
        _buildSummaryRow('Status', 'Biofortified ✓'),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Share traceability report
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon!')),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share Report'),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
