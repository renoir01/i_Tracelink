import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_localizations.dart';
import 'inventory_management_screen.dart';
import 'record_purchase_screen.dart';
import 'sales_tracking_screen.dart';
import 'supplier_management_screen.dart';
import 'trader_financial_dashboard_screen.dart';

/// Entry point for the trader workflow. The module screens existed, but there
/// was no dashboard file for the routes in SplashScreen and LoginScreen to open.
class TraderDashboardScreen extends StatelessWidget {
  const TraderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('traderDashboard')),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.translate('signOut'),
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('welcomeBack'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(user.displayName),
                        const SizedBox(height: 10),
                        Chip(
                          avatar: const Icon(Icons.storefront, size: 18),
                          label: Text(user.isVerified
                              ? AppLocalizations.of(context)!.translate('traderVerified')
                              : AppLocalizations.of(context)!.translate('traderPendingVerification')),
                          backgroundColor: user.isVerified
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _TraderActionTile(
                  icon: Icons.qr_code_scanner,
                  title: AppLocalizations.of(context)!.translate('recordPurchase'),
                  subtitle: AppLocalizations.of(context)!.translate('recordPurchaseDesc'),
                  onTap: () => _open(context, const RecordPurchaseScreen()),
                ),
                _TraderActionTile(
                  icon: Icons.inventory_2_outlined,
                  title: AppLocalizations.of(context)!.translate('inventory'),
                  subtitle: AppLocalizations.of(context)!.translate('inventoryDesc'),
                  onTap: () => _open(context, const InventoryManagementScreen()),
                ),
                _TraderActionTile(
                  icon: Icons.point_of_sale,
                  title: AppLocalizations.of(context)!.translate('salesTracking'),
                  subtitle: AppLocalizations.of(context)!.translate('salesTrackingDesc'),
                  onTap: () => _open(context, const SalesTrackingScreen()),
                ),
                _TraderActionTile(
                  icon: Icons.local_shipping_outlined,
                  title: AppLocalizations.of(context)!.translate('suppliers'),
                  subtitle: AppLocalizations.of(context)!.translate('suppliersDesc'),
                  onTap: () => _open(context, const SupplierManagementScreen()),
                ),
                _TraderActionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: AppLocalizations.of(context)!.translate('financialDashboard'),
                  subtitle: AppLocalizations.of(context)!.translate('financialDashboardDesc'),
                  onTap: () => _open(context, const TraderFinancialDashboardScreen()),
                ),
              ],
            ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _TraderActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TraderActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          foregroundColor: AppTheme.primaryColor,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
