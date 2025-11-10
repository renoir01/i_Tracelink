import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class BatchTrackingScreen extends StatelessWidget {
  const BatchTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Tracking'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('batches')
            .where('farmerId', isEqualTo: userId)
            .orderBy('registrationDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final batches = snapshot.data?.docs ?? [];

          if (batches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No batches registered yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by registering a new harvest',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final doc = batches[index];
              final data = doc.data() as Map<String, dynamic>;
              final batchId = doc.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _showBatchDetails(context, batchId, data),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['batchNumber'] ?? 'Batch',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['beanVariety'] ?? 'Iron-Biofortified Beans',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusBadge(data['status']),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoTile(
                                'Quantity',
                                '${data['quantity']} kg',
                                Icons.scale,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoTile(
                                'Quality',
                                data['quality']?.toString().toUpperCase() ?? 'N/A',
                                Icons.star,
                              ),
                            ),
                          ],
                        ),
                        if (data['pricePerKg'] != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoTile(
                            'Price',
                            'RWF ${data['pricePerKg']}/kg',
                            Icons.attach_money,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showQRCode(context, batchId, data),
                                icon: const Icon(Icons.qr_code_2, size: 20),
                                label: const Text('View QR Code'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showBatchDetails(context, batchId, data),
                                icon: const Icon(Icons.visibility, size: 20),
                                label: const Text('Details'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'growing':
        color = Colors.orange;
        icon = Icons.trending_up;
        label = 'GROWING';
        break;
      case 'harvested':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'HARVESTED';
        break;
      case 'available':
        color = Colors.blue;
        icon = Icons.store;
        label = 'AVAILABLE';
        break;
      case 'sold':
        color = Colors.grey;
        icon = Icons.done_all;
        label = 'SOLD';
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        label = 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showQRCode(BuildContext context, String batchId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['batchNumber'] ?? 'Batch QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor),
              ),
              child: QrImageView(
                data: batchId,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan this code to verify batch authenticity',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBatchDetails(BuildContext context, String batchId, Map<String, dynamic> data) {
    final registrationDate = (data['registrationDate'] as Timestamp?)?.toDate();
    final harvestDate = (data['harvestDate'] as Timestamp?)?.toDate();
    final plantingDate = (data['plantingDate'] as Timestamp?)?.toDate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                data['batchNumber'] ?? 'Batch Details',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusBadge(data['status']),
              const Divider(height: 32),
              _buildDetailRow('Batch ID', batchId.substring(0, 12)),
              _buildDetailRow('Bean Variety', data['beanVariety'] ?? 'N/A'),
              _buildDetailRow('Quantity', '${data['quantity']} kg'),
              _buildDetailRow('Quality Grade', data['quality']?.toString().toUpperCase() ?? 'N/A'),
              if (data['pricePerKg'] != null)
                _buildDetailRow('Price per kg', 'RWF ${data['pricePerKg']}'),
              if (data['landSize'] != null)
                _buildDetailRow('Land Size', '${data['landSize']} hectares'),
              if (data['ironContent'] != null)
                _buildDetailRow('Iron Content', '${data['ironContent']} mg/100g'),
              if (plantingDate != null)
                _buildDetailRow(
                  'Planting Date',
                  '${plantingDate.day}/${plantingDate.month}/${plantingDate.year}',
                ),
              if (harvestDate != null)
                _buildDetailRow(
                  'Harvest Date',
                  '${harvestDate.day}/${harvestDate.month}/${harvestDate.year}',
                ),
              if (registrationDate != null)
                _buildDetailRow(
                  'Registration Date',
                  '${registrationDate.day}/${registrationDate.month}/${registrationDate.year}',
                ),
              if (data['seedSource'] != null)
                _buildDetailRow('Seed Source', data['seedSource']),
              if (data['storageLocation'] != null)
                _buildDetailRow('Storage', data['storageLocation']),
              if (data['notes'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(data['notes']),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showQRCode(context, batchId, data);
                  },
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('View QR Code'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
