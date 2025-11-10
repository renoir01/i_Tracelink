import 'dart:async';
import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../services/sms_service.dart';
import '../models/payment_model.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final PaymentModel payment;
  final OrderModel order;

  const PaymentProcessingScreen({
    super.key,
    required this.payment,
    required this.order,
  });

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  Timer? _statusCheckTimer;
  PaymentStatus _currentStatus = PaymentStatus.pending;
  int _checkCount = 0;
  static const int maxChecks = 60; // 5 minutes with 5-second intervals

  @override
  void initState() {
    super.initState();
    _startStatusChecking();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startStatusChecking() {
    // Check status immediately
    _checkPaymentStatus();

    // Then check every 5 seconds
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkCount++;
      if (_checkCount >= maxChecks) {
        timer.cancel();
        _handleTimeout();
        return;
      }
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final paymentService = PaymentService();
      final status = await paymentService.checkPaymentStatus(
        widget.payment.paymentMethod,
        widget.payment.transactionId ?? '',
      );

      if (status != _currentStatus) {
        setState(() => _currentStatus = status);

        // Update payment in Firestore
        await FirestoreService().updatePaymentStatus(
          widget.payment.id,
          status,
          status == PaymentStatus.completed ? DateTime.now() : null,
        );

        // Handle completion
        if (status == PaymentStatus.completed) {
          _handlePaymentSuccess();
        } else if (status == PaymentStatus.failed) {
          _handlePaymentFailure();
        }
      }
    } catch (e) {
      print('Status check error: $e');
    }
  }

  void _handlePaymentSuccess() async {
    _statusCheckTimer?.cancel();

    // Update order status
    await FirestoreService().updateOrderStatus(widget.order.id, AppConstants.orderPaid);
    
    // Send SMS payment confirmation to seller
    try {
      final seller = await FirestoreService().getUserById(widget.order.sellerId);
      if (seller != null && seller.phone.isNotEmpty) {
        await SMSService().sendPaymentConfirmation(
          phoneNumber: seller.phone,
          amount: widget.payment.amount,
          quantity: widget.order.quantity,
          transactionId: widget.payment.transactionId ?? widget.payment.id,
        );
        debugPrint('✅ Payment confirmation SMS sent to: ${seller.phone}');
      }
    } catch (smsError) {
      debugPrint('⚠️ Payment SMS failed: $smsError');
    }

    // Show success dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Text('Payment Successful!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your payment of RWF ${widget.payment.amount.toStringAsFixed(0)} has been processed successfully.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildPaymentDetails(),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to orders
                Navigator.of(context).pop(); // Go back to dashboard
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    });
  }

  void _handlePaymentFailure() {
    _statusCheckTimer?.cancel();

    // Show failure dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              const Text('Payment Failed'),
            ],
          ),
          content: const Text(
            'Your payment could not be processed. Please check your mobile money balance and try again.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to payment screen
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    });
  }

  void _handleTimeout() {
    // Show timeout dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.access_time, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text('Payment Timeout'),
            ],
          ),
          content: const Text(
            'Payment confirmation is taking longer than expected. Please check your mobile money app for payment status.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to orders
              Navigator.of(context).pop(); // Go back to dashboard
            },
              child: const Text('Continue'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Refresh status one more time
                _checkPaymentStatus();
              },
              child: const Text('Check Again'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Payment'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status Animation
              _buildStatusAnimation(),
              const SizedBox(height: 32),

              // Status Text
              _buildStatusText(),
              const SizedBox(height: 16),

              // Progress Indicator
              _buildProgressIndicator(),
              const SizedBox(height: 32),

              // Payment Details
              _buildPaymentSummary(),
              const SizedBox(height: 32),

              // Instructions
              _buildInstructions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAnimation() {
    Widget animation;
    switch (_currentStatus) {
      case PaymentStatus.pending:
        animation = const SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            strokeWidth: 8,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        );
        break;
      case PaymentStatus.processing:
        animation = Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.access_time,
            color: Colors.orange,
            size: 60,
          ),
        );
        break;
      case PaymentStatus.completed:
        animation = Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 60,
          ),
        );
        break;
      case PaymentStatus.failed:
        animation = Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error,
            color: Colors.red,
            size: 60,
          ),
        );
        break;
      default:
        animation = const SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            strokeWidth: 8,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        );
    }

    return animation;
  }

  Widget _buildStatusText() {
    String title;
    String subtitle;
    Color color;

    switch (_currentStatus) {
      case PaymentStatus.pending:
        title = 'Initiating Payment';
        subtitle = 'Sending payment request to your mobile money provider...';
        color = AppTheme.primaryColor;
        break;
      case PaymentStatus.processing:
        title = 'Confirming Payment';
        subtitle = 'Waiting for payment confirmation from your mobile money provider...';
        color = Colors.orange;
        break;
      case PaymentStatus.completed:
        title = 'Payment Successful!';
        subtitle = 'Your payment has been processed successfully.';
        color = Colors.green;
        break;
      case PaymentStatus.failed:
        title = 'Payment Failed';
        subtitle = 'Your payment could not be processed.';
        color = Colors.red;
        break;
      default:
        title = 'Processing Payment';
        subtitle = 'Please wait while we process your payment...';
        color = AppTheme.primaryColor;
    }

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    if (_currentStatus == PaymentStatus.completed || _currentStatus == PaymentStatus.failed) {
      return const SizedBox.shrink();
    }

    final progress = _checkCount / maxChecks;
    final remainingTime = ((maxChecks - _checkCount) * 5) ~/ 60;

    return Column(
      children: [
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${remainingTime}m remaining',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Payment Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Amount', 'RWF ${widget.payment.amount.toStringAsFixed(0)}'),
            _buildSummaryRow('Method', widget.payment.paymentMethodDisplayName),
            _buildSummaryRow('Phone', widget.payment.phoneNumber ?? 'N/A'),
            _buildSummaryRow('Order ID', widget.payment.orderId),
          ],
        ),
      ),
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
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    if (_currentStatus != PaymentStatus.pending && _currentStatus != PaymentStatus.processing) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Check Your Phone',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You should receive an SMS from ${widget.payment.paymentMethodDisplayName} asking you to confirm the payment. Please check your phone and follow the instructions.',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Details:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Amount: RWF ${widget.payment.amount.toStringAsFixed(0)}'),
          Text('Method: ${widget.payment.paymentMethodDisplayName}'),
          Text('Reference: ${widget.payment.transactionId ?? 'N/A'}'),
          Text('Time: ${widget.payment.createdAt.toString().split('.')[0]}'),
        ],
      ),
    );
  }
}
