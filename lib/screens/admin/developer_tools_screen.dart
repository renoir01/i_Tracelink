import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../payment/payment_test_screen.dart';

class DeveloperToolsScreen extends StatelessWidget {
  const DeveloperToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Developer/Testing tools - Use in development only',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payment Testing
          _buildSection(
            'Payment Integration',
            [
              _buildToolTile(
                context,
                'Test Payments',
                'Test MTN MoMo & Airtel Money integration',
                Icons.payment,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentTestScreen(),
                  ),
                ),
              ),
              _buildToolTile(
                context,
                'View All Payments',
                'View payment records in Firestore',
                Icons.list_alt,
                Colors.blue,
                () => _viewPayments(context),
              ),
            ],
          ),

          // Database Tools
          _buildSection(
            'Database',
            [
              _buildToolTile(
                context,
                'Collections Stats',
                'View document counts',
                Icons.bar_chart,
                Colors.purple,
                () => _showCollectionStats(context),
              ),
              _buildToolTile(
                context,
                'Clear Test Data',
                'Remove test payments & orders',
                Icons.delete_sweep,
                Colors.red,
                () => _clearTestData(context),
              ),
            ],
          ),

          // System Info
          _buildSection(
            'System Info',
            [
              _buildToolTile(
                context,
                'Environment',
                'View configuration',
                Icons.settings,
                Colors.teal,
                () => _showEnvironmentInfo(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildToolTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _viewPayments(BuildContext context) async {
    final payments = await FirebaseFirestore.instance
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recent Payments'),
        content: SizedBox(
          width: double.maxFinite,
          child: payments.docs.isEmpty
              ? const Center(child: Text('No payments found'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: payments.docs.length,
                  itemBuilder: (context, index) {
                    final data = payments.docs[index].data();
                    return ListTile(
                      title: Text('${data['amount']} ${data['currency']}'),
                      subtitle: Text(data['status'] ?? 'Unknown'),
                      trailing: Text(
                        _formatStatus(data['status']),
                        style: TextStyle(
                          color: _getStatusColor(data['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Unknown';
    return status.split('.').last.toUpperCase();
  }

  Color _getStatusColor(String? status) {
    if (status?.contains('completed') ?? false) return Colors.green;
    if (status?.contains('failed') ?? false) return Colors.red;
    if (status?.contains('processing') ?? false) return Colors.orange;
    return Colors.grey;
  }

  Future<void> _showCollectionStats(BuildContext context) async {
    final stats = <String, int>{};

    try {
      final collections = [
        'users',
        'cooperatives',
        'aggregators',
        'agro_dealers',
        'seed_producers',
        'orders',
        'payments',
        'agro_dealer_sales',
        'farmer_purchases',
        'harvest_notifications',
        'consumer_purchase_requests',
      ];

      for (final collection in collections) {
        final snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .limit(1000)
            .get();
        stats[collection] = snapshot.docs.length;
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Collection Statistics'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: stats.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  trailing: Text(
                    '${entry.value}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _clearTestData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Test Data'),
        content: const Text(
          'This will delete all test payments and orders. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      // Delete test payments
      final payments = await FirebaseFirestore.instance
          .collection('payments')
          .where('orderId', isGreaterThanOrEqualTo: 'TEST-')
          .where('orderId', isLessThan: 'TEST.')
          .get();

      for (final doc in payments.docs) {
        await doc.reference.delete();
      }

      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${payments.docs.length} test records'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showEnvironmentInfo(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Environment Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Mode', 'Development'),
            _buildInfoRow('Payment', 'Sandbox'),
            _buildInfoRow('SMS', 'Active'),
            _buildInfoRow('Firebase', 'Connected'),
            const SizedBox(height: 16),
            const Text(
              'Check .env file for API keys',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
