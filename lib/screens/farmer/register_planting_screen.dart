import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cooperative_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';

class RegisterPlantingScreen extends StatefulWidget {
  const RegisterPlantingScreen({super.key});

  @override
  State<RegisterPlantingScreen> createState() => _RegisterPlantingScreenState();
}

class _RegisterPlantingScreenState extends State<RegisterPlantingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _seedBatchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _landAreaController = TextEditingController();
  final _expectedYieldController = TextEditingController();
  
  DateTime _purchaseDate = DateTime.now();
  DateTime _plantingDate = DateTime.now();
  DateTime _expectedHarvestDate = DateTime.now().add(const Duration(days: 90));
  
  String? _selectedAgroDealer;
  bool _isLoading = false;

  final List<String> _agroDealers = [
    'Musanze Inputs Ltd',
    'Rwanda Agro Supplies',
    'Eastern Province Seeds',
    'Kigali Agricultural Center',
    'Northern Seeds Cooperative',
  ];

  @override
  void dispose() {
    _seedBatchController.dispose();
    _quantityController.dispose();
    _landAreaController.dispose();
    _expectedYieldController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime initialDate;
    DateTime firstDate;
    DateTime lastDate;

    switch (type) {
      case 'purchase':
        initialDate = _purchaseDate;
        firstDate = DateTime.now().subtract(const Duration(days: 180));
        lastDate = DateTime.now();
        break;
      case 'planting':
        initialDate = _plantingDate;
        firstDate = DateTime.now().subtract(const Duration(days: 30));
        lastDate = DateTime.now().add(const Duration(days: 30));
        break;
      case 'harvest':
        initialDate = _expectedHarvestDate;
        firstDate = DateTime.now().add(const Duration(days: 60));
        lastDate = DateTime.now().add(const Duration(days: 180));
        break;
      default:
        return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'purchase':
            _purchaseDate = picked;
            break;
          case 'planting':
            _plantingDate = picked;
            break;
          case 'harvest':
            _expectedHarvestDate = picked;
            break;
        }
      });
    }
  }

  Future<void> _registerPlanting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAgroDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an agro-dealer'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.id ?? '';

      // Get current cooperative data
      final cooperative = await FirestoreService().getCooperativeByUserId(userId);
      
      if (cooperative == null) {
        throw Exception('Cooperative profile not found');
      }

      // Update cooperative with planting info
      final updatedCooperative = CooperativeModel(
        id: cooperative.id,
        userId: cooperative.userId,
        cooperativeName: cooperative.cooperativeName,
        registrationNumber: cooperative.registrationNumber,
        numberOfMembers: cooperative.numberOfMembers,
        location: cooperative.location,
        contactPerson: cooperative.contactPerson,
        phone: cooperative.phone,
        agroDealerPurchase: AgroDealerPurchase(
          dealerName: _selectedAgroDealer!,
          seedBatch: _seedBatchController.text,
          quantity: double.parse(_quantityController.text),
          purchaseDate: _purchaseDate,
        ),
        plantingInfo: PlantingInfo(
          plantingDate: _plantingDate,
          landArea: double.parse(_landAreaController.text),
          expectedHarvestDate: _expectedHarvestDate,
        ),
        harvestInfo: HarvestInfo(
          expectedQuantity: double.parse(_expectedYieldController.text),
          actualQuantity: null,
          harvestDate: null,
          storageLocation: null,
        ),
        pricePerKg: cooperative.pricePerKg,
        availableForSale: false,
      );

      await FirestoreService().updateCooperative(updatedCooperative);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Planting registered successfully!'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Planting'),
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
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Register your planting to track harvest and enable traceability',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Seed Purchase Section
                    Text(
                      'Seed Purchase Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedAgroDealer,
                      decoration: const InputDecoration(
                        labelText: 'Agro-Dealer *',
                        prefixIcon: Icon(Icons.store),
                        helperText: 'Where you purchased the seeds',
                      ),
                      items: _agroDealers.map((dealer) {
                        return DropdownMenuItem(value: dealer, child: Text(dealer));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedAgroDealer = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _seedBatchController,
                      decoration: const InputDecoration(
                        labelText: 'Seed Batch Number *',
                        hintText: 'e.g., RWA-2024-001',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Batch number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Seed Quantity (kg) *',
                        prefixIcon: Icon(Icons.scale),
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

                    InkWell(
                      onTap: () => _selectDate(context, 'purchase'),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Purchase Date *',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_purchaseDate.day}/${_purchaseDate.month}/${_purchaseDate.year}'),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Planting Section
                    Text(
                      'Planting Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () => _selectDate(context, 'planting'),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Planting Date *',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_plantingDate.day}/${_plantingDate.month}/${_plantingDate.year}'),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _landAreaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Land Area (hectares) *',
                        prefixIcon: Icon(Icons.landscape),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Land area is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () => _selectDate(context, 'harvest'),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Expected Harvest Date *',
                          prefixIcon: Icon(Icons.calendar_today),
                          helperText: 'Typically 90-120 days after planting',
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_expectedHarvestDate.day}/${_expectedHarvestDate.month}/${_expectedHarvestDate.year}'),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _expectedYieldController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Expected Yield (kg) *',
                        prefixIcon: Icon(Icons.agriculture),
                        helperText: 'Estimated harvest quantity',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Expected yield is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Register Button
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
                  onPressed: _isLoading ? null : _registerPlanting,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Register Planting'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
