import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class InventoryManagementScreen extends StatelessWidget {
  const InventoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('inventory')
            .where('traderId', isEqualTo: userId)
            .orderBy('purchaseDate', descending: true)
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

          final inventory = snapshot.data?.docs ?? [];

          if (inventory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No inventory yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by recording purchases',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Calculate summary stats
          double totalValue = 0;
          double totalQuantity = 0;
          int lowStockCount = 0;

          for (var doc in inventory) {
            final data = doc.data() as Map<String, dynamic>;
            final qty = (data['quantityAvailable'] ?? 0).toDouble();
            final price = (data['sellingPricePerKg'] ?? data['purchasePricePerKg'] ?? 0).toDouble();
            totalQuantity += qty;
            totalValue += qty * price;

            // Check low stock
            final purchased = (data['quantityPurchased'] ?? 0).toDouble();
            if (qty < purchased * 0.2) {
              lowStockCount++;
            }
          }

          return Column(
            children: [
              // Summary Cards
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Stock',
                        '${totalQuantity.toStringAsFixed(0)} kg',
                        Icons.inventory_2,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Value',
                        'RWF ${totalValue.toStringAsFixed(0)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Low Stock',
                        '$lowStockCount items',
                        Icons.warning,
                        lowStockCount > 0 ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Inventory List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: inventory.length,
                  itemBuilder: (context, index) {
                    return _buildInventoryCard(context, inventory[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final qtyAvailable = (data['quantityAvailable'] ?? 0).toDouble();
    final qtyPurchased = (data['quantityPurchased'] ?? 0).toDouble();
    final qtySold = (data['quantitySold'] ?? 0).toDouble();
    final purchasePrice = (data['purchasePricePerKg'] ?? 0).toDouble();
    final sellingPrice = data['sellingPricePerKg']?.toDouble();
    final status = data['status'] ?? 'in_stock';
    final quality = data['quality'] ?? 'A';

    final isLowStock = qtyAvailable < qtyPurchased * 0.2;
    final stockPercentage = qtyPurchased > 0 ? (qtyAvailable / qtyPurchased * 100) : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showInventoryDetails(context, doc.id, data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: _getStatusColor(status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        Text(
                          data['beanVariety'] ?? 'Beans',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getQualityColor(quality).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Grade $quality',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getQualityColor(quality),
                          ),
                        ),
                      ),
                      if (isLowStock) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'LOW STOCK',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),

              // Stock Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stock Level',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${stockPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isLowStock ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stockPercentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLowStock ? Colors.orange : Colors.green,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Details Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Available',
                      '${qtyAvailable.toStringAsFixed(0)} kg',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Sold',
                      '${qtySold.toStringAsFixed(0)} kg',
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Buy Price',
                      'RWF $purchasePrice/kg',
                      Icons.arrow_downward,
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Sell Price',
                      sellingPrice != null ? 'RWF $sellingPrice/kg' : 'Not set',
                      Icons.arrow_upward,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Supplier Info
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    data['supplierName'] ?? 'Unknown Supplier',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.warehouse, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    data['storageLocation'] ?? 'No location',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_stock':
        return Colors.green;
      case 'low_stock':
        return Colors.orange;
      case 'out_of_stock':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showInventoryDetails(BuildContext context, String docId, Map<String, dynamic> data) {
    final purchaseDate = (data['purchaseDate'] as Timestamp?)?.toDate();

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
                data['batchNumber'] ?? 'Inventory Details',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 32),
              _buildDetailRow('Batch Number', data['batchNumber'] ?? 'N/A'),
              _buildDetailRow('Bean Variety', data['beanVariety'] ?? 'N/A'),
              _buildDetailRow('Quality Grade', data['quality'] ?? 'N/A'),
              _buildDetailRow('Quantity Available', '${data['quantityAvailable']} kg'),
              _buildDetailRow('Quantity Purchased', '${data['quantityPurchased']} kg'),
              _buildDetailRow('Quantity Sold', '${data['quantitySold']} kg'),
              _buildDetailRow('Purchase Price', 'RWF ${data['purchasePricePerKg']}/kg'),
              if (data['sellingPricePerKg'] != null)
                _buildDetailRow('Selling Price', 'RWF ${data['sellingPricePerKg']}/kg'),
              _buildDetailRow('Supplier', data['supplierName'] ?? 'Unknown'),
              _buildDetailRow('Storage Location', data['storageLocation'] ?? 'N/A'),
              _buildDetailRow('Iron Content', '${data['ironContent'] ?? 80} mg/100g'),
              if (purchaseDate != null)
                _buildDetailRow(
                  'Purchase Date',
                  '${purchaseDate.day}/${purchaseDate.month}/${purchaseDate.year}',
                ),
              if (data['notes'] != null && data['notes'].toString().isNotEmpty) ...[
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditPriceDialog(context, docId, data);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Update Price'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ),
                ],
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
            width: 140,
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

  void _showEditPriceDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final controller = TextEditingController(
      text: data['sellingPricePerKg']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Selling Price'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Selling Price per kg (RWF)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
            suffixText: 'RWF',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(controller.text);
              if (price != null && price > 0) {
                await FirebaseFirestore.instance
                    .collection('inventory')
                    .doc(docId)
                    .update({'sellingPricePerKg': price});
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Price updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
