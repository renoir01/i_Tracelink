import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class QRGenerator {
  /// Generate QR code data for a batch
  static String generateBatchQR({
    required String batchId,
    required String producerName,
    required String variety,
    required String productionDate,
  }) {
    return 'iTraceLink:batch:$batchId:$producerName:$variety:$productionDate';
  }

  /// Generate QR code data for a product
  static String generateProductQR({
    required String productId,
    required String sellerName,
    required String variety,
    required String certificationNumber,
  }) {
    return 'iTraceLink:product:$productId:$sellerName:$variety:$certificationNumber';
  }

  /// Generate QR code widget for display
  static Widget buildQRWidget({
    required String data,
    double size = 200,
    Color? foregroundColor,
    Color? backgroundColor,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      gapless: false,
      foregroundColor: foregroundColor ?? Colors.black,
      backgroundColor: backgroundColor ?? Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );
  }

  /// Generate printable QR code PDF
  static Future<void> printQRCode({
    required String data,
    required String title,
    required String subtitle,
    List<String>? additionalInfo,
  }) async {
    final pdf = pw.Document();

    // Generate QR image data
    final qrImage = await QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: false,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    ).toImageData(400);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 40),
              
              // Title
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              
              // Subtitle
              pw.Text(
                subtitle,
                style: const pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 40),
              
              // QR Code
              if (qrImage != null)
                pw.Image(
                  pw.MemoryImage(qrImage.buffer.asUint8List()),
                  width: 300,
                  height: 300,
                ),
              pw.SizedBox(height: 40),
              
              // Additional Info
              if (additionalInfo != null && additionalInfo.isNotEmpty) ...[
                pw.Divider(),
                pw.SizedBox(height: 20),
                ...additionalInfo.map((info) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text(
                    info,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                )),
              ],
              
              pw.Spacer(),
              
              // Footer
              pw.Text(
                'Scan this QR code with iTraceLink app to verify authenticity',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'iTraceLink - Iron-Biofortified Beans Traceability',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey500,
                ),
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  /// Generate multiple QR codes for batch printing
  static Future<void> printMultipleQRCodes({
    required List<Map<String, String>> items,
    required String headerTitle,
  }) async {
    final pdf = pw.Document();

    // Print 6 QR codes per page (2 columns x 3 rows)
    const itemsPerPage = 6;
    final pages = (items.length / itemsPerPage).ceil();

    for (int page = 0; page < pages; page++) {
      final startIndex = page * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage > items.length)
          ? items.length
          : startIndex + itemsPerPage;
      final pageItems = items.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              children: [
                // Header
                pw.Text(
                  headerTitle,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // QR Codes Grid
                pw.Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: pageItems.map((item) {
                    return pw.Container(
                      width: 250,
                      height: 280,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                      ),
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            item['title'] ?? '',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 10),
                          pw.Container(
                            width: 180,
                            height: 180,
                            child: pw.BarcodeWidget(
                              data: item['data'] ?? '',
                              barcode: pw.Barcode.qrCode(),
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            item['subtitle'] ?? '',
                            style: const pw.TextStyle(fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  /// Parse QR code data
  static Map<String, String>? parseQRData(String data) {
    if (!data.startsWith('iTraceLink:')) return null;

    final parts = data.split(':');
    if (parts.length < 3) return null;

    final type = parts[1]; // 'batch' or 'product'
    
    if (type == 'batch' && parts.length >= 6) {
      return {
        'type': 'batch',
        'batchId': parts[2],
        'producerName': parts[3],
        'variety': parts[4],
        'productionDate': parts[5],
      };
    } else if (type == 'product' && parts.length >= 6) {
      return {
        'type': 'product',
        'productId': parts[2],
        'sellerName': parts[3],
        'variety': parts[4],
        'certificationNumber': parts[5],
      };
    }

    return null;
  }
}
