import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/payment_service.dart';
import '../services/firestore_service.dart';
import '../models/payment_model.dart';
import '../models/order_model.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'payment_processing_screen.dart';

class PaymentScreen extends StatefulWidget {
  final OrderModel order;

  const PaymentScreen({super.key, required this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.mtnMomo;
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill phone number if available
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = authProvider.userModel?.phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      _phoneController.text = phone;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            _buildOrderSummary(),
            const SizedBox(height: 32),

            // Payment Method Selection
            _buildPaymentMethodSelection(),
            const SizedBox(height: 32),

            // Payment Form
            _buildPaymentForm(),
            const SizedBox(height: 32),

            // Terms and Conditions
            _buildTermsAndConditions(),
            const SizedBox(height: 32),

            // Pay Button
            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Order Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Order ID', widget.order.id),
            _buildSummaryRow('Quantity', '${widget.order.quantity} kg'),
            _buildSummaryRow('Variety', widget.order.seedVariety ?? 'N/A'),
            _buildSummaryRow('Quality', widget.order.qualityGrade ?? 'N/A'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'RWF ${widget.order.totalAmount?.toStringAsFixed(0) ?? '0'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Payment Method',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodOption(
              PaymentMethod.mtnMomo,
              'MTN MoMo',
              'Pay with your MTN Mobile Money account',
              'assets/images/mtn_momo.png',
              Colors.yellow,
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodOption(
              PaymentMethod.airtelMoney,
              'Airtel Money',
              'Pay with your Airtel Money account',
              'assets/images/airtel_money.png',
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    PaymentMethod method,
    String title,
    String subtitle,
    String logoPath,
    Color color,
  ) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                method == PaymentMethod.mtnMomo ? Icons.phone_android : Icons.mobile_friendly,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: _selectedMethod,
              onChanged: (value) => setState(() => _selectedMethod = value!),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Mobile Money Phone Number',
                hintText: _selectedMethod == PaymentMethod.mtnMomo
                    ? '078 123 4567'
                    : '073 123 4567',
                prefixIcon: const Icon(Icons.phone),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Phone number is required';
                }
                if (!PaymentService().isValidPhoneNumber(value!, _selectedMethod)) {
                  return 'Invalid phone number for selected payment method';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedMethod == PaymentMethod.mtnMomo
                          ? 'You will receive an SMS from MTN MoMo to confirm the payment of RWF ${widget.order.totalAmount?.toStringAsFixed(0) ?? '0'}.'
                          : 'You will receive an SMS from Airtel Money to confirm the payment of RWF ${widget.order.totalAmount?.toStringAsFixed(0) ?? '0'}.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
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

  Widget _buildTermsAndConditions() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'By proceeding with this payment, you agree to:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildTermItem('Make payment using your registered mobile money account'),
            _buildTermItem('Confirm the payment via SMS prompt from your mobile money provider'),
            _buildTermItem('Ensure sufficient balance in your mobile money account'),
            _buildTermItem('Accept that payments are final and non-refundable'),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                  activeColor: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'I agree to the terms and conditions',
                    style: TextStyle(
                      color: _agreedToTerms ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isProcessing || !_agreedToTerms) ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Pay RWF ${widget.order.totalAmount?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _processPayment() async {
    // Validate form
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    if (!PaymentService().isValidPhoneNumber(_phoneController.text, _selectedMethod)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone number for selected payment method')),
      );
      return;
    }

    if (!PaymentService().isValidAmount(widget.order.totalAmount ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid payment amount')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final paymentService = PaymentService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final request = PaymentRequest(
        phoneNumber: paymentService.formatPhoneNumber(_phoneController.text),
        amount: widget.order.totalAmount ?? 0,
        currency: 'RWF',
        reference: paymentService.generateTransactionReference(widget.order.id),
        description: 'Payment for Order ${widget.order.id}',
      );

      final response = await paymentService.processPayment(_selectedMethod, request);

      if (response.success) {
        // Create payment record in Firestore
        final payment = PaymentModel(
          id: '',
          orderId: widget.order.id,
          payerId: authProvider.userModel?.id ?? '',
          payeeId: widget.order.sellerId,
          amount: widget.order.totalAmount ?? 0,
          currency: 'RWF',
          paymentMethod: _selectedMethod,
          status: PaymentStatus.pending,
          transactionId: response.transactionId,
          phoneNumber: request.phoneNumber,
          createdAt: DateTime.now(),
        );

        await FirestoreService().createPayment(payment);

        // Show success screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PaymentProcessingScreen(
                payment: payment,
                order: widget.order,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: ${response.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
