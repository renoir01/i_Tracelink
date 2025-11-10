import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import '../../utils/app_theme.dart';
import 'payment_status_screen.dart';

class PaymentTestScreen extends StatefulWidget {
  const PaymentTestScreen({super.key});

  @override
  State<PaymentTestScreen> createState() => _PaymentTestScreenState();
}

class _PaymentTestScreenState extends State<PaymentTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '46733123450'); // Test number
  final _amountController = TextEditingController(text: '1000');
  
  PaymentMethod _selectedMethod = PaymentMethod.mtnMomo;
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Test'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
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
                          SizedBox(width: 12),
                          Text(
                            'Sandbox Testing',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'MTN MoMo Test Numbers:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text('• Success: 46733123450'),
                      const Text('• Failed: 46733123451'),
                      const Text('• Timeout: 46733123452'),
                      const SizedBox(height: 12),
                      const Text(
                        'Use sandbox credentials in .env file',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Payment Method
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildMethodSelector(),
              const SizedBox(height: 24),

              // Phone Number
              const Text(
                'Phone Number',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText: 'Use test number for sandbox',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  if (!PaymentService().isValidPhoneNumber(value, _selectedMethod)) {
                    return 'Invalid phone number for selected method';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Amount
              const Text(
                'Amount (RWF)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: 'RWF',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || !PaymentService().isValidAmount(amount)) {
                    return 'Invalid amount (1 - 1,000,000 RWF)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Process Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Process Test Payment',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Test Buttons
              const Divider(height: 32),
              const Text(
                'Quick Tests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickTestButton(
                    'Success Test',
                    '46733123450',
                    1000,
                    Colors.green,
                  ),
                  _buildQuickTestButton(
                    'Fail Test',
                    '46733123451',
                    2000,
                    Colors.red,
                  ),
                  _buildQuickTestButton(
                    'Timeout Test',
                    '46733123452',
                    3000,
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildMethodCard(
            PaymentMethod.mtnMomo,
            'MTN MoMo',
            Icons.phone_android,
            Colors.yellow.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMethodCard(
            PaymentMethod.airtelMoney,
            'Airtel Money',
            Icons.phone_iphone,
            Colors.red.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCard(
    PaymentMethod method,
    String name,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestButton(
    String label,
    String phone,
    double amount,
    Color color,
  ) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _phoneController.text = phone;
          _amountController.text = amount.toString();
        });
        Future.delayed(const Duration(milliseconds: 100), _processPayment);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
      child: Text(label),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);
      final phone = _phoneController.text;

      // Generate test order ID
      final testOrderId = 'TEST-${DateTime.now().millisecondsSinceEpoch}';

      final result = await PaymentService().createAndProcessPayment(
        orderId: testOrderId,
        payerId: 'test-buyer-id',
        payeeId: 'test-seller-id',
        amount: amount,
        phoneNumber: phone,
        paymentMethod: _selectedMethod,
        description: 'Test Payment - iTraceLink',
      );

      if (mounted) {
        if (result.success) {
          // Navigate to status screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PaymentStatusScreen(
                paymentId: result.paymentId!,
              ),
            ),
          );
        } else {
          _showError(result.message ?? 'Payment failed');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
