import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../models/cooperative_model.dart';
import '../../models/aggregator_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../orders/order_details_screen.dart';

class PendingOrdersScreen extends StatefulWidget {
  const PendingOrdersScreen({Key? key}) : super(key: key);

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Orders'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .orderBy('requestDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data?.docs
                  .map((doc) => OrderModel.fromFirestore(doc))
                  .toList() ??
              [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Pending Orders',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New orders from buyers will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(context, order);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header with order info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PENDING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy - HH:mm').format(order.requestDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Buyer information
          FutureBuilder<Map<String, dynamic>>(
            future: _getBuyerInfo(order.buyerId),
            builder: (context, snapshot) {
              final buyerName = snapshot.data?['name'] ?? 'Loading...';
              final buyerType = snapshot.data?['type'] ?? '';
              final buyerPhone = snapshot.data?['phone'] ?? '';

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Buyer info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(
                            _getBuyerIcon(buyerType),
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Buyer',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                buyerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (buyerPhone.isNotEmpty)
                                Text(
                                  buyerPhone,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Order details
                    _buildDetailRow(
                      'Quantity',
                      '${order.quantity.toStringAsFixed(1)} kg',
                      Icons.scale,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Price per kg',
                      '${order.pricePerKg.toStringAsFixed(0)} RWF',
                      Icons.attach_money,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Total Amount',
                      '${order.totalAmount.toStringAsFixed(0)} RWF',
                      Icons.payments,
                      isHighlight: true,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Delivery Date',
                      DateFormat('MMM dd, yyyy').format(order.expectedDeliveryDate),
                      Icons.local_shipping,
                    ),

                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.note, size: 16, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.notes!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _showRejectDialog(context, order),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.close, size: 18),
                                      SizedBox(width: 4),
                                      Text('Reject'),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _showAcceptDialog(context, order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle, size: 18),
                                      SizedBox(width: 4),
                                      Text('Accept Order'),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlight ? Colors.green : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getBuyerInfo(String buyerId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(buyerId)
          .get();

      if (!userDoc.exists) {
        return {'name': 'Unknown', 'type': '', 'phone': ''};
      }

      final userData = userDoc.data()!;
      final userType = userData['userType'] ?? '';
      String name = 'Unknown';
      String phone = userData['phone'] ?? '';

      // Get name based on user type
      if (userType == 'aggregator') {
        final aggDoc = await FirebaseFirestore.instance
            .collection('aggregators')
            .doc(buyerId)
            .get();
        if (aggDoc.exists) {
          name = aggDoc.data()?['businessName'] ?? 'Unknown Aggregator';
        }
      } else if (userType == 'institution') {
        final instDoc = await FirebaseFirestore.instance
            .collection('institutions')
            .doc(buyerId)
            .get();
        if (instDoc.exists) {
          name = instDoc.data()?['institutionName'] ?? 'Unknown Institution';
        }
      } else if (userType == 'cooperative') {
        final coopDoc = await FirebaseFirestore.instance
            .collection('cooperatives')
            .doc(buyerId)
            .get();
        if (coopDoc.exists) {
          name = coopDoc.data()?['cooperativeName'] ?? 'Unknown Cooperative';
        }
      }

      return {
        'name': name,
        'type': userType,
        'phone': phone,
      };
    } catch (e) {
      debugPrint('Error fetching buyer info: $e');
      return {'name': 'Error loading', 'type': '', 'phone': ''};
    }
  }

  IconData _getBuyerIcon(String userType) {
    switch (userType) {
      case 'aggregator':
        return Icons.store;
      case 'institution':
        return Icons.business;
      case 'cooperative':
        return Icons.groups;
      default:
        return Icons.person;
    }
  }

  void _showAcceptDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to accept this order?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantity: ${order.quantity.toStringAsFixed(1)} kg',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Total: ${order.totalAmount.toStringAsFixed(0)} RWF',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Delivery: ${DateFormat('MMM dd, yyyy').format(order.expectedDeliveryDate)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, OrderModel order) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejecting this order:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Insufficient stock, Price issue, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _rejectOrder(order, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptOrder(OrderModel order) async {
    setState(() => _isLoading = true);

    try {
      // Update order status
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({
        'status': 'accepted',
        'acceptedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // TODO: Send notification to buyer (implement in notification service)
      // await NotificationService().sendOrderAcceptedNotification(order);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error accepting order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectOrder(OrderModel order, String reason) async {
    setState(() => _isLoading = true);

    try {
      // Update order status
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // TODO: Send notification to buyer (implement in notification service)
      // await NotificationService().sendOrderRejectedNotification(order, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
