import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../models/cooperative_model.dart';
import '../../models/aggregator_model.dart';
import '../../models/institution_model.dart';
import '../../models/agro_dealer_model.dart';
import '../../models/agro_dealer_sale_model.dart';
import '../../models/seed_batch_model.dart';
import '../../models/seed_producer_model.dart';
import '../../models/inventory_model.dart';
import '../../models/user_model.dart';
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

  Future<Map<String, dynamic>> _getCompleteSupplyChain() async {
    try {
      // Determine if this is an institution order with potential trader involvement
      final institution = await FirestoreService().getInstitutionByUserId(_order!.buyerId);

      // Check if order went through a trader (look for intermediate orders)
      final traderOrdersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: _order!.buyerId)
          .where('status', whereIn: ['accepted', 'delivered'])
          .get();

      // Check if sellerId is a trader (not an aggregator)
      final aggregatorCheck = await FirestoreService().getAggregatorByUserId(_order!.sellerId);

      // If not an aggregator, check if it's a trader by looking for inventory
      InventoryModel? traderInventory;
      AggregatorModel? aggregator;

      if (aggregatorCheck == null) {
        // Try to find trader inventory
        final inventorySnapshot = await FirebaseFirestore.instance
            .collection('inventory')
            .where('traderId', isEqualTo: _order!.sellerId)
            .limit(1)
            .get();

        if (inventorySnapshot.docs.isNotEmpty) {
          traderInventory = InventoryModel.fromFirestore(inventorySnapshot.docs.first);
          // Get the aggregator supplier
          aggregator = await FirestoreService().getAggregatorByUserId(traderInventory.supplierId);
        } else {
          aggregator = null;
        }
      } else {
        aggregator = aggregatorCheck;
      }

      // Get aggregator's recent order to farmer
      final farmerOrdersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: _order!.sellerId)
          .where('orderType', isEqualTo: 'aggregator_to_farmer')
          .orderBy('orderDate', descending: true)
          .limit(1)
          .get();

      CooperativeModel? cooperative;
      AgroDealerModel? agroDealer;
      SeedBatchModel? seedBatch;
      SeedProducerModel? seedProducer;

      if (farmerOrdersSnapshot.docs.isNotEmpty) {
        final farmerOrder = OrderModel.fromFirestore(farmerOrdersSnapshot.docs.first);

        // Get farmer cooperative
        cooperative = await FirestoreService().getCooperativeByUserId(farmerOrder.sellerId);

        if (cooperative?.agroDealerPurchase != null) {
          final agroPurchase = cooperative!.agroDealerPurchase!;

          // Try using FK first, fallback to name search
          if (agroPurchase.dealerId != null) {
            final agroDealerDoc = await FirebaseFirestore.instance
                .collection('agro_dealers')
                .doc(agroPurchase.dealerId)
                .get();

            if (agroDealerDoc.exists) {
              agroDealer = AgroDealerModel.fromFirestore(agroDealerDoc);
            }
          } else {
            // Fallback to name search for legacy data
            final agroDealerSnapshot = await FirebaseFirestore.instance
                .collection('agro_dealers')
                .where('businessName', isEqualTo: agroPurchase.dealerName)
                .limit(1)
                .get();

            if (agroDealerSnapshot.docs.isNotEmpty) {
              agroDealer = AgroDealerModel.fromFirestore(agroDealerSnapshot.docs.first);
            }
          }

          // Try to find seed batch using FK first
          if (agroPurchase.seedBatchId != null) {
            final seedBatchDoc = await FirebaseFirestore.instance
                .collection('seed_batches')
                .doc(agroPurchase.seedBatchId)
                .get();

            if (seedBatchDoc.exists) {
              seedBatch = SeedBatchModel.fromFirestore(seedBatchDoc);

              // Get seed producer
              final seedProducerDoc = await FirebaseFirestore.instance
                  .collection('seed_producers')
                  .doc(seedBatch.producerId)
                  .get();

              if (seedProducerDoc.exists) {
                seedProducer = SeedProducerModel.fromFirestore(seedProducerDoc);
              }
            }
          } else if (agroDealer != null) {
            // Fallback to batch number search for legacy data
            final seedSaleSnapshot = await FirebaseFirestore.instance
                .collection('agro_dealer_sales')
                .where('agroDealerId', isEqualTo: agroDealer.userId)
                .where('batchNumber', isEqualTo: agroPurchase.seedBatch)
                .limit(1)
                .get();

            if (seedSaleSnapshot.docs.isNotEmpty) {
              final sale = AgroDealerSaleModel.fromFirestore(seedSaleSnapshot.docs.first);

              // Try to find seed batch
              final seedBatchSnapshot = await FirebaseFirestore.instance
                  .collection('seed_batches')
                  .where('batchNumber', isEqualTo: sale.batchNumber)
                  .limit(1)
                  .get();

              if (seedBatchSnapshot.docs.isNotEmpty) {
                seedBatch = SeedBatchModel.fromFirestore(seedBatchSnapshot.docs.first);

                // Get seed producer
                final seedProducerDoc = await FirebaseFirestore.instance
                    .collection('seed_producers')
                    .doc(seedBatch.producerId)
                    .get();

                if (seedProducerDoc.exists) {
                  seedProducer = SeedProducerModel.fromFirestore(seedProducerDoc);
                }
              }
            }
          }
        }
      }

      return {
        'aggregator': aggregator,
        'traderInventory': traderInventory,
        'cooperative': cooperative,
        'agroDealer': agroDealer,
        'seedBatch': seedBatch,
        'seedProducer': seedProducer,
      };
    } catch (e) {
      debugPrint('Error loading complete supply chain: $e');
      return {};
    }
  }

  Future<AggregatorModel?> _findTraderSupplier(String traderId) async {
    try {
      // Find inventory records for this trader to get supplier info
      final inventorySnapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('userId', isEqualTo: traderId)
          .limit(1)
          .get();

      if (inventorySnapshot.docs.isNotEmpty) {
        final inventory = inventorySnapshot.docs.first.data();
        final supplierId = inventory['supplierId'] as String?;

        if (supplierId != null) {
          return await FirestoreService().getAggregatorByUserId(supplierId);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error finding trader supplier: $e');
      return null;
    }
  }

  Widget _buildInstitutionToAggregatorChain(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCompleteSupplyChain(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final seedProducer = data['seedProducer'] as SeedProducerModel?;
        final seedBatch = data['seedBatch'] as SeedBatchModel?;
        final agroDealer = data['agroDealer'] as AgroDealerModel?;
        final cooperative = data['cooperative'] as CooperativeModel?;
        final aggregator = data['aggregator'] as AggregatorModel?;
        final traderInventory = data['traderInventory'] as InventoryModel?;

        return Column(
          children: [
            // Seed Producer (real data)
            if (seedProducer != null)
              _ChainActor(
                icon: Icons.eco,
                title: 'Seed Producer',
                name: seedProducer.organizationName,
                location: '${seedProducer.location.district}, ${seedProducer.location.sector}',
                details: seedBatch != null
                    ? 'Batch: ${seedBatch.batchNumber} • ${seedBatch.variety}${seedBatch.ironContent != null ? ' • ${seedBatch.ironContent!.toStringAsFixed(0)}mg Fe/100g' : ''}'
                    : 'Certified seed producer',
                color: Colors.brown,
                showConnector: true,
              )
            else
              _ChainActor(
                icon: Icons.eco,
                title: 'Seed Producer',
                name: 'Iron-Biofortified Seed Producer',
                location: 'Rwanda',
                details: 'Certified high-iron variety (80-90mg/100g)',
                color: Colors.brown.withOpacity(0.5),
                showConnector: true,
              ),

            // Agro-Dealer (real data)
            if (agroDealer != null)
              _ChainActor(
                icon: Icons.store,
                title: 'Agro-Dealer',
                name: agroDealer.businessName,
                location: '${agroDealer.location.district}, ${agroDealer.location.sector}',
                details: 'License: ${agroDealer.licenseNumber}',
                color: Colors.orange,
                showConnector: true,
              )
            else
              _ChainActor(
                icon: Icons.store,
                title: 'Agro-Dealer',
                name: cooperative?.agroDealerPurchase?.dealerName ?? 'Certified Input Supplier',
                location: _order!.deliveryLocation.district,
                details: cooperative?.agroDealerPurchase != null
                    ? 'Seed batch: ${cooperative!.agroDealerPurchase!.seedBatch}'
                    : 'Licensed seed distributor',
                color: agroDealer == null ? Colors.orange.withOpacity(0.5) : Colors.orange,
                showConnector: true,
              ),

            // Farmer Cooperative (real data)
            if (cooperative != null)
              _ChainActor(
                icon: Icons.agriculture,
                title: 'Farmer Cooperative',
                name: cooperative.cooperativeName,
                location: '${cooperative.location.district}, ${cooperative.location.sector}',
                details: '${cooperative.numberOfMembers} members',
                color: Colors.green,
                showConnector: true,
              )
            else
              _ChainActor(
                icon: Icons.agriculture,
                title: 'Farmer Cooperative',
                name: 'Bean Farmer Cooperative',
                location: _order!.deliveryLocation.district,
                details: 'Organic farming practices',
                color: Colors.green.withOpacity(0.5),
                showConnector: true,
              ),

            // Aggregator (real data)
            if (aggregator != null)
              _ChainActor(
                icon: Icons.local_shipping,
                title: 'Aggregator',
                name: aggregator.businessName,
                location: '${aggregator.location.district}',
                details: aggregator.storageInfo != null
                    ? 'Storage: ${aggregator.storageInfo!.capacityInTons} tons'
                    : '',
                color: Colors.blue,
                showConnector: true,
              )
            else
              FutureBuilder<AggregatorModel?>(
                future: FirestoreService().getAggregatorByUserId(_order!.sellerId),
                builder: (context, aggSnapshot) {
                  final agg = aggSnapshot.data;
                  return _ChainActor(
                    icon: Icons.local_shipping,
                    title: 'Aggregator',
                    name: agg?.businessName ?? 'Loading...',
                    location: agg != null ? '${agg.location.district}' : '',
                    details: agg?.storageInfo != null
                        ? 'Storage: ${agg!.storageInfo!.capacityInTons} tons'
                        : '',
                    color: Colors.blue,
                    showConnector: traderInventory != null,
                  );
                },
              ),

            // Trader (if present in supply chain)
            if (traderInventory != null)
              _ChainActor(
                icon: Icons.storefront,
                title: 'Trader',
                name: traderInventory.supplierName != 'Unknown'
                    ? 'Bean Trader'
                    : 'Bean Trader',
                location: traderInventory.storageLocation,
                details: '${traderInventory.quantityPurchased.toStringAsFixed(0)}kg traded • Quality: ${traderInventory.quality}',
                color: Colors.teal,
                showConnector: true,
              ),

            // Institution
            FutureBuilder<InstitutionModel?>(
              future: FirestoreService().getInstitutionByUserId(_order!.buyerId),
              builder: (context, instSnapshot) {
                final institution = instSnapshot.data;
                return _ChainActor(
                  icon: Icons.school,
                  title: 'Institution',
                  name: institution?.institutionName ?? 'Loading...',
                  location: institution != null ? '${institution.location.district}' : '',
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
      },
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
