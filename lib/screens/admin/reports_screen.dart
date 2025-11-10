import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateReport(String reportType) async {
    setState(() => _isGeneratingReport = true);

    // Simulate report generation
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isGeneratingReport = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$reportType report generated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24.0),
          color: Colors.white,
          child: Row(
            children: [
              Icon(
                Icons.report,
                size: 32,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports & Analytics',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Generate comprehensive reports for system insights',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'User Reports', icon: Icon(Icons.people)),
              Tab(text: 'Transaction Reports', icon: Icon(Icons.receipt_long)),
              Tab(text: 'Quality Reports', icon: Icon(Icons.verified)),
              Tab(text: 'System Reports', icon: Icon(Icons.computer)),
            ],
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUserReportsTab(),
              _buildTransactionReportsTab(),
              _buildQualityReportsTab(),
              _buildSystemReportsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Report Cards
          _buildReportCard(
            'User Registration Report',
            'Comprehensive analysis of user registrations by type, location, and time period',
            Icons.person_add,
            Colors.blue,
            () => _generateReport('User Registration'),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'User Verification Status',
            'Detailed breakdown of verified vs pending users across all categories',
            Icons.verified_user,
            Colors.green,
            () => _generateReport('User Verification Status'),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'User Activity Report',
            'User engagement metrics, login frequency, and platform usage patterns',
            Icons.trending_up,
            Colors.orange,
            () => _generateReport('User Activity'),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'Geographic Distribution',
            'User distribution by district, sector, and regional analysis',
            Icons.location_on,
            Colors.purple,
            () => _generateReport('Geographic Distribution'),
          ),

          const SizedBox(height: 32),

          // Custom Report Builder
          _buildCustomReportSection(),
        ],
      ),
    );
  }

  Widget _buildTransactionReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          _buildReportCard(
            'Order Summary Report',
            'Complete overview of all orders, including status, value, and timelines',
            Icons.receipt_long,
            Colors.green,
            () => _generateReport('Order Summary'),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'Supply Chain Analysis',
            'End-to-end traceability reports for seed-to-consumer journey',
            Icons.timeline,
            Colors.blue,
            () => _generateReport('Supply Chain Analysis'),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'Financial Summary',
            'Revenue analysis, transaction volumes, and financial performance',
            Icons.attach_money,
            Colors.orange,
            () => _generateReport('Financial Summary'),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'Performance Metrics',
            'Order completion rates, processing times, and efficiency metrics',
            Icons.speed,
            Colors.purple,
            () => _generateReport('Performance Metrics'),
          ),

          const SizedBox(height: 32),

          // Transaction Analytics
          _buildTransactionAnalytics(),
        ],
      ),
    );
  }

  Widget _buildQualityReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quality Assurance Reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          _buildReportCard(
            'Seed Quality Report',
            'Certification status, iron content analysis, and quality compliance',
            Icons.science,
            Colors.green,
            () => _generateReport('Seed Quality'),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'Certification Tracking',
            'RAB certification status, expiry dates, and renewal requirements',
            Icons.verified,
            Colors.blue,
            () => _generateReport('Certification Tracking'),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'Quality Control Metrics',
            'Pass/fail rates, defect analysis, and quality improvement trends',
            Icons.verified,
            Colors.orange,
            () => _generateReport('Quality Control Metrics'),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'Compliance Report',
            'Regulatory compliance status and audit trail analysis',
            Icons.gavel,
            Colors.red,
            () => _generateReport('Compliance'),
          ),

          const SizedBox(height: 32),

          // Quality Dashboard
          _buildQualityDashboard(),
        ],
      ),
    );
  }

  Widget _buildSystemReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Administration Reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          _buildReportCard(
            'System Performance',
            'Server performance, response times, and system health metrics',
            Icons.computer,
            Colors.blue,
            () => _generateReport('System Performance'),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'Security Audit Log',
            'User access logs, security events, and threat analysis',
            Icons.security,
            Colors.red,
            () => _generateReport('Security Audit'),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'Data Integrity Report',
            'Database consistency checks and data validation results',
            Icons.storage,
            Colors.green,
            () => _generateReport('Data Integrity'),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'API Usage Analytics',
            'API endpoint usage, error rates, and performance statistics',
            Icons.api,
            Colors.purple,
            () => _generateReport('API Usage'),
          ),

          const SizedBox(height: 32),

          // System Health Overview
          _buildSystemHealthOverview(),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String description, IconData icon, Color color, VoidCallback onGenerate) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isGeneratingReport ? null : onGenerate,
                    icon: _isGeneratingReport
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isGeneratingReport ? 'Generating...' : 'Generate Report'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.schedule),
                  tooltip: 'Schedule Report',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                  tooltip: 'Share Report',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomReportSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Report Builder',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create custom reports with specific parameters and filters',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.build),
                    label: const Text('Build Custom Report'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.history),
                    label: const Text('View Report History'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionAnalytics() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Analytics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsMetric(
                    'Total Transactions',
                    '12,847',
                    Icons.swap_horiz,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsMetric(
                    'Success Rate',
                    '96.8%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsMetric(
                    'Average Value',
                    'RWF 1,970',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityDashboard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quality Dashboard',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsMetric(
                    'Certified Batches',
                    '98.2%',
                    Icons.verified,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsMetric(
                    'Iron Content Avg',
                    '12.8 mg/100g',
                    Icons.science,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnalyticsMetric(
                    'Quality Score',
                    '4.6/5',
                    Icons.star,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealthOverview() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Health Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    'Uptime',
                    '99.9%',
                    Icons.online_prediction,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHealthMetric(
                    'Response Time',
                    '245ms',
                    Icons.speed,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHealthMetric(
                    'Error Rate',
                    '0.1%',
                    Icons.error,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsMetric(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHealthMetric(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
