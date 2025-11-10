import 'package:flutter/material.dart';
import '../../models/cooperative_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';

class UpdateHarvestScreen extends StatefulWidget {
  final CooperativeModel cooperative;

  const UpdateHarvestScreen({
    super.key,
    required this.cooperative,
  });

  @override
  State<UpdateHarvestScreen> createState() => _UpdateHarvestScreenState();
}

class _UpdateHarvestScreenState extends State<UpdateHarvestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualQuantityController = TextEditingController();
  final _storageLocationController = TextEditingController();
  final _priceController = TextEditingController();
  
  DateTime _harvestDate = DateTime.now();
  String _qualityGrade = 'A';
  bool _availableForSale = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if harvest already exists
    if (widget.cooperative.harvestInfo?.actualQuantity != null) {
      _actualQuantityController.text = widget.cooperative.harvestInfo!.actualQuantity.toString();
      if (widget.cooperative.harvestInfo!.harvestDate != null) {
        _harvestDate = widget.cooperative.harvestInfo!.harvestDate!;
      }
      if (widget.cooperative.harvestInfo!.storageLocation != null) {
        _storageLocationController.text = widget.cooperative.harvestInfo!.storageLocation!;
      }
    }
    if (widget.cooperative.pricePerKg != null) {
      _priceController.text = widget.cooperative.pricePerKg.toString();
    }
  }

  @override
  void dispose() {
    _actualQuantityController.dispose();
    _storageLocationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectHarvestDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      firstDate: widget.cooperative.plantingInfo!.plantingDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _harvestDate = picked);
    }
  }

  Future<void> _updateHarvest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedCooperative = CooperativeModel(
        id: widget.cooperative.id,
        userId: widget.cooperative.userId,
        cooperativeName: widget.cooperative.cooperativeName,
        registrationNumber: widget.cooperative.registrationNumber,
        numberOfMembers: widget.cooperative.numberOfMembers,
        location: widget.cooperative.location,
        contactPerson: widget.cooperative.contactPerson,
        phone: widget.cooperative.phone,
        agroDealerPurchase: widget.cooperative.agroDealerPurchase,
        plantingInfo: widget.cooperative.plantingInfo,
        harvestInfo: HarvestInfo(
          expectedQuantity: widget.cooperative.harvestInfo?.expectedQuantity ?? 0,
          actualQuantity: double.parse(_actualQuantityController.text),
          harvestDate: _harvestDate,
          storageLocation: _storageLocationController.text.isNotEmpty 
              ? _storageLocationController.text 
              : null,
        ),
        pricePerKg: _priceController.text.isNotEmpty 
            ? double.parse(_priceController.text) 
            : null,
        availableForSale: _availableForSale,
      );

      await FirestoreService().updateCooperative(updatedCooperative);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harvest updated successfully!'),
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
    final expectedQuantity = widget.cooperative.harvestInfo?.expectedQuantity ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Harvest'),
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
                    // Info Card
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Expected yield: ${expectedQuantity.round()} kg',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Harvest Information
                    Text(
                      'Harvest Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: _selectHarvestDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Harvest Date *',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_harvestDate.day}/${_harvestDate.month}/${_harvestDate.year}'),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _actualQuantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Actual Quantity Harvested (kg) *',
                        prefixIcon: const Icon(Icons.scale),
                        suffixText: 'kg',
                        helperText: 'Expected: ${expectedQuantity.round()} kg',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Quantity is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _qualityGrade,
                      decoration: const InputDecoration(
                        labelText: 'Quality Grade',
                        prefixIcon: Icon(Icons.grade),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'A', child: Text('Grade A - Premium')),
                        DropdownMenuItem(value: 'B', child: Text('Grade B - Standard')),
                        DropdownMenuItem(value: 'C', child: Text('Grade C - Basic')),
                      ],
                      onChanged: (value) {
                        setState(() => _qualityGrade = value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _storageLocationController,
                      decoration: const InputDecoration(
                        labelText: 'Storage Location',
                        prefixIcon: Icon(Icons.warehouse),
                        hintText: 'e.g., Cooperative warehouse, Cell X',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sales Information
                    Text(
                      'Sales Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price per kg (RWF)',
                        prefixIcon: Icon(Icons.attach_money),
                        hintText: 'Your selling price',
                      ),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Available for Sale'),
                      subtitle: const Text('List your beans for aggregators to purchase'),
                      value: _availableForSale,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (value) {
                        setState(() => _availableForSale = value);
                      },
                    ),

                    if (_availableForSale) ...[
                      const SizedBox(height: 16),
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
                                    'Sales Listing',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your beans will be visible to aggregators. They can place orders and you will receive notifications.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Save Button
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
                  onPressed: _isLoading ? null : _updateHarvest,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Harvest Information'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
