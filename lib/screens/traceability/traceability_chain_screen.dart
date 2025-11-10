import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../models/cooperative_model.dart';
import '../../models/aggregator_model.dart';
import '../../models/institution_model.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/app_theme.dart';

class TraceabilityChainScreen extends StatefulWidget {
  final OrderModel? order;
  final String? orderId;

  const TraceabilityChainScreen({
    super.key,
    this.order,
    this.orderId,
  }) : assert(order != null || orderId != null, 'Either order or orderId must be provided');

  @override
  State<TraceabilityChainScreen> createState() => _TraceabilityChainScreenState();
}

class _TraceabilityChainScreenState extends State<TraceabilityChainScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    if (widget.order != null) {
      setState(() {
        _order = widget.order;
        _isLoading = false;
      });
      return;
    }

    try {
      final order = await FirestoreService().getOrderById(widget.orderId!);
      if (order != null) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Order not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading order: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traceability Chain'),
        centerTitle: true,
        actions: [
          if (_order != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // TODO: Share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Verified Iron-Biofortified Beans',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order #${_order!.id.substring(0, 8)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'VERIFIED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Order Info Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _InfoRow(label: 'Quantity', value: '${_order!.quantity} kg'),
                    _InfoRow(
                      label: 'Delivery Date',
                      value: '${_order!.expectedDeliveryDate.day}/${_order!.expectedDeliveryDate.month}/${_order!.expectedDeliveryDate.year}',
                    ),
                    _InfoRow(label: 'Status', value: _order!.status.toUpperCase()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Supply Chain Title
            Row(
              children: const [
                Icon(Icons.eco, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Supply Chain Journey',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Supply Chain Visualization
            _buildSupplyChain(context),

            const SizedBox(height: 24),

            // Download Certificate Button
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Generating certificate...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  await PDFService().generateTraceabilityCertificate(_order!);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error generating certificate: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.file_download),
              label: const Text('Download Certificate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplyChain(BuildContext context) {
    // For now, display based on order type
    if (_order!.orderType == 'aggregator_to_farmer') {
      return _buildAggregatorToFarmerChain(context);
    } else if (_order!.orderType == 'institution_to_aggregator') {
      return _buildInstitutionToAggregatorChain(context);
    }
    return const Text('Unknown order type');
  }

  Widget _buildAggregatorToFarmerChain(BuildContext context) {
    return Column(
      children: [
        // Farmer Cooperative
        FutureBuilder<CooperativeModel?>(
          future: FirestoreService().getCooperativeByUserId(_order!.sellerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final cooperative = snapshot.data;
            return _ChainActor(
              icon: Icons.groups,
              title: 'Farmer Cooperative',
              name: cooperative?.cooperativeName ?? 'Loading...',
              location: cooperative != null
                  ? '${cooperative.location.district}, ${cooperative.location.sector}'
                  : '',
              details: cooperative != null
                  ? '${cooperative.numberOfMembers} members'
                  : '',
              color: Colors.green,
              showConnector: true,
            );
          },
        ),

        // Aggregator
        FutureBuilder<AggregatorModel?>(
          future: FirestoreService().getAggregatorByUserId(_order!.buyerId),
          builder: (context, snapshot) {
            final aggregator = snapshot.data;
            return _ChainActor(
              icon: Icons.local_shipping,
              title: 'Aggregator',
              name: aggregator?.businessName ?? 'Loading...',
              location: aggregator != null
                  ? '${aggregator.location.district}'
                  : '',
              details: aggregator?.storageInfo != null
                  ? '${aggregator!.storageInfo!.capacityInTons} tons capacity'
                  : '',
              color: Colors.blue,
              showConnector: false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildInstitutionToAggregatorChain(BuildContext context) {
    return Column(
      children: [
        // Seed Producer (placeholder for now)
        _ChainActor(
          icon: Icons.eco,
          title: 'Seed Producer',
          name: 'Iron-Biofortified Seed Producer',
          location: 'Rwanda',
          details: 'Certified high-iron variety (80-90mg/100g)',
          color: Colors.brown,
          showConnector: true,
        ),

        // Agro-Dealer (placeholder)
        _ChainActor(
          icon: Icons.store,
          title: 'Agro-Dealer',
          name: 'Certified Input Supplier',
          location: _order!.deliveryLocation.district,
          details: 'Licensed seed distributor',
          color: Colors.orange,
          showConnector: true,
        ),

        // Farmer Cooperative (from aggregator's source)
        _ChainActor(
          icon: Icons.agriculture,
          title: 'Farmer Cooperative',
          name: 'Bean Farmer Cooperative',
          location: _order!.deliveryLocation.district,
          details: 'Organic farming practices',
          color: Colors.green,
          showConnector: true,
        ),

        // Aggregator
        FutureBuilder<AggregatorModel?>(
          future: FirestoreService().getAggregatorByUserId(_order!.sellerId),
          builder: (context, snapshot) {
            final aggregator = snapshot.data;
            return _ChainActor(
              icon: Icons.local_shipping,
              title: 'Aggregator',
              name: aggregator?.businessName ?? 'Loading...',
              location: aggregator != null
                  ? '${aggregator.location.district}'
                  : '',
              details: aggregator?.storageInfo != null
                  ? 'Storage: ${aggregator!.storageInfo!.capacityInTons} tons'
                  : '',
              color: Colors.blue,
              showConnector: true,
            );
          },
        ),

        // Institution
        FutureBuilder<InstitutionModel?>(
          future: FirestoreService().getInstitutionByUserId(_order!.buyerId),
          builder: (context, snapshot) {
            final institution = snapshot.data;
            return _ChainActor(
              icon: Icons.school,
              title: 'Institution',
              name: institution?.institutionName ?? 'Loading...',
              location: institution != null
                  ? '${institution.location.district}'
                  : '',
              details: institution?.numberOfBeneficiaries != null
                  ? 'Serves ${institution!.numberOfBeneficiaries} beneficiaries'
                  : '',
              color: Colors.purple,
              showConnector: false,
            );
          },
        ),
      ],
    );
  }
}

class _ChainActor extends StatelessWidget {
  final IconData icon;
  final String title;
  final String name;
  final String location;
  final String details;
  final Color color;
  final bool showConnector;

  const _ChainActor({
    required this.icon,
    required this.title,
    required this.name,
    required this.location,
    required this.details,
    required this.color,
    this.showConnector = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: color, size: 24),
                  ],
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            details,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showConnector)
          Container(
            width: 2,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withOpacity(0.3)],
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
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
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
