import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' if (dart.library.html) 'package:share_plus_web/share_plus_web.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeService {
  static final QrCodeService _instance = QrCodeService._internal();
  factory QrCodeService() => _instance;
  QrCodeService._internal();

  /// Generate QR code data for a seed batch
  String generateBatchQrData(String batchId) {
    // For now, just return the batch ID
    // In production, you could use a URL like: https://itracelink.app/verify?batch=$batchId
    return batchId;
  }

  /// Generate QR code data for an order
  String generateOrderQrData(String orderId) {
    return 'ORDER:$orderId';
  }

  /// Generate QR code data for a user/producer
  String generateProducerQrData(String producerId) {
    return 'PRODUCER:$producerId';
  }

  /// Save QR code image to device
  Future<String?> saveQrCodeImage({
    required GlobalKey qrKey,
    required String fileName,
  }) async {
    try {
      // Get the render object
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Convert to image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get directory
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/$fileName.png';

      // Save file
      final file = File(imagePath);
      await file.writeAsBytes(pngBytes);

      return imagePath;
    } catch (e) {
      debugPrint('Error saving QR code: $e');
      return null;
    }
  }

  /// Share QR code image
  Future<void> shareQrCode({
    required GlobalKey qrKey,
    required String title,
    required String fileName,
  }) async {
    try {
      final imagePath = await saveQrCodeImage(
        qrKey: qrKey,
        fileName: fileName,
      );

      if (imagePath != null) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: title,
        );
      }
    } catch (e) {
      debugPrint('Error sharing QR code: $e');
    }
  }

  /// Show QR code in dialog
  void showQrCodeDialog({
    required BuildContext context,
    required String data,
    required String title,
    String? subtitle,
  }) {
    final GlobalKey qrKey = GlobalKey();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),

              // QR Code
              RepaintBoundary(
                key: qrKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: QrImageView(
                    data: data,
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                    errorStateBuilder: (ctx, err) {
                      return const Center(
                        child: Text(
                          'Error generating QR code',
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Data info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        data,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.grey[700],
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Share button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await shareQrCode(
                          qrKey: qrKey,
                          title: title,
                          fileName: 'qr_code_${DateTime.now().millisecondsSinceEpoch}',
                        );
                      },
                      icon: const Icon(Icons.share, size: 20),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Close button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
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

  /// Show QR code bottom sheet (alternative to dialog)
  void showQrCodeBottomSheet({
    required BuildContext context,
    required String data,
    required String title,
    String? subtitle,
    Widget? additionalContent,
  }) {
    final GlobalKey qrKey = GlobalKey();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),

            // QR Code
            RepaintBoundary(
              key: qrKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
            ),

            if (additionalContent != null) ...[
              const SizedBox(height: 16),
              additionalContent,
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await shareQrCode(
                        qrKey: qrKey,
                        title: title,
                        fileName: 'qr_code_${DateTime.now().millisecondsSinceEpoch}',
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),

            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
