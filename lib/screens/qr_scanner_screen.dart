import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/app_theme.dart';
import '../utils/qr_generator.dart';
import 'qr/batch_verification_screen.dart';
import 'traceability/traceability_chain_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) continue;

      setState(() => _isProcessing = true);
      _controller.stop();

      final qrData = QRGenerator.parseQRData(value);
      if (qrData != null && qrData['type'] == 'batch') {
        final batchId = qrData['batchId'];
        if (batchId != null && batchId.isNotEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BatchVerificationScreen(batchId: batchId),
            ),
          );
          return;
        }
      }

      if (qrData != null && qrData['type'] == 'product') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Product QR')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 56),
                      const SizedBox(height: 16),
                      const Text(
                        'Product QR recognized',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text("Product ID: ${qrData['productId'] ?? 'Unknown'}"),
                      const SizedBox(height: 8),
                      const Text(
                        'Product certificate verification is not available yet. '
                        'This code alone does not confirm authenticity.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        return;
      }

      // Unstructured QR values are treated as order IDs for compatibility
      // with the existing order traceability workflow.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TraceabilityChainScreen(orderId: value),
        ),
      );
      return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            tooltip: 'Toggle flashlight',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.black.withOpacity(0.65),
              child: Text(
                _isProcessing
                    ? 'Code detected. Opening traceability…'
                    : 'Position the QR code inside the camera view.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
