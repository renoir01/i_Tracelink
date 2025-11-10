import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cooperative_model.dart';
import '../../models/order_model.dart';
import '../../models/aggregator_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

class PlaceOrderScreen extends StatefulWidget {
  final CooperativeModel cooperative;

  const PlaceOrderScreen({
    super.key,
    required this.cooperative,
  });

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDeliveryDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill price if available
    if (widget.cooperative.pricePerKg != null) {
      _priceController.text = widget.cooperative.pricePerKg.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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
      final pricePerKg = double.parse(_priceController.text);

      final order = OrderModel(
        id: '',
        orderType: 'aggregator_to_farmer',
        buyerId: userId,
        sellerId: widget.cooperative.userId,
        quantity: quantity,
        pricePerKg: pricePerKg,
        totalAmount: quantity * pricePerKg,
        requestDate: DateTime.now(),
        expectedDeliveryDate: _selectedDeliveryDate,
        status: 'pending',
        deliveryLocation: widget.cooperative.location,
        paymentStatus: 'pending',
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await FirestoreService().createOrder(order);

      // Send SMS & in-app notification to farmer
      try {
        final aggregator = await FirestoreService().getAggregatorByUserId(userId);
        if (aggregator != null) {
          // SMS notification
          if (widget.cooperative.phone.isNotEmpty) {
            final deliveryDate = '${_selectedDeliveryDate.day}/${_selectedDeliveryDate.month}/${_selectedDeliveryDate.year}';
            
            await SMSService().sendOrderPlacedNotification(
              phoneNumber: widget.cooperative.phone,
              aggregatorName: aggregator.businessName,
              quantity: quantity,
              pricePerKg: pricePerKg,
              deliveryDate: deliveryDate,
            );
            debugPrint('✅ SMS sent to farmer: ${widget.cooperative.phone}');
          }
          
          // In-app notification
          await NotificationService().notifyOrderPlaced(
            userId: widget.cooperative.userId,
            aggregatorName: aggregator.businessName,
            orderId: order.id,
            quantity: quantity,
          );
          debugPrint('✅ In-app notification sent to farmer');
        }
      } catch (e) {
        debugPrint('⚠️ Notification error: $e');
        // Don't block order if notifications fail
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
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
    final harvestInfo = widget.cooperative.harvestInfo;
    final availableQty = harvestInfo?.actualQuantity ?? 0;

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
                    // Cooperative info card
                    Card(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.groups, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.cooperative.cooperativeName,
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
                                  '${widget.cooperative.location.district}, ${widget.cooperative.location.sector}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.people, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.cooperative.numberOfMembers} members',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            if (availableQty > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.inventory, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Available: ${availableQty.round()} kg',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Order form
                    Text(
                      'Order Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity (kg) *',
                        hintText: 'Enter quantity',
                        prefixIcon: const Icon(Icons.scale),
                        suffixText: availableQty > 0 ? 'of ${availableQty.round()}' : null,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Quantity is required';
                        }
                        final qty = double.tryParse(value);
                        if (qty == null || qty <= 0) {
                          return 'Enter a valid quantity';
                        }
                        if (availableQty > 0 && qty > availableQty) {
                          return 'Exceeds available quantity';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price per kg (RWF) *',
                        hintText: 'Enter price',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Price is required';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Enter a valid price';
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
                          labelText: 'Expected Delivery Date *',
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
                        labelText: 'Additional Notes',
                        hintText: 'Enter any special requirements',
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
                              label: 'Price per kg',
                              value: _priceController.text.isEmpty
                                  ? '-'
                                  : 'RWF ${_priceController.text}',
                            ),
                            const Divider(),
                            _SummaryRow(
                              label: 'Total Amount',
                              value: _quantityController.text.isEmpty || _priceController.text.isEmpty
                                  ? '-'
                                  : 'RWF ${(double.tryParse(_quantityController.text) ?? 0) * (double.tryParse(_priceController.text) ?? 0)}',
                              isTotal: true,
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
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
