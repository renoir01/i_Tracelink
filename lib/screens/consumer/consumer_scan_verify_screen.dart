import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import 'product_information_screen.dart';

class ConsumerScanVerifyScreen extends StatefulWidget {
  const ConsumerScanVerifyScreen({super.key});

  @override
  State<ConsumerScanVerifyScreen> createState() => _ConsumerScanVerifyScreenState();
}

class _ConsumerScanVerifyScreenState extends State<ConsumerScanVerifyScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedCode;
  bool isProcessing = false;

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
          scannedCode = scanData.code;
        });

        // Pause camera
        await controller.pauseCamera();

        // Verify the product
        await _verifyProduct(scanData.code!);
      }
    });
  }

  Future<void> _verifyProduct(String batchId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.id ?? '';

      // Get batch information from Firestore
      final batchDoc = await FirebaseFirestore.instance
          .collection(AppConstants.batchesCollection)
          .doc(batchId)
          .get();

      if (!batchDoc.exists) {
        if (mounted) {
          _showVerificationResult(
            isVerified: false,
            message: 'Product not found in system',
            details: 'This QR code is not registered in our database. It may be counterfeit.',
          );
        }
        return;
      }

      final batchData = batchDoc.data() as Map<String, dynamic>;

      // Record the scan
      await FirebaseFirestore.instance
          .collection(AppConstants.consumerPurchasesCollection)
          .add({
        'consumerId': userId,
        'batchId': batchId,
        'sellerId': batchData['farmerId'] ?? '',
        'sellerName': batchData['cooperativeName'] ?? 'Unknown',
        'sellerType': 'farmer',
        'scanDate': Timestamp.now(),
        'wasVerified': true,
      });

      // Update consumer stats
      await FirebaseFirestore.instance
          .collection(AppConstants.consumersCollection)
          .where('userId', isEqualTo: userId)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          doc.reference.update({
            'totalScans': FieldValue.increment(1),
            'lastScanDate': Timestamp.now(),
            'scannedProducts': FieldValue.arrayUnion([batchId]),
          });
        }
      });

      // Navigate to product information screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ProductInformationScreen(
              batchId: batchId,
              batchData: batchData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showVerificationResult(
          isVerified: false,
          message: 'Verification Error',
          details: 'Failed to verify product: $e',
        );
      }
    }
  }

  void _showVerificationResult({
    required bool isVerified,
    required String message,
    required String details,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isVerified ? Icons.check_circle : Icons.warning,
              color: isVerified ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isVerified ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(details),
            if (!isVerified) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.report, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This product may be counterfeit. Please report to authorities.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!isVerified)
            TextButton.icon(
              onPressed: () {
                // TODO: Report fraud
                Navigator.pop(context);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.report, color: Colors.red),
              label: const Text('Report Fraud'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isVerified) {
                Navigator.pop(context);
              } else {
                setState(() => isProcessing = false);
                controller?.resumeCamera();
              }
            },
            child: Text(isVerified ? 'View Details' : 'Scan Again'),
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
        title: const Text('Scan Product'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          // Instructions Card
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
                        'Scan Product QR Code',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Position the QR code within the frame to verify authenticity',
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

          // Status Display
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
                        'Verifying product...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Position QR code in the frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Instant Verification',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
