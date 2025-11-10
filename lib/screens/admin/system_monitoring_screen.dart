import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class SystemMonitoringScreen extends StatefulWidget {
  const SystemMonitoringScreen({super.key});

  @override
  State<SystemMonitoringScreen> createState() => _SystemMonitoringScreenState();
}

class _SystemMonitoringScreenState extends State<SystemMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

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

  Future<void> _refreshSystemStatus() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isRefreshing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('System status refreshed')),
      );
    }
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
                Icons.monitor_heart,
                size: 32,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Monitoring',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Real-time monitoring of system health and performance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isRefreshing ? null : _refreshSystemStatus,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Refresh Status'),
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
              Tab(text: 'System Health', icon: Icon(Icons.favorite)),
              Tab(text: 'Performance', icon: Icon(Icons.speed)),
              Tab(text: 'Logs & Alerts', icon: Icon(Icons.warning)),
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
              _buildSystemHealthTab(),
              _buildPerformanceTab(),
              _buildLogsAlertsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Health Status',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Overall Health Status
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Status: HEALTHY',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'All systems are operating normally',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: const Text('99.9% Uptime'),
                        backgroundColor: Colors.green.withOpacity(0.1),
                        labelStyle: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Service Status Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildServiceCard(
                'Database',
                'Operational',
                Icons.storage,
                Colors.green,
                'Response: 45ms',
              ),
              _buildServiceCard(
                'Authentication',
                'Operational',
                Icons.security,
                Colors.green,
                'Active sessions: 1,247',
              ),
              _buildServiceCard(
                'SMS Service',
                'Operational',
                Icons.sms,
                Colors.green,
                'Queue: 12 messages',
              ),
              _buildServiceCard(
                'File Storage',
                'Operational',
                Icons.cloud,
                Colors.green,
                'Usage: 67%',
              ),
              _buildServiceCard(
                'API Gateway',
                'Operational',
                Icons.api,
                Colors.green,
                'Requests/min: 234',
              ),
              _buildServiceCard(
                'Email Service',
                'Maintenance',
                Icons.email,
                Colors.orange,
                'Scheduled: 2:00 AM',
              ),
            ],
          ),

          const SizedBox(height: 32),

          // System Resources
          _buildSystemResourcesSection(),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Performance Cards
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'Average Response Time',
                  '245ms',
                  Icons.speed,
                  Colors.blue,
                  '-12% from last week',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceCard(
                  'Requests per Minute',
                  '1,234',
                  Icons.trending_up,
                  Colors.green,
                  '+8% from last week',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceCard(
                  'Error Rate',
                  '0.1%',
                  Icons.error_outline,
                  Colors.orange,
                  '-0.05% from last week',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Performance Charts
          Row(
            children: [
              Expanded(
                child: _buildPerformanceChart(
                  'Response Time Trend',
                  'Average response time over the last 24 hours',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceChart(
                  'Request Volume',
                  'API requests per minute over the last 24 hours',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Slow Queries & Bottlenecks
          _buildBottlenecksSection(),
        ],
      ),
    );
  }

  Widget _buildLogsAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Logs & Alerts',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Active Alerts
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Active Alerts (3)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAlertItem(
                    'High Memory Usage',
                    'Server memory usage is above 85%',
                    'Warning',
                    Colors.orange,
                    '2025-01-30 14:23',
                  ),
                  _buildAlertItem(
                    'Slow Database Query',
                    'User verification query taking >5 seconds',
                    'Warning',
                    Colors.orange,
                    '2025-01-30 13:45',
                  ),
                  _buildAlertItem(
                    'Failed SMS Delivery',
                    '12 SMS messages failed to deliver',
                    'Error',
                    Colors.red,
                    '2025-01-30 12:30',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recent Logs
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list_alt),
                      const SizedBox(width: 8),
                      Text(
                        'Recent System Logs',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All Logs'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLogItem(
                    'INFO',
                    'User verification completed',
                    'user_verification_service',
                    '2025-01-30 15:30:12',
                    Colors.blue,
                  ),
                  _buildLogItem(
                    'INFO',
                    'Seed batch registered successfully',
                    'inventory_service',
                    '2025-01-30 15:28:45',
                    Colors.blue,
                  ),
                  _buildLogItem(
                    'WARN',
                    'Slow query detected: 3.2 seconds',
                    'database_service',
                    '2025-01-30 15:25:33',
                    Colors.orange,
                  ),
                  _buildLogItem(
                    'INFO',
                    'SMS notification sent',
                    'notification_service',
                    '2025-01-30 15:22:18',
                    Colors.blue,
                  ),
                  _buildLogItem(
                    'ERROR',
                    'Payment processing failed',
                    'payment_service',
                    '2025-01-30 15:20:05',
                    Colors.red,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Log Filters
          _buildLogFiltersSection(),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String serviceName, String status, IconData icon, Color color, String details) {
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
                Expanded(
                  child: Text(
                    serviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              details,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemResourcesSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Resources',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResourceMeter(
                    'CPU Usage',
                    67,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResourceMeter(
                    'Memory Usage',
                    82,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResourceMeter(
                    'Storage Usage',
                    45,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(String title, String value, IconData icon, Color color, String change) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(String title, String subtitle) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Performance Chart',
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

  Widget _buildBottlenecksSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Bottlenecks',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBottleneckItem(
              'Database Query Optimization',
              'Several queries are running slower than expected',
              'High',
              Colors.red,
            ),
            _buildBottleneckItem(
              'Image Upload Processing',
              'Large image files taking longer to process',
              'Medium',
              Colors.orange,
            ),
            _buildBottleneckItem(
              'SMS Delivery Queue',
              'Occasional delays in SMS delivery during peak hours',
              'Low',
              Colors.yellow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(String title, String message, String severity, Color color, String timestamp) {
    return Card(
      color: color.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.warning, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(
                  label: Text(severity),
                  backgroundColor: color.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: color,
                    fontSize: 10,
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(String level, String message, String service, String timestamp, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              level,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            service,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            timestamp.split(' ')[1], // Show only time
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogFiltersSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('All Levels'),
                  selected: true,
                  onSelected: (selected) {},
                ),
                FilterChip(
                  label: const Text('Errors Only'),
                  selected: false,
                  onSelected: (selected) {},
                ),
                FilterChip(
                  label: const Text('Warnings'),
                  selected: false,
                  onSelected: (selected) {},
                ),
                FilterChip(
                  label: const Text('Info'),
                  selected: false,
                  onSelected: (selected) {},
                ),
                FilterChip(
                  label: const Text('Last Hour'),
                  selected: false,
                  onSelected: (selected) {},
                ),
                FilterChip(
                  label: const Text('Last 24 Hours'),
                  selected: false,
                  onSelected: (selected) {},
                ),
                FilterChip(
                  label: const Text('Last 7 Days'),
                  selected: false,
                  onSelected: (selected) {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search logs...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Export Logs'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceMeter(String label, int percentage, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildBottleneckItem(String title, String description, String priority, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          priority,
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: color.withOpacity(0.2),
                        labelStyle: TextStyle(color: color),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              tooltip: 'View Details',
            ),
          ],
        ),
      ),
    );
  }
}
