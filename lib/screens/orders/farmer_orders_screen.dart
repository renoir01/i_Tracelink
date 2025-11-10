import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/cooperative_model.dart';
import '../../models/aggregator_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import 'order_details_screen.dart';

class FarmerOrdersScreen extends StatelessWidget {
  const FarmerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Accepted'),
                Tab(text: 'Completed'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OrdersList(userId: userId, status: 'pending'),
                  _OrdersList(userId: userId, status: 'accepted'),
                  _OrdersList(userId: userId, status: 'completed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final String userId;
  final String status;

  const _OrdersList({
    required this.userId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: FirestoreService().getUserOrders(userId, isBuyer: false),
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

        final allOrders = snapshot.data ?? [];
        final orders = allOrders.where((order) => order.status == status).toList();

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No $status orders',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _OrderCard(order: orders[index]);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isProcessing = false;

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() => _isProcessing = true);

    try {
      await FirestoreService().updateOrderStatus(widget.order.id, newStatus);
      
      // Send SMS & in-app notification to aggregator (buyer)
      try {
        final aggregator = await FirestoreService().getAggregatorByUserId(widget.order.buyerId);
        final cooperative = await FirestoreService().getCooperativeByUserId(widget.order.sellerId);
        
        if (aggregator != null && cooperative != null) {
          final deliveryDate = '${widget.order.expectedDeliveryDate.day}/${widget.order.expectedDeliveryDate.month}/${widget.order.expectedDeliveryDate.year}';
          
          if (newStatus == 'accepted') {
            // SMS
            if (aggregator.phone.isNotEmpty) {
              await SMSService().sendOrderAcceptedNotification(
                phoneNumber: aggregator.phone,
                cooperativeName: cooperative.cooperativeName,
                quantity: widget.order.quantity,
                deliveryDate: deliveryDate,
              );
              debugPrint('✅ SMS sent to aggregator: ${aggregator.phone}');
            }
            
            // In-app notification
            await NotificationService().notifyOrderAccepted(
              userId: widget.order.buyerId,
              cooperativeName: cooperative.cooperativeName,
              orderId: widget.order.id,
            );
            debugPrint('✅ In-app notification sent to aggregator');
            
          } else if (newStatus == 'rejected') {
            // SMS
            if (aggregator.phone.isNotEmpty) {
              await SMSService().sendOrderRejectedNotification(
                phoneNumber: aggregator.phone,
                cooperativeName: cooperative.cooperativeName,
                quantity: widget.order.quantity,
              );
              debugPrint('✅ Rejection SMS sent to aggregator: ${aggregator.phone}');
            }
            
            // In-app notification
            await NotificationService().notifyOrderRejected(
              userId: widget.order.buyerId,
              cooperativeName: cooperative.cooperativeName,
              orderId: widget.order.id,
            );
            debugPrint('✅ Rejection notification sent to aggregator');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Notification error: $e');
        // Don't block status update if notifications fail
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${newStatus == 'accepted' ? 'accepted' : 'rejected'}'),
            backgroundColor: newStatus == 'accepted' 
                ? AppTheme.successColor 
                : AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showOrderDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(
          order: widget.order,
          isBuyer: false, // Farmer is the seller
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.order.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _showOrderDetails,
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
                          'Order #${widget.order.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.order.requestDate.day}/${widget.order.requestDate.month}/${widget.order.requestDate.year}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: widget.order.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        Text(
                          '${widget.order.quantity} kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        Text(
                          'RWF ${widget.order.totalAmount}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (isPending && !_isProcessing) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateOrderStatus('rejected'),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateOrderStatus('accepted'),
                        icon: const Icon(Icons.check),
                        label: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
              
              if (_isProcessing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'accepted':
        color = Colors.blue;
        icon = Icons.check_circle;
        break;
      case 'completed':
        color = Colors.green;
        icon = Icons.done_all;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

