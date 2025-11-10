import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import 'traceability_chain_screen.dart';
import '../qr_scanner_screen.dart';

class VerifyTraceabilityScreen extends StatefulWidget {
  const VerifyTraceabilityScreen({super.key});

  @override
  State<VerifyTraceabilityScreen> createState() => _VerifyTraceabilityScreenState();
}

class _VerifyTraceabilityScreenState extends State<VerifyTraceabilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _orderIdController.dispose();
    super.dispose();
  }

  Future<void> _verifyTraceability() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderId = _orderIdController.text.trim();
      
      // Get order from Firestore
      final orderSnapshot = await FirestoreService().getOrderById(orderId);
      
      if (orderSnapshot == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order not found. Please check the ID and try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Navigate to chain visualization
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TraceabilityChainScreen(order: orderSnapshot),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Traceability'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.verified_user,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Track Your Beans',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Verify the complete journey from seed to table',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Order ID Input
              TextFormField(
                controller: _orderIdController,
                decoration: const InputDecoration(
                  labelText: 'Order ID or Batch Number',
                  hintText: 'Enter the ID to track',
                  prefixIcon: Icon(Icons.qr_code),
                  helperText: 'Found on your delivery receipt or packaging',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an Order ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Verify Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _verifyTraceability,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? 'Verifying...' : 'Verify'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),

              // OR Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[400])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400])),
                ],
              ),
              const SizedBox(height: 16),

              // Scan QR Code Button
              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const QRScannerScreen(),
                          ),
                        );
                      },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR Code'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
              const SizedBox(height: 32),

              // Info Cards
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'What You\'ll See',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.eco,
                        text: 'Seed producer and variety details',
                      ),
                      _InfoRow(
                        icon: Icons.store,
                        text: 'Agro-dealer who supplied the seeds',
                      ),
                      _InfoRow(
                        icon: Icons.groups,
                        text: 'Farmer cooperative that grew the beans',
                      ),
                      _InfoRow(
                        icon: Icons.local_shipping,
                        text: 'Aggregator who collected and distributed',
                      ),
                      _InfoRow(
                        icon: Icons.verified,
                        text: 'Iron content and quality certifications',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Iron Info Card
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Iron-Biofortified Beans',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'These beans contain 60-90mg of iron per 100g, helping combat iron deficiency.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
