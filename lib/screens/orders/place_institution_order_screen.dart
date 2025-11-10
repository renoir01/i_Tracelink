import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/aggregator_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart';
import '../../utils/app_theme.dart';

class PlaceInstitutionOrderScreen extends StatefulWidget {
  final AggregatorModel aggregator;

  const PlaceInstitutionOrderScreen({
    super.key,
    required this.aggregator,
  });

  @override
  State<PlaceInstitutionOrderScreen> createState() => _PlaceInstitutionOrderScreenState();
}

class _PlaceInstitutionOrderScreenState extends State<PlaceInstitutionOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDeliveryDate = DateTime.now().add(const Duration(days: 14));
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null && picked != _selectedDeliveryDate) {
      setState(() => _selectedDeliveryDate = picked);
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.id ?? '';

      final quantity = double.parse(_quantityController.text);
      final budget = double.parse(_budgetController.text);
      final pricePerKg = budget / quantity;

      final order = OrderModel(
        id: '',
        orderType: 'institution_to_aggregator',
        buyerId: userId,
        sellerId: widget.aggregator.userId,
        quantity: quantity,
        pricePerKg: pricePerKg,
        totalAmount: budget,
        requestDate: DateTime.now(),
        expectedDeliveryDate: _selectedDeliveryDate,
        status: 'pending',
        deliveryLocation: widget.aggregator.location,
        paymentStatus: 'pending',
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await FirestoreService().createOrder(order);

      // Send SMS notification to aggregator
      if (widget.aggregator.phone.isNotEmpty) {
        try {
          final institution = await FirestoreService().getUserById(userId);
          final institutionName = institution?.email.split('@')[0] ?? 'An institution';
          
          await SMSService().sendNotification(
            phoneNumber: widget.aggregator.phone,
            title: 'New Order from Institution',
            body: '$institutionName placed an order for ${quantity.toStringAsFixed(0)} kg '
                  'at ${pricePerKg.toStringAsFixed(0)} RWF/kg. '
                  'Total: ${budget.toStringAsFixed(0)} RWF. '
                  'Check iTraceLink app for details.',
          );
          debugPrint('✅ SMS sent to aggregator: ${widget.aggregator.phone}');
        } catch (smsError) {
          debugPrint('⚠️ SMS notification failed: $smsError');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
        Navigator.of(context).pop(); // Go back to dashboard
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
        title: const Text('Place Order'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aggregator info card
                    Card(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_shipping, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.aggregator.businessName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.aggregator.location.district}, ${widget.aggregator.location.sector}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            if (widget.aggregator.serviceAreas.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: widget.aggregator.serviceAreas.take(3).map((area) {
                                  return Chip(
                                    label: Text(area),
                                    visualDensity: VisualDensity.compact,
                                    labelStyle: const TextStyle(fontSize: 10),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Order form
                    Text(
                      'Order Requirements',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity Needed (kg) *',
                        hintText: 'e.g., 1000',
                        prefixIcon: Icon(Icons.scale),
                        helperText: 'Monthly or one-time requirement',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Quantity is required';
                        }
                        final qty = double.tryParse(value);
                        if (qty == null || qty <= 0) {
                          return 'Enter a valid quantity';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Budget (RWF) *',
                        hintText: 'e.g., 800000',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Budget is required';
                        }
                        final budget = double.tryParse(value);
                        if (budget == null || budget <= 0) {
                          return 'Enter a valid budget';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Delivery date
                    InkWell(
                      onTap: _selectDeliveryDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Required Delivery Date *',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDeliveryDate.day}/${_selectedDeliveryDate.month}/${_selectedDeliveryDate.year}',
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Special Requirements',
                        hintText: 'Quality specifications, packaging, delivery instructions',
                        prefixIcon: Icon(Icons.note),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Order summary
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Divider(),
                            _SummaryRow(
                              label: 'Quantity',
                              value: _quantityController.text.isEmpty
                                  ? '-'
                                  : '${_quantityController.text} kg',
                            ),
                            _SummaryRow(
                              label: 'Budget',
                              value: _budgetController.text.isEmpty
                                  ? '-'
                                  : 'RWF ${_budgetController.text}',
                            ),
                            _SummaryRow(
                              label: 'Price per kg',
                              value: _quantityController.text.isEmpty || _budgetController.text.isEmpty
                                  ? '-'
                                  : 'RWF ${((double.tryParse(_budgetController.text) ?? 0) / (double.tryParse(_quantityController.text) ?? 1)).round()}',
                            ),
                            const Divider(),
                            _SummaryRow(
                              label: 'Delivery Date',
                              value: '${_selectedDeliveryDate.day}/${_selectedDeliveryDate.month}/${_selectedDeliveryDate.year}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Info card
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: const [
                            Icon(Icons.verified, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Iron-biofortified beans with full traceability',
                                style: TextStyle(fontSize: 12),
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

            // Place order button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _placeOrder,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Place Order'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
