import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_localizations.dart';
import '../notifications_screen.dart';
import '../orders/farmer_orders_screen.dart';
import '../qr/qr_scanner_screen.dart';
import 'register_planting_screen.dart';
import 'harvest_management_screen.dart';
import 'batch_tracking_screen.dart';
import 'earnings_dashboard_screen.dart';

class FarmerDashboardEnhancedScreen extends StatelessWidget {
  const FarmerDashboardEnhancedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userModel = authProvider.userModel;
    final userId = userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dashboard),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(userId),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const QrScannerScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(context, userModel?.email ?? 'Farmer'),
            const SizedBox(height: 16),

            // Overview Statistics
            _buildOverviewStats(context, userId),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context),
            const SizedBox(height: 24),

            // Recent Activity
            Text(
              'Recent Batches',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildRecentBatches(context, userId),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String email) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.agriculture,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('batches')
          .where('farmerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, batchSnapshot) {
        final batches = batchSnapshot.data?.docs ?? [];
        final totalBatches = batches.length;
        final activeBatches = batches.where((b) {
          final data = b.data() as Map<String, dynamic>;
          return data['status'] == 'growing' || data['status'] == 'harvested';
        }).length;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .where('sellerId', isEqualTo: userId)
              .snapshots(),
          builder: (context, transactionSnapshot) {
            final transactions = transactionSnapshot.data?.docs ?? [];
            double totalEarnings = 0;
            for (var doc in transactions) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['paymentStatus'] == 'completed') {
                totalEarnings += (data['totalAmount'] ?? 0).toDouble();
              }
            }

            double totalInventory = 0;
            for (var doc in batches) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['availableForSale'] == true) {
                totalInventory += (data['quantity'] ?? 0).toDouble();
              }
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total Batches',
                        '$totalBatches',
                        Icons.inventory_2,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Active Batches',
                        '$activeBatches',
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total Earnings',
                        'RWF ${totalEarnings.toStringAsFixed(0)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Inventory',
                        '${totalInventory.toStringAsFixed(0)} kg',
                        Icons.warehouse,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Register Harvest',
                Icons.add_circle,
                Colors.green,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RegisterPlantingScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Batch Tracking',
                Icons.qr_code_2,
                Colors.blue,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BatchTrackingScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'My Orders',
                Icons.shopping_cart,
                Colors.orange,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FarmerOrdersScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Earnings',
                Icons.account_balance_wallet,
                Colors.purple,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EarningsDashboardScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBatches(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('batches')
          .where('farmerId', isEqualTo: userId)
          .orderBy('registrationDate', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final batches = snapshot.data?.docs ?? [];

        if (batches.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No batches yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: batches.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(data['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.eco,
                    color: _getStatusColor(data['status']),
                  ),
                ),
                title: Text(
                  data['batchNumber'] ?? 'Batch',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${data['quantity']} kg - ${data['beanVariety'] ?? 'Beans'}',
                ),
                trailing: Chip(
                  label: Text(
                    data['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: _getStatusColor(data['status']).withOpacity(0.2),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'growing':
        return Colors.orange;
      case 'harvested':
        return Colors.green;
      case 'available':
        return Colors.blue;
      case 'sold':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
