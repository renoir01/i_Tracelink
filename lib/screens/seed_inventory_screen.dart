import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/seed_batch_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class SeedInventoryScreen extends StatefulWidget {
  const SeedInventoryScreen({super.key});

  @override
  State<SeedInventoryScreen> createState() => _SeedInventoryScreenState();
}

class _SeedInventoryScreenState extends State<SeedInventoryScreen> {
  bool _isLoading = false;
  List<SeedBatchModel> _seedBatches = [];

  @override
  void initState() {
    super.initState();
    _loadSeedInventory();
  }

  Future<void> _loadSeedInventory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userModel?.id ?? '';

    if (userId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final batches = await FirestoreService().getSeedBatchesByProducer(userId);
      setState(() {
        _seedBatches = batches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading inventory: $e')),
        );
      }
    }
  }

  Future<void> _addNewSeedBatch() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddSeedBatchDialog(),
    );

    if (result != null && mounted) {
      await _loadSeedInventory(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seed batch added successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewSeedBatch,
            tooltip: 'Add New Seed Batch',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSeedInventory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _seedBatches.isEmpty
              ? _buildEmptyState()
              : _buildInventoryList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewSeedBatch,
        child: const Icon(Icons.add),
        tooltip: 'Add New Seed Batch',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2,
            size: 80,
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Seed Inventory',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first seed batch to start tracking inventory',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewSeedBatch,
            icon: const Icon(Icons.add),
            label: const Text('Add First Seed Batch'),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _seedBatches.length,
      itemBuilder: (context, index) {
        final batch = _seedBatches[index];
        return _buildSeedBatchCard(batch);
      },
    );
  }

  Widget _buildSeedBatchCard(SeedBatchModel batch) {
    final isLowStock = batch.quantity < 100; // Consider low if less than 100kg
    final isExpiringSoon = batch.expiryDate.difference(DateTime.now()).inDays < 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch ${batch.batchNumber}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        batch.variety,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLowStock || isExpiringSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLowStock ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isLowStock ? 'Low Stock' : 'Expiring Soon',
                      style: TextStyle(
                        color: isLowStock ? Colors.orange : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Quantity',
                    '${batch.quantity} kg',
                    Icons.scale,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Quality',
                    batch.qualityGrade,
                    Icons.verified,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Added',
                    '${batch.productionDate.day}/${batch.productionDate.month}/${batch.productionDate.year}',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Expires',
                    '${batch.expiryDate.day}/${batch.expiryDate.month}/${batch.expiryDate.year}',
                    Icons.event_busy,
                  ),
                ),
              ],
            ),
            if (batch.certificationNumber.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoItem(
                'Certification',
                batch.certificationNumber,
                Icons.medical_services,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editSeedBatch(batch),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteSeedBatch(batch),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(color: AppTheme.errorColor),
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

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editSeedBatch(SeedBatchModel batch) async {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  Future<void> _deleteSeedBatch(SeedBatchModel batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Seed Batch'),
        content: Text('Are you sure you want to delete batch ${batch.batchNumber}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService().deleteSeedBatch(batch.id);
        await _loadSeedInventory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seed batch deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting batch: $e')),
          );
        }
      }
    }
  }
}

class AddSeedBatchDialog extends StatefulWidget {
  const AddSeedBatchDialog({super.key});

  @override
  State<AddSeedBatchDialog> createState() => _AddSeedBatchDialogState();
}

class _AddSeedBatchDialogState extends State<AddSeedBatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _batchNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _certificationController = TextEditingController();

  String _selectedVariety = AppConstants.ironBeanVarieties.first;
  String _selectedQuality = 'Grade A';
  DateTime _productionDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _batchNumberController.dispose();
    _quantityController.dispose();
    _certificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Seed Batch'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _batchNumberController,
                decoration: const InputDecoration(
                  labelText: 'Batch Number *',
                  hintText: 'e.g., SP-2025-001',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Batch number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedVariety,
                decoration: const InputDecoration(labelText: 'Seed Variety *'),
                items: AppConstants.ironBeanVarieties.map((variety) {
                  return DropdownMenuItem(
                    value: variety,
                    child: Text(variety),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedVariety = value!);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity (kg) *',
                  hintText: 'e.g., 500',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Quantity is required';
                  }
                  final quantity = double.tryParse(value!);
                  if (quantity == null || quantity <= 0) {
                    return 'Enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedQuality,
                decoration: const InputDecoration(labelText: 'Quality Grade *'),
                items: ['Grade A', 'Grade B', 'Grade C'].map((grade) {
                  return DropdownMenuItem(
                    value: grade,
                    child: Text(grade),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedQuality = value!);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Production Date'),
                subtitle: Text('${_productionDate.day}/${_productionDate.month}/${_productionDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _productionDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _productionDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('Expiry Date'),
                subtitle: Text('${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (date != null) {
                    setState(() => _expiryDate = date);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _certificationController,
                decoration: const InputDecoration(
                  labelText: 'Certification Number',
                  hintText: 'e.g., RAB-2025-001',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSeedBatch,
          child: const Text('Add Batch'),
        ),
      ],
    );
  }

  Future<void> _saveSeedBatch() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userModel?.id ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final batch = SeedBatchModel(
      id: '',
      producerId: userId,
      batchNumber: _batchNumberController.text.trim(),
      variety: _selectedVariety,
      quantity: double.parse(_quantityController.text),
      qualityGrade: _selectedQuality,
      productionDate: _productionDate,
      expiryDate: _expiryDate,
      certificationNumber: _certificationController.text.trim(),
      status: 'active',
      createdAt: DateTime.now(),
    );

    try {
      await FirestoreService().addSeedBatch(batch);
      if (mounted) {
        Navigator.of(context).pop({
          'batch': batch,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving batch: $e')),
        );
      }
    }
  }
}
