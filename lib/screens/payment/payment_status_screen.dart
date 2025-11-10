import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/payment_model.dart';
import '../../utils/app_theme.dart';

class PaymentStatusScreen extends StatelessWidget {
  final String paymentId;

  const PaymentStatusScreen({
    super.key,
    required this.paymentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .doc(paymentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error.toString());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildErrorState(context, 'Payment not found');
          }

          final payment = PaymentModel.fromMap(
            snapshot.data!.id,
            snapshot.data!.data() as Map<String, dynamic>,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 32),
                
                // Status Icon
                _buildStatusIcon(payment.status),
                const SizedBox(height: 24),

                // Status Text
                Text(
                  payment.statusDisplayName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(payment.status),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Status Message
                Text(
                  _getStatusMessage(payment.status),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Payment Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow('Amount', '${payment.amount.toStringAsFixed(0)} ${payment.currency}'),
                        const Divider(height: 24),
                        _buildDetailRow('Payment Method', payment.paymentMethodDisplayName),
                        const Divider(height: 24),
                        _buildDetailRow('Phone Number', payment.phoneNumber ?? 'N/A'),
                        const Divider(height: 24),
                        _buildDetailRow('Transaction ID', payment.transactionId ?? 'N/A'),
                        if (payment.externalTransactionId != null) ...[
                          const Divider(height: 24),
                          _buildDetailRow('External ID', payment.externalTransactionId!),
                        ],
                        if (payment.failureReason != null) ...[
                          const Divider(height: 24),
                          _buildDetailRow(
                            'Failure Reason',
                            payment.failureReason!,
                            isError: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Timeline Card
                if (payment.status != PaymentStatus.pending)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Timeline',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTimelineItem(
                            'Payment Initiated',
                            payment.createdAt,
                            Icons.schedule,
                            true,
                          ),
                          if (payment.status == PaymentStatus.processing ||
                              payment.status == PaymentStatus.completed ||
                              payment.status == PaymentStatus.failed)
                            _buildTimelineItem(
                              'Processing',
                              payment.createdAt,
                              Icons.sync,
                              true,
                            ),
                          if (payment.status == PaymentStatus.completed)
                            _buildTimelineItem(
                              'Completed',
                              payment.completedAt ?? payment.createdAt,
                              Icons.check_circle,
                              true,
                            ),
                          if (payment.status == PaymentStatus.failed)
                            _buildTimelineItem(
                              'Failed',
                              DateTime.now(),
                              Icons.error,
                              true,
                              isError: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Action Buttons
                if (payment.isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                if (payment.isFailed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Go Back',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                if (payment.isPending || payment.status == PaymentStatus.processing)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text(
                        'Waiting for payment confirmation...',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(PaymentStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case PaymentStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case PaymentStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case PaymentStatus.processing:
        icon = Icons.sync;
        color = Colors.orange;
        break;
      case PaymentStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.grey;
        break;
      default:
        icon = Icons.schedule;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 80, color: color),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.processing:
        return Colors.orange;
      case PaymentStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusMessage(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return 'Your payment has been successfully processed';
      case PaymentStatus.failed:
        return 'Payment was not successful. Please try again';
      case PaymentStatus.processing:
        return 'Your payment is being processed. Please wait...';
      case PaymentStatus.cancelled:
        return 'This payment was cancelled';
      default:
        return 'Waiting for payment confirmation';
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isError ? Colors.red : Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String title,
    DateTime time,
    IconData icon,
    bool isCompleted, {
    bool isError = false,
  }) {
    final color = isError ? Colors.red : (isCompleted ? Colors.green : Colors.grey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                Text(
                  _formatTime(time),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} seconds ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error Loading Payment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
