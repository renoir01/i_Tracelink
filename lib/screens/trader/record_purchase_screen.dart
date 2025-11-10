import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class RecordPurchaseScreen extends StatefulWidget {
  const RecordPurchaseScreen({super.key});

  @override
  State<RecordPurchaseScreen> createState() => _RecordPurchaseScreenState();
}

class _RecordPurchaseScreenState extends State<RecordPurchaseScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;
  String? scannedBatchId;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!isProcessing && scanData.code != null) {
        setState(() {
          isProcessing = true;
          scannedBatchId = scanData.code;
        });

        await controller.pauseCamera();
        await _processBatch(scanData.code!);
      }
    });
  }

  Future<void> _processBatch(String batchId) async {
    try {
      // Fetch batch information
      final batchDoc = await FirebaseFirestore.instance
          .collection(AppConstants.batchesCollection)
          .doc(batchId)
          .get();

      if (!batchDoc.exists) {
        if (mounted) {
          _showError('Batch not found in system');
        }
        return;
      }

      final batchData = batchDoc.data() as Map<String, dynamic>;

      // Check if batch is available for purchase
      if (batchData['status'] != 'available' && batchData['status'] != 'harvested') {
        if (mounted) {
          _showError('This batch is not available for purchase');
        }
        return;
      }

      // Show purchase form
      if (mounted) {
        await _showPurchaseForm(batchId, batchData);
      }
    } catch (e) {
      if (mounted) {
        _showError('Error processing batch: $e');
      }
    } finally {
      setState(() => isProcessing = false);
      controller?.resumeCamera();
    }
  }

  Future<void> _showPurchaseForm(String batchId, Map<String, dynamic> batchData) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PurchaseFormScreen(
          batchId: batchId,
          batchData: batchData,
        ),
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isProcessing = false);
              controller?.resumeCamera();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Purchase'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan Farmer Batch QR Code',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan the batch QR code to record purchase details',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // QR Scanner
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: AppTheme.primaryColor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
              ),
            ),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isProcessing) ...[
                      const CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Processing batch...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Scan batch QR code to purchase',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Purchase Form Screen
class _PurchaseFormScreen extends StatefulWidget {
  final String batchId;
  final Map<String, dynamic> batchData;

  const _PurchaseFormScreen({
    required this.batchId,
    required this.batchData,
  });

  @override
  State<_PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<_PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _storageController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedQuality = 'A';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill available quantity
    _quantityController.text = widget.batchData['quantity'].toString();
  }

  Future<void> _submitPurchase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.id ?? '';
      final quantity = double.parse(_quantityController.text);
      final pricePerKg = double.parse(_priceController.text);
      final totalAmount = quantity * pricePerKg;

      // Create inventory record
      await FirebaseFirestore.instance
          .collection('inventory')
          .add({
        'traderId': userId,
        'batchId': widget.batchId,
        'batchNumber': widget.batchData['batchNumber'],
        'beanVariety': widget.batchData['beanVariety'],
        'quantityAvailable': quantity,
        'quantityPurchased': quantity,
        'quantitySold': 0,
        'purchasePricePerKg': pricePerKg,
        'purchaseDate': Timestamp.now(),
        'supplierId': widget.batchData['farmerId'],
        'supplierName': widget.batchData['cooperativeName'],
        'storageLocation': _storageController.text,
        'status': 'in_stock',
        'quality': _selectedQuality,
        'ironContent': widget.batchData['ironContent'] ?? 80.0,
        'notes': _notesController.text,
      });

      // Create transaction record
      await FirebaseFirestore.instance
          .collection(AppConstants.transactionsCollection)
          .add({
        'type': 'purchase',
        'sellerId': widget.batchData['farmerId'],
        'sellerName': widget.batchData['cooperativeName'],
        'buyerId': userId,
        'buyerName': authProvider.userModel?.email ?? 'Trader',
        'batchId': widget.batchId,
        'batchNumber': widget.batchData['batchNumber'],
        'quantity': quantity,
        'pricePerKg': pricePerKg,
        'totalAmount': totalAmount,
        'transactionDate': Timestamp.now(),
        'paymentStatus': 'pending',
        'location': {},
        'status': 'completed',
      });

      // Update batch status
      await FirebaseFirestore.instance
          .collection(AppConstants.batchesCollection)
          .doc(widget.batchId)
          .update({
        'status': 'sold',
        'availableForSale': false,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording purchase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableQty = widget.batchData['quantity'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Batch Info Card
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Batch Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildInfoRow('Batch Number', widget.batchData['batchNumber']),
                      _buildInfoRow('Variety', widget.batchData['beanVariety']),
                      _buildInfoRow('Available', '$availableQty kg'),
                      _buildInfoRow('Farmer', widget.batchData['cooperativeName']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Purchase Form
              Text(
                'Purchase Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity (kg)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.scale),
                  suffixText: 'kg',
                  helperText: 'Max: $availableQty kg',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  final qty = double.tryParse(value);
                  if (qty == null || qty <= 0) {
                    return 'Enter valid quantity';
                  }
                  if (qty > availableQty) {
                    return 'Cannot exceed available quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price per kg
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per kg (RWF)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'RWF',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Enter valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quality Grade
              DropdownButtonFormField<String>(
                value: _selectedQuality,
                decoration: const InputDecoration(
                  labelText: 'Quality Grade',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                ),
                items: ['A', 'B', 'C'].map((quality) {
                  return DropdownMenuItem(
                    value: quality,
                    child: Text('Grade $quality'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedQuality = value!);
                },
              ),
              const SizedBox(height: 16),

              // Storage Location
              TextFormField(
                controller: _storageController,
                decoration: const InputDecoration(
                  labelText: 'Storage Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warehouse),
                  hintText: 'e.g., Warehouse A, Section 3',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter storage location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Additional details...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Total Amount Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'RWF ${_calculateTotal()}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitPurchase,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isSubmitting ? 'Recording...' : 'Record Purchase',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _calculateTotal() {
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return (qty * price).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _storageController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
