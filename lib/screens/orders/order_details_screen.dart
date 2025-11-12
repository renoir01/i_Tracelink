import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/order_model.dart';
import '../../models/cooperative_model.dart';
import '../../models/aggregator_model.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../payment_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;
  final bool isBuyer; // true if viewing as buyer, false if seller

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.isBuyer,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isProcessing = false;

  Future<void> _updateOrderStatus(String newStatus) async {
    // Confirm action
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm ${_getStatusLabel(newStatus)}'),
        content: Text('Are you sure you want to mark this order as ${_getStatusLabel(newStatus).toLowerCase()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await FirestoreService().updateOrderStatus(widget.order.id, newStatus);
      
      // Send SMS & in-app notification to relevant party
      try {
        String? phoneNumber;
        String? notifyUserId;
        
        // Determine who to notify based on status and role
        if (widget.isBuyer) {
          // Buyer (aggregator) is updating status, notify seller (farmer)
          final cooperative = await FirestoreService().getCooperativeByUserId(widget.order.sellerId);
          phoneNumber = cooperative?.phone;
          notifyUserId = widget.order.sellerId;
        } else {
          // Seller (farmer) is updating status, notify buyer (aggregator)
          final aggregator = await FirestoreService().getAggregatorByUserId(widget.order.buyerId);
          phoneNumber = aggregator?.phone;
          notifyUserId = widget.order.buyerId;
        }
        
        // SMS notification
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          await SMSService().sendOrderStatusUpdate(
            phoneNumber: phoneNumber,
            orderId: widget.order.id,
            newStatus: newStatus,
          );
          debugPrint('✅ Status update SMS sent to: $phoneNumber');
        }
        
        // In-app notification
        if (notifyUserId != null) {
          await NotificationService().notifyOrderStatusUpdate(
            userId: notifyUserId,
            orderId: widget.order.id,
            status: newStatus,
          );
          debugPrint('✅ Status update notification sent');
        }
      } catch (e) {
        debugPrint('⚠️ Notification error: $e');
        // Don't block status update if notifications fail
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as ${_getStatusLabel(newStatus).toLowerCase()}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context); // Go back after update
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'preparing':
        return 'Preparing';
      case 'shipped':
        return 'Shipped';
      case 'collected':
        return 'Collected';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      default:
        return status.toUpperCase();
    }
  }

  void _navigateToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(order: widget.order),
      ),
    );
  }

  List<Widget> _getActionButtons() {
    final List<Widget> buttons = [];

    // Buyer Payment Button (if payment is pending and order is accepted)
    if (widget.isBuyer &&
        widget.order.status == 'accepted' &&
        (widget.order.paymentStatus == 'pending' || widget.order.paymentStatus == 'unpaid')) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _navigateToPayment,
            icon: const Icon(Icons.payment),
            label: const Text('Pay Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      );
      // Add spacing if there are other buttons
      if (buttons.length < 2) {
        return buttons;
      }
      buttons.add(const SizedBox(width: 12));
    }

    // Seller (Farmer/Cooperative) actions
    if (!widget.isBuyer) {
      if (widget.order.status == 'accepted') {
        // Seller can start preparing the order
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _updateOrderStatus('preparing'),
              icon: const Icon(Icons.soup_kitchen),
              label: const Text('Start Preparing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
        );
      } else if (widget.order.status == 'preparing') {
        // Seller can mark as ready for pickup/shipping
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _updateOrderStatus('shipped'),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Mark as Shipped'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
          ),
        );
      } else if (widget.order.status == 'delivered') {
        // Seller confirms completion after delivery
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _updateOrderStatus('completed'),
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirm Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
              ),
            ),
          ),
        );
      }
    }

    // Buyer (Aggregator/Institution) actions
    if (widget.isBuyer) {
      if (widget.order.status == 'shipped') {
        // Buyer collects the order
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _updateOrderStatus('collected'),
              icon: const Icon(Icons.inventory_2),
              label: const Text('Mark Collected'),
            ),
          ),
        );
      } else if (widget.order.status == 'collected') {
        // Buyer transports the order
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _updateOrderStatus('in_transit'),
              icon: const Icon(Icons.local_shipping),
              label: const Text('In Transit'),
            ),
          ),
        );
      } else if (widget.order.status == 'in_transit') {
        // Buyer marks as delivered to final destination
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _updateOrderStatus('delivered'),
              icon: const Icon(Icons.done),
              label: const Text('Mark Delivered'),
            ),
          ),
        );
      }
    }

    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Timeline
                  _OrderTimeline(order: widget.order),
                  const SizedBox(height: 24),

                  // Order Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Divider(height: 24),
                          _InfoRow(label: 'Order ID', value: widget.order.id),
                          _InfoRow(label: 'Order Type', value: widget.order.orderType),
                          _InfoRow(label: 'Quantity', value: '${widget.order.quantity} kg'),
                          _InfoRow(label: 'Price per kg', value: 'RWF ${widget.order.pricePerKg}'),
                          _InfoRow(
                            label: 'Total Amount',
                            value: 'RWF ${widget.order.totalAmount}',
                            isHighlighted: true,
                          ),
                          _InfoRow(
                            label: 'Order Date',
                            value: '${widget.order.requestDate.day}/${widget.order.requestDate.month}/${widget.order.requestDate.year}',
                          ),
                          _InfoRow(
                            label: 'Expected Delivery',
                            value: '${widget.order.expectedDeliveryDate.day}/${widget.order.expectedDeliveryDate.month}/${widget.order.expectedDeliveryDate.year}',
                          ),
                          _InfoRow(label: 'Payment Status', value: widget.order.paymentStatus.toUpperCase()),
                          if (widget.order.notes != null) ...[
                            const SizedBox(height: 12),
                            const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(widget.order.notes!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Delivery Location',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('${widget.order.deliveryLocation.district}, ${widget.order.deliveryLocation.sector}'),
                          if (widget.order.deliveryLocation.cell.isNotEmpty)
                            Text('Cell: ${widget.order.deliveryLocation.cell}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // QR Code for Traceability
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_2, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Order QR Code',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                            ),
                            child: QrImageView(
                              data: widget.order.id,
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.white,
                              errorStateBuilder: (ctx, err) {
                                return const Center(
                                  child: Text(
                                    'Error generating QR code',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Scan this QR code to verify complete traceability',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Order ID: ${widget.order.id.substring(0, 8)}...',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          if (_getActionButtons().isNotEmpty && !_isProcessing)
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
                children: _getActionButtons(),
              ),
            ),

          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              child: const CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  final OrderModel order;

  const _OrderTimeline({required this.order});

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  DateTime? _getTimestampForStatus(String status) {
    switch (status) {
      case 'pending':
        return order.requestDate;
      case 'accepted':
        return order.acceptedAt;
      case 'preparing':
        return order.preparingAt;
      case 'shipped':
        return order.shippedAt;
      case 'collected':
        return order.collectedAt;
      case 'in_transit':
        return order.inTransitAt;
      case 'delivered':
        return order.deliveredAt;
      case 'completed':
        return order.completedAt;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statuses = [
      {'status': 'pending', 'label': 'Pending', 'icon': Icons.schedule},
      {'status': 'accepted', 'label': 'Accepted', 'icon': Icons.check_circle},
      {'status': 'preparing', 'label': 'Preparing', 'icon': Icons.soup_kitchen},
      {'status': 'shipped', 'label': 'Shipped', 'icon': Icons.local_shipping},
      {'status': 'collected', 'label': 'Collected', 'icon': Icons.inventory_2},
      {'status': 'in_transit', 'label': 'In Transit', 'icon': Icons.local_shipping},
      {'status': 'delivered', 'label': 'Delivered', 'icon': Icons.done},
      {'status': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
    ];

    final currentIndex = statuses.indexWhere((s) => s['status'] == order.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Column(
              children: List.generate(statuses.length, (index) {
                final status = statuses[index];
                final isActive = index <= currentIndex;
                final isCurrent = index == currentIndex;
                final isLast = index == statuses.length - 1;

                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.primaryColor
                                : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            status['icon'] as IconData,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    status['label'] as String,
                                    style: TextStyle(
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                      fontSize: isCurrent ? 16 : 14,
                                      color: isActive ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                  if (isActive)
                                    Text(
                                      _formatTimestamp(_getTimestampForStatus(status['status'] as String)),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                              if (isCurrent)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Current',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!isLast)
                      Container(
                        margin: const EdgeInsets.only(left: 19),
                        width: 2,
                        height: 30,
                        color: isActive ? AppTheme.primaryColor : Colors.grey[300],
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
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
