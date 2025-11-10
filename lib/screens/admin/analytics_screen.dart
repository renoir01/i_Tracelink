import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      // Load various analytics data
      final userStats = await FirestoreService().getUserStatistics();
      final orderStats = await _getOrderStatistics();
      final seedStats = await _getSeedStatistics();

      setState(() {
        _analyticsData = {
          'userStats': userStats,
          'orderStats': orderStats,
          'seedStats': seedStats,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getOrderStatistics() async {
    // Placeholder - in real implementation, this would query orders collection
    return {
      'totalOrders': 1247,
      'completedOrders': 982,
      'pendingOrders': 156,
      'cancelledOrders': 109,
      'totalValue': 2456780, // RWF
    };
  }

  Future<Map<String, dynamic>> _getSeedStatistics() async {
    // Placeholder - in real implementation, this would query seed batches
    return {
      'totalBatches': 456,
      'totalQuantity': 125000, // kg
      'varieties': {
        'RWR 2245': 180,
        'RWR 2154': 145,
        'MAC 42': 89,
        'MAC 44': 42,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with refresh
        Container(
          padding: const EdgeInsets.all(24.0),
          color: Colors.white,
          child: Row(
            children: [
              Icon(
                Icons.analytics,
                size: 32,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Comprehensive insights into system performance and usage',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadAnalyticsData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Data'),
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
              Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
              Tab(text: 'Users', icon: Icon(Icons.people)),
              Tab(text: 'Operations', icon: Icon(Icons.business)),
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
              _buildOverviewTab(),
              _buildUsersTab(),
              _buildOperationsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final userStats = _analyticsData['userStats'] as Map<String, int>? ?? {};
    final orderStats = _analyticsData['orderStats'] as Map<String, dynamic>? ?? {};
    final seedStats = _analyticsData['seedStats'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Users',
                  userStats['total']?.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                  '+12% from last month',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Orders',
                  orderStats['totalOrders']?.toString() ?? '0',
                  Icons.receipt_long,
                  Colors.green,
                  '+8% from last week',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Seed Batches',
                  seedStats['totalBatches']?.toString() ?? '0',
                  Icons.eco,
                  Colors.orange,
                  '456 active batches',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Charts Row
          Row(
            children: [
              Expanded(
                child: _buildUserTypeChart(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOrderStatusChart(),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Trends
          _buildTrendsSection(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final userStats = _analyticsData['userStats'] as Map<String, int>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // User Statistics Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDetailedMetricCard(
                'Seed Producers',
                '89',
                Icons.eco,
                Colors.green,
                '67% verified',
              ),
              _buildDetailedMetricCard(
                'Agro-Dealers',
                '156',
                Icons.store,
                Colors.blue,
                '72% verified',
              ),
              _buildDetailedMetricCard(
                'Farmers',
                '1247',
                Icons.agriculture,
                Colors.orange,
                '58% verified',
              ),
              _buildDetailedMetricCard(
                'Aggregators',
                '234',
                Icons.local_shipping,
                Colors.purple,
                '81% verified',
              ),
              _buildDetailedMetricCard(
                'Institutions',
                '121',
                Icons.school,
                Colors.teal,
                '95% verified',
              ),
              _buildDetailedMetricCard(
                'Total Pending',
                userStats['pending']?.toString() ?? '0',
                Icons.pending,
                Colors.red,
                'Awaiting verification',
              ),
            ],
          ),
          const SizedBox(height: 32),

          // User Registration Trends
          _buildUserRegistrationChart(),
          const SizedBox(height: 32),

          // User Activity
          _buildUserActivitySection(),
        ],
      ),
    );
  }

  Widget _buildOperationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final orderStats = _analyticsData['orderStats'] as Map<String, dynamic>? ?? {};
    final seedStats = _analyticsData['seedStats'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operations Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Operations Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Completed Orders',
                  orderStats['completedOrders']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                  '78.8% completion rate',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Seed Volume',
                  '${(seedStats['totalQuantity'] as int? ?? 0) ~/ 1000}t',
                  Icons.scale,
                  Colors.orange,
                  '125 tons tracked',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Active Batches',
                  seedStats['totalBatches']?.toString() ?? '0',
                  Icons.inventory,
                  Colors.blue,
                  '456 batches monitored',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Seed Variety Distribution
          _buildSeedVarietyChart(),
          const SizedBox(height: 32),

          // Order Performance
          _buildOrderPerformanceSection(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'User Distribution Chart\n(Charts coming soon)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Status Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Order Status Chart\n(Charts coming soon)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Trends',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Monthly Trends Chart\n(Charts coming soon)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'User registrations over the last 7 months',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRegistrationChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Registration Trends',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'User Registration Trends\n(Charts coming soon)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserActivitySection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Activity Insights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              'Most Active User Type',
              'Farmers (75% of total users)',
              Icons.trending_up,
              Colors.green,
            ),
            _buildActivityItem(
              'Highest Verification Rate',
              'Institutions (95% verified)',
              Icons.verified,
              Colors.blue,
            ),
            _buildActivityItem(
              'Fastest Growing Segment',
              'Agro-Dealers (+15% monthly)',
              Icons.show_chart,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedVarietyChart() {
    final seedStats = _analyticsData['seedStats'] as Map<String, dynamic>? ?? {};
    final varieties = seedStats['varieties'] as Map<String, int>? ?? {};

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seed Variety Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...varieties.entries.map((entry) {
              final percentage = (entry.value / (seedStats['totalBatches'] as int? ?? 1) * 100).round();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text('${entry.value} batches'),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: entry.value / (varieties.values.reduce((a, b) => a > b ? a : b)),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$percentage%'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderPerformanceSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Performance Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    'Average Order Value',
                    'RWF 1,970',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceMetric(
                    'Average Processing Time',
                    '2.3 days',
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceMetric(
                    'Customer Satisfaction',
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

  Widget _buildActivityItem(String title, String value, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(value),
    );
  }

  Widget _buildPerformanceMetric(String title, String value, IconData icon, Color color) {
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
