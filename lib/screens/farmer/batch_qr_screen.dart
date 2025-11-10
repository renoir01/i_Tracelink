import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/cooperative_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/qr_generator.dart';

class BatchQRScreen extends StatefulWidget {
  const BatchQRScreen({super.key});

  @override
  State<BatchQRScreen> createState() => _BatchQRScreenState();
}

class _BatchQRScreenState extends State<BatchQRScreen> {
  CooperativeModel? _cooperative;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCooperative();
  }

  Future<void> _loadCooperative() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userModel?.id ?? '';
    
    try {
      final coop = await FirestoreService().getCooperativeByUserId(userId);
      setState(() {
        _cooperative = coop;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch QR Codes'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cooperative == null || _cooperative!.harvestInfo?.actualQuantity == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No harvest recorded yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Record your harvest first to generate QR codes',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _buildQRContent(),
    );
  }

  Widget _buildQRContent() {
    final batchId = _cooperative!.id;
    final cooperativeName = _cooperative!.cooperativeName;
    final variety = _cooperative!.agroDealerPurchase?.seedBatch ?? 'Unknown';
    final harvestDate = _cooperative!.harvestInfo?.harvestDate;
    final productionDate = harvestDate != null
        ? '${harvestDate.day}/${harvestDate.month}/${harvestDate.year}'
        : 'N/A';

    final qrData = QRGenerator.generateBatchQR(
      batchId: batchId,
      producerName: cooperativeName,
      variety: variety,
      productionDate: productionDate,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
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
                        'Batch Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _InfoRow(label: 'Batch ID', value: batchId),
                  _InfoRow(label: 'Producer', value: cooperativeName),
                  _InfoRow(label: 'Variety', value: variety),
                  _InfoRow(label: 'Harvest Date', value: productionDate),
                  _InfoRow(
                    label: 'Quantity',
                    value: '${(_cooperative!.harvestInfo!.actualQuantity ?? 0).toStringAsFixed(0)} kg',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // QR Code Display
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Batch QR Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QRGenerator.buildQRWidget(
                      data: qrData,
                      size: 250,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scan to verify authenticity',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _printSingleQR(qrData),
              icon: const Icon(Icons.print),
              label: const Text('Print QR Code Label'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _printMultipleLabels(qrData),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print Multiple Labels'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showQRInstructions(),
              icon: const Icon(Icons.help_outline),
              label: const Text('How to Use QR Codes'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printSingleQR(String qrData) async {
    try {
      await QRGenerator.printQRCode(
        data: qrData,
        title: 'iTraceLink Batch QR Code',
        subtitle: _cooperative!.cooperativeName,
        additionalInfo: [
          'Batch ID: ${_cooperative!.id}',
          'Variety: ${_cooperative!.agroDealerPurchase?.seedBatch ?? "Unknown"}',
          'Quantity: ${(_cooperative!.harvestInfo!.actualQuantity ?? 0).toStringAsFixed(0)} kg',
          'Harvest Date: ${_cooperative!.harvestInfo!.harvestDate != null ? "${_cooperative!.harvestInfo!.harvestDate!.day}/${_cooperative!.harvestInfo!.harvestDate!.month}/${_cooperative!.harvestInfo!.harvestDate!.year}" : "N/A"}',
        ],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: $e')),
        );
      }
    }
  }

  Future<void> _printMultipleLabels(String qrData) async {
    final count = await showDialog<int>(
      context: context,
      builder: (context) => _PrintCountDialog(),
    );

    if (count == null) return;

    try {
      final items = List.generate(
        count,
        (index) => {
          'data': qrData,
          'title': _cooperative!.cooperativeName,
          'subtitle': 'Batch ${index + 1} of $count',
        },
      );

      await QRGenerator.printMultipleQRCodes(
        items: items,
        headerTitle: 'Batch QR Codes - ${_cooperative!.cooperativeName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: $e')),
        );
      }
    }
  }

  void _showQRInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use QR Codes'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'QR codes help verify the authenticity and trace the origin of your beans.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. Print QR code labels'),
              Text('2. Attach labels to your bean packages'),
              Text('3. Consumers can scan with iTraceLink app'),
              Text('4. They see your batch details & verify authenticity'),
              SizedBox(height: 16),
              Text(
                'Benefits:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Builds consumer trust'),
              Text('• Prevents counterfeiting'),
              Text('• Shows your quality standards'),
              Text('• Increases market value'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PrintCountDialog extends StatefulWidget {
  @override
  State<_PrintCountDialog> createState() => _PrintCountDialogState();
}

class _PrintCountDialogState extends State<_PrintCountDialog> {
  int _count = 10;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Print Multiple Labels'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How many labels do you want to print?'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _count > 1 ? () => setState(() => _count--) : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_count',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _count < 100 ? () => setState(() => _count++) : null,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _count),
          child: const Text('Print'),
        ),
      ],
    );
  }
}
