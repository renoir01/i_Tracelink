import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../utils/app_localizations.dart';

class SeedProducerHelpScreen extends StatefulWidget {
  const SeedProducerHelpScreen({super.key});

  @override
  State<SeedProducerHelpScreen> createState() => _SeedProducerHelpScreenState();
}

class _SeedProducerHelpScreenState extends State<SeedProducerHelpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Getting Started'),
            Tab(text: 'Features Guide'),
            Tab(text: 'Contact Support'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGettingStartedTab(),
          _buildFeaturesGuideTab(),
          _buildContactSupportTab(),
        ],
      ),
    );
  }

  Widget _buildGettingStartedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '🌱 Welcome to iTraceLink - Seed Producer',
            'Your role in the iron-biofortified beans supply chain',
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            'Your Role',
            'As a seed producer, you are the foundation of the iron-biofortified beans supply chain. You produce and distribute certified seeds that ensure nutritional quality from the very beginning.',
            Icons.eco,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            'Getting Started Steps',
            '1. Complete your organization profile\n2. List your authorized agro-dealers\n3. Monitor seed distribution\n4. Track traceability\n5. Manage certifications',
            Icons.checklist,
            Colors.green,
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            'Important Notes',
            '• All seeds must be certified iron-biofortified varieties\n• Only authorize reputable agro-dealers\n• Maintain detailed records of all seed batches\n• Regularly update your inventory\n• Monitor the complete supply chain',
            Icons.info,
            Colors.orange,
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            'Account Verification',
            'Your account will be reviewed by administrators before full access is granted. You will receive SMS notification once verified.',
            Icons.verified_user,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGuideTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '📋 Feature Guide',
            'How to use all available tools',
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            'Manage Seed Inventory',
            'Keep track of your seed stock, varieties, and batches',
            Icons.inventory,
            [
              'Add new seed batches',
              'Update stock quantities',
              'Track expiry dates',
              'Monitor seed varieties (RWR 2245, RWR 2154, etc.)',
              'View low stock alerts',
            ],
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            'Seed Orders Management',
            'Handle orders from agro-dealers and farmers',
            Icons.receipt_long,
            [
              'View incoming orders',
              'Accept or reject orders',
              'Track order status',
              'Manage delivery schedules',
              'Update order fulfillment',
            ],
            Colors.orange,
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            'Verify Traceability',
            'Check the complete supply chain journey',
            Icons.verified,
            [
              'Search by batch number',
              'Search by order ID',
              'View full product journey',
              'Verify actor authenticity',
              'Download traceability reports',
            ],
            Colors.green,
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            'Manage Authorized Dealers',
            'Control who can sell your seeds',
            Icons.business,
            [
              'Add new agro-dealers',
              'Remove unauthorized dealers',
              'View dealer performance',
              'Track seed distribution',
              'Monitor dealer ratings',
            ],
            Colors.blue,
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            'Certifications & Quality',
            'Maintain seed quality standards',
            Icons.medical_services,
            [
              'Upload certification documents',
              'Track certification expiry',
              'Update quality test results',
              'Manage iron content data',
              'Share certificates with buyers',
            ],
            Colors.purple,
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            'Profile Management',
            'Keep your organization information current',
            Icons.account_circle,
            [
              'Update contact information',
              'Change business details',
              'Add team members',
              'Update service areas',
              'Manage payment information',
            ],
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSupportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '📞 Contact Support',
            'Get help when you need it',
          ),
          const SizedBox(height: 16),

          _buildContactCard(
            'Technical Support',
            'For app issues, bugs, or technical problems',
            Icons.computer,
            [
              '📧 Email: support@itracelink.rw',
              '📱 WhatsApp: +250 788 123 456',
              '🕒 Response: Within 24 hours',
            ],
            () => _launchUrl('mailto:support@itracelink.rw'),
          ),
          const SizedBox(height: 16),

          _buildContactCard(
            'Business Support',
            'For business inquiries, partnerships, training',
            Icons.business_center,
            [
              '📧 Email: business@itracelink.rw',
              '📱 Phone: +250 788 654 321',
              '🕒 Business Hours: Mon-Fri 8AM-5PM',
            ],
            () => _launchUrl('mailto:business@itracelink.rw'),
          ),
          const SizedBox(height: 16),

          _buildContactCard(
            'Emergency Support',
            'For urgent issues affecting operations',
            Icons.emergency,
            [
              '📱 Hotline: +250 788 999 999',
              '🕒 24/7 Availability',
              '🚨 Use only for critical issues',
            ],
            () => _launchUrl('tel:+250788999999'),
          ),
          const SizedBox(height: 16),

          _buildContactCard(
            'RAB Partnership',
            'Rwanda Agriculture Board collaboration',
            Icons.agriculture,
            [
              '🌱 Technical seed certification support',
              '📋 Quality assurance guidance',
              '🔬 Lab testing coordination',
              '📊 Market intelligence',
            ],
            () => _launchUrl('https://rab.gov.rw'),
          ),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    'How do I add a new agro-dealer?',
                    'Go to your profile settings and use the "Manage Authorized Dealers" section.',
                  ),
                  _buildFAQItem(
                    'What if my seeds don\'t meet certification standards?',
                    'Contact RAB immediately for guidance on quality improvement.',
                  ),
                  _buildFAQItem(
                    'How do I track seed distribution?',
                    'Use the traceability verification feature to monitor your seeds throughout the supply chain.',
                  ),
                  _buildFAQItem(
                    'What varieties should I produce?',
                    'Focus on iron-biofortified varieties: RWR 2245, RWR 2154, MAC 42, MAC 44.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, List<String> features, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Text('• ', style: TextStyle(color: Colors.green)),
                  Expanded(
                    child: Text(
                      feature,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(String title, String description, IconData icon, List<String> contactInfo, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 12),
              ...contactInfo.map((info) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  info,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q: $question',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A: $answer',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }
}
