import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/app_localizations.dart';
import 'login_screen.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectUserType),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.selectUserType,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _UserTypeCard(
              icon: Icons.agriculture,
              titleKey: 'seedProducer',
              descriptionKey: 'seedProducerDesc',
              userType: AppConstants.seedProducerType,
            ),
            _UserTypeCard(
              icon: Icons.store,
              titleKey: 'agroDealer',
              descriptionKey: 'agroDealerDesc',
              userType: AppConstants.agroDealerType,
            ),
            _UserTypeCard(
              icon: Icons.groups,
              titleKey: 'farmerCooperative',
              descriptionKey: 'farmerCooperativeDesc',
              userType: AppConstants.farmerType,
            ),
            _UserTypeCard(
              icon: Icons.local_shipping,
              titleKey: 'aggregator',
              descriptionKey: 'aggregatorDesc',
              userType: AppConstants.aggregatorType,
            ),
            _UserTypeCard(
              icon: Icons.business,
              titleKey: 'institution',
              descriptionKey: 'institutionDesc',
              userType: AppConstants.institutionType,
            ),
            const SizedBox(height: 24),
            // Admin Login Button
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/admin-login');
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Admin Login'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  side: BorderSide(color: AppTheme.primaryColor),
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  final String userType;

  const _UserTypeCard({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LoginScreen(userType: userType),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate(titleKey),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.translate(descriptionKey),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
