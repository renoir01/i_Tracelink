import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class AggregatorOrdersScreen extends StatefulWidget {
  const AggregatorOrdersScreen({super.key});

  @override
  State<AggregatorOrdersScreen> createState() => _AggregatorOrdersScreenState();
}

class _AggregatorOrdersScreenState extends State<AggregatorOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(userId, null),
          _buildOrdersList(userId, 'pending'),
          _buildOrdersList(userId, 'accepted'),
          _buildOrdersList(userId, 'fulfilled'),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String userId, String? status) {
    Query query = FirebaseFirestore.instance
        .collection(AppConstants.ordersCollection)
        .where('buyerId', isEqualTo: userId)
        .orderBy('requestDate', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  status == null ? 'No orders yet' : 'No $status orders',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Orders will appear here when you place them',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final doc = orders[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildOrderCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> data) {
    final requestDate = (data['requestDate'] as Timestamp?)?.toDate();
    final expectedDeliveryDate = (data['expectedDeliveryDate'] as Timestamp?)?.toDate();
    final status = data['status'] ?? 'pending';
    final quantity = data['quantity']?.toDouble() ?? 0.0;
    final pricePerKg = data['pricePerKg']?.toDouble() ?? 0.0;
    final totalAmount = data['totalAmount']?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showOrderDetails(orderId, data),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${orderId.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${quantity.toStringAsFixed(0)} kg @ RWF ${pricePerKg.toStringAsFixed(0)}/kg',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
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
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoTile(
                      'Total Amount',
                      'RWF ${totalAmount.toStringAsFixed(0)}',
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoTile(
                      'Order Date',
                      requestDate != null
                          ? '${requestDate.day}/${requestDate.month}/${requestDate.year}'
                          : 'N/A',
                      Icons.calendar_today,
                    ),
                  ),
                ],
              ),
              if (expectedDeliveryDate != null) ...[
                const SizedBox(height: 8),
                _buildInfoTile(
                  'Expected Delivery',
                  '${expectedDeliveryDate.day}/${expectedDeliveryDate.month}/${expectedDeliveryDate.year}',
                  Icons.local_shipping,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showOrderDetails(orderId, data),
                      icon: const Icon(Icons.visibility, size: 20),
                      label: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showOrderDetails(String orderId, Map<String, dynamic> data) {
    final requestDate = (data['requestDate'] as Timestamp?)?.toDate();
    final expectedDeliveryDate = (data['expectedDeliveryDate'] as Timestamp?)?.toDate();
    final actualDeliveryDate = (data['actualDeliveryDate'] as Timestamp?)?.toDate();
    final status = data['status'] ?? 'pending';
    final quantity = data['quantity']?.toDouble() ?? 0.0;
    final pricePerKg = data['pricePerKg']?.toDouble() ?? 0.0;
    final totalAmount = data['totalAmount']?.toDouble() ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order Details',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      size: 16,
                      color: _getStatusColor(status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
              _buildDetailRow('Order ID', orderId.substring(0, 12)),
              _buildDetailRow('Quantity', '${quantity.toStringAsFixed(0)} kg'),
              _buildDetailRow('Price per kg', 'RWF ${pricePerKg.toStringAsFixed(0)}'),
              _buildDetailRow('Total Amount', 'RWF ${totalAmount.toStringAsFixed(0)}'),
              if (requestDate != null)
                _buildDetailRow(
                  'Order Date',
                  '${requestDate.day}/${requestDate.month}/${requestDate.year}',
                ),
              if (expectedDeliveryDate != null)
                _buildDetailRow(
                  'Expected Delivery',
                  '${expectedDeliveryDate.day}/${expectedDeliveryDate.month}/${expectedDeliveryDate.year}',
                ),
              if (actualDeliveryDate != null)
                _buildDetailRow(
                  'Actual Delivery',
                  '${actualDeliveryDate.day}/${actualDeliveryDate.month}/${actualDeliveryDate.year}',
                ),
              if (data['notes'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(data['notes']),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'fulfilled':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'fulfilled':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
