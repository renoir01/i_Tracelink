import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_localizations.dart';
import '../utils/constants.dart';
import 'orders/farmer_orders_screen.dart';
import 'farmer/register_planting_screen.dart';
import 'farmer/harvest_management_screen.dart';
import 'notifications_screen.dart';
import 'seed_producer/seed_distribution_screen.dart';
import 'seed_inventory_screen.dart';
import 'agro_dealer/agro_dealer_sales_screen.dart';
import 'agro_dealer/agro_dealer_inventory_screen.dart';
import 'consumer/consumer_scan_verify_screen.dart';
import 'consumer/purchase_history_screen.dart';
import 'consumer/nutritional_tracking_screen.dart';
import 'consumer/education_center_screen.dart';
import 'orders/institution_orders_screen.dart';
import 'traceability_screen.dart';
import 'profile/cooperative_profile_screen.dart';
import 'profile/aggregator_profile_screen.dart';
import 'profile/seed_producer_profile_screen.dart';
import 'profile/agro_dealer_profile_screen.dart';
import 'profile/institution_profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userModel = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dashboard),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(userModel?.id ?? ''),
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
      body: userModel == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.welcomeBack,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userModel.email,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(_getUserTypeLabel(userModel.userType)),
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Verification Status
                  if (!userModel.isVerified)
                    Card(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: AppTheme.warningColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account Pending Verification',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    'Your account is under review. You will be notified once verified.',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Quick Stats
                  Text(
                    'Quick Stats',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.shopping_bag,
                          label: 'Orders',
                          value: '0',
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.notifications,
                          label: 'Notifications',
                          value: '0',
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(context, userModel.userType),
                ],
              ),
            ),
    );
  }

  String _getUserTypeLabel(String userType) {
    switch (userType) {
      case 'seed_producer':
        return 'Seed Producer';
      case 'agro_dealer':
        return 'Agro-Dealer';
      case 'farmer':
        return 'Farmer Cooperative';
      case 'aggregator':
        return 'Aggregator';
      case 'institution':
        return 'School/Hospital';
      case 'consumer':
        return 'Consumer';
      default:
        return userType;
    }
  }

  Widget _buildQuickActions(BuildContext context, String userType) {
    List<Widget> actions = [];

    // Farmer-specific actions
    if (userType == AppConstants.farmerType) {
      actions.addAll([
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco, color: Colors.green),
            ),
            title: const Text('Register Planting'),
            subtitle: const Text('Record new bean planting'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RegisterPlantingScreen(),
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.agriculture, color: Colors.orange),
            ),
            title: const Text('Harvest Management'),
            subtitle: const Text('Update harvest information'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HarvestManagementScreen(),
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long, color: AppTheme.primaryColor),
            ),
            title: const Text('My Orders'),
            subtitle: const Text('View and respond to orders'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FarmerOrdersScreen(),
                ),
              );
            },
          ),
        ),
      ]);
    }

    // Seed Producer-specific actions
    if (userType == AppConstants.seedProducerType) {
      actions.addAll([
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory, color: AppTheme.primaryColor),
            ),
            title: const Text('Manage Seed Inventory'),
            subtitle: const Text('Update seed stock and varieties'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SeedInventoryScreen(),
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.agriculture, color: Colors.teal),
            ),
            title: const Text('Seed Distribution'),
            subtitle: const Text('Track seed distributions to farmers'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SeedDistributionScreen(),
                ),
              );
            },
          ),
        ),
      ]);
    }

    // Agro-Dealer-specific actions
    if (userType == AppConstants.agroDealerType) {
      actions.addAll([
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory_2, color: AppTheme.primaryColor),
            ),
            title: const Text('Manage Inventory'),
            subtitle: const Text('Update seed stock and varieties'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AgroDealerInventoryScreen(),
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long, color: Colors.orange),
            ),
            title: const Text('Sales Tracking'),
            subtitle: const Text('View and record seed sales'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AgroDealerSalesScreen(),
                ),
              );
            },
          ),
        ),
      ]);
    }

    // Consumer-specific actions
    if (userType == AppConstants.consumerType) {
      actions.addAll([
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history, color: Colors.orange),
            ),
            title: const Text('Purchase History'),
            subtitle: const Text('View your purchases'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PurchaseHistoryScreen(),
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite, color: Colors.green),
            ),
            title: const Text('Nutritional Tracking'),
            subtitle: const Text('Track your iron intake'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NutritionalTrackingScreen(),
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.blue),
            ),
            title: const Text('Education Center'),
            subtitle: const Text('Learn about biofortified beans'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EducationCenterScreen(),
                ),
              );
            },
          ),
        ),
      ]);
    }

    // Institution-specific actions
    if (userType == AppConstants.institutionType) {
      actions.addAll([
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shopping_cart, color: AppTheme.primaryColor),
            ),
            title: const Text('My Orders'),
            subtitle: const Text('View and place orders'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const InstitutionOrdersScreen(),
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified, color: Colors.green),
            ),
            title: const Text('Verify Traceability'),
            subtitle: const Text('Check product supply chain'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TraceabilityScreen(),
                ),
              );
            },
          ),
        ),
      ]);
    }

    // Common actions for all users
    actions.addAll([
      Card(
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
          ),
          title: const Text('Scan & Verify Product'),
          subtitle: const Text('Scan QR code to verify authenticity'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ConsumerScanVerifyScreen(),
              ),
            );
          },
        ),
      ),
      Card(
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_circle, color: Colors.blue),
          ),
          title: const Text('Profile'),
          subtitle: const Text('View and edit your profile'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            _navigateToProfile(context, userType);
          },
        ),
      ),
      Card(
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.help, color: Colors.green),
          ),
          title: const Text('Help & Support'),
          subtitle: const Text('Call: 0780866714'),
          trailing: const Icon(Icons.phone, size: 16),
          onTap: () async {
            final Uri phoneUri = Uri(scheme: 'tel', path: '0780866714');
            if (await canLaunchUrl(phoneUri)) {
              await launchUrl(phoneUri);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not launch phone dialer. Please call 0780866714'),
                  ),
                );
              }
            }
          },
        ),
      ),
    ]);

    return Column(children: actions);
  }

  void _navigateToProfile(BuildContext context, String userType) {
    Widget profileScreen;

    switch (userType) {
      case AppConstants.farmerType:
        profileScreen = const CooperativeProfileScreen();
        break;
      case AppConstants.aggregatorType:
        profileScreen = const AggregatorProfileScreen();
        break;
      case AppConstants.seedProducerType:
        profileScreen = const SeedProducerProfileScreen();
        break;
      case AppConstants.agroDealerType:
        profileScreen = const AgroDealerProfileScreen();
        break;
      case AppConstants.institutionType:
        profileScreen = const InstitutionProfileScreen();
        break;
      case AppConstants.consumerType:
        // For consumer, show a simple message or create a consumer profile screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consumer profile coming soon!')),
        );
        return;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile not available')),
        );
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => profileScreen),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
