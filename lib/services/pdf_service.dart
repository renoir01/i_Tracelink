import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order_model.dart';
import '../models/cooperative_model.dart';
import '../models/aggregator_model.dart';
import '../models/institution_model.dart';
import 'firestore_service.dart';

class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  Future<void> generateTraceabilityCertificate(OrderModel order) async {
    final pdf = pw.Document();

    // Fetch all actors in the supply chain
    CooperativeModel? cooperative;
    AggregatorModel? aggregator;
    InstitutionModel? institution;

    if (order.orderType == 'aggregator_to_farmer') {
      cooperative = await FirestoreService().getCooperativeByUserId(order.sellerId);
      aggregator = await FirestoreService().getAggregatorByUserId(order.buyerId);
    } else if (order.orderType == 'institution_to_aggregator') {
      aggregator = await FirestoreService().getAggregatorByUserId(order.sellerId);
      institution = await FirestoreService().getInstitutionByUserId(order.buyerId);
    }

    // Build PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(),
          pw.SizedBox(height: 20),

          // Certificate Title
          pw.Container(
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#E8F5E9'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'TRACEABILITY CERTIFICATE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#2E7D32'),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Iron-Biofortified Beans Supply Chain',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColor.fromHex('#1B5E20'),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Order Information
          _buildSection(
            'Order Information',
            [
              _buildInfoRow('Order ID', order.id.substring(0, 16)),
              _buildInfoRow('Order Type', order.orderType),
              _buildInfoRow('Quantity', '${order.quantity} kg'),
              _buildInfoRow('Status', order.status.toUpperCase()),
              _buildInfoRow(
                'Order Date',
                '${order.requestDate.day}/${order.requestDate.month}/${order.requestDate.year}',
              ),
              _buildInfoRow(
                'Expected Delivery',
                '${order.expectedDeliveryDate.day}/${order.expectedDeliveryDate.month}/${order.expectedDeliveryDate.year}',
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Iron Content Verification
          _buildIronVerificationSection(),
          pw.SizedBox(height: 20),

          // Supply Chain Actors
          _buildSection(
            'Supply Chain Verification',
            [
              if (cooperative != null) ...[
                _buildActorInfo(
                  'Farmer Cooperative',
                  cooperative.cooperativeName,
                  cooperative.location.district,
                  '${cooperative.numberOfMembers} members',
                ),
                pw.SizedBox(height: 12),
              ],
              if (aggregator != null) ...[
                _buildActorInfo(
                  'Aggregator',
                  aggregator.businessName,
                  aggregator.location.district,
                  (aggregator.storageInfo as String?) ?? 'Verified storage facility',
                ),
                pw.SizedBox(height: 12),
              ],
              if (institution != null) ...[
                _buildActorInfo(
                  'Institution',
                  institution.institutionName,
                  institution.location.district,
                  '${institution.numberOfBeneficiaries ?? 0} beneficiaries',
                ),
              ],
            ],
          ),
          pw.SizedBox(height: 20),

          // Delivery Location
          _buildSection(
            'Delivery Location',
            [
              _buildInfoRow('District', order.deliveryLocation.district),
              _buildInfoRow('Sector', order.deliveryLocation.sector),
              if (order.deliveryLocation.cell.isNotEmpty)
                _buildInfoRow('Cell', order.deliveryLocation.cell),
            ],
          ),
          pw.SizedBox(height: 30),

          // Footer
          _buildFooter(order.id),
        ],
      ),
    );

    // Save or share PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'traceability_certificate_${order.id.substring(0, 8)}.pdf',
    );
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor.fromHex('#4CAF50'),
            width: 3,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'iTraceLink',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#4CAF50'),
                ),
              ),
              pw.Text(
                'Supply Chain Traceability System',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromHex('#666666'),
                ),
              ),
            ],
          ),
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#E8F5E9'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(30)),
            ),
            child: pw.Center(
              child: pw.Text(
                '✓',
                style: pw.TextStyle(
                  fontSize: 32,
                  color: PdfColor.fromHex('#4CAF50'),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#DDDDDD')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#333333'),
            ),
          ),
          pw.SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColor.fromHex('#666666'),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildActorInfo(
    String role,
    String name,
    String location,
    String details,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                role,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#4CAF50'),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#4CAF50'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Text(
                  '✓ Verified',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            name,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '📍 $location',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#666666'),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            details,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#888888'),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildIronVerificationSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#E3F2FD'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColor.fromHex('#2196F3'), width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 40,
                height: 40,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#2196F3'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '💊',
                    style: const pw.TextStyle(fontSize: 20),
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Iron-Biofortified Beans',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1976D2'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Verified iron content: 60-90mg per 100g',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#0D47A1'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'These beans are biofortified to combat iron deficiency and improve nutrition outcomes in Rwanda.',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#424242'),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(String orderId) {
    final now = DateTime.now();
    return pw.Column(
      children: [
        pw.Divider(color: PdfColor.fromHex('#DDDDDD')),
        pw.SizedBox(height: 12),
        pw.Text(
          'This certificate verifies the complete traceability of iron-biofortified beans',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColor.fromHex('#666666'),
            fontStyle: pw.FontStyle.italic,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated on ${now.day}/${now.month}/${now.year} at ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColor.fromHex('#888888'),
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Certificate ID: ${orderId.substring(0, 16)}',
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColor.fromHex('#AAAAAA'),
            fontStyle: pw.FontStyle.italic,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'iTraceLink © 2025 | Powered by Rwanda Agriculture Board',
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColor.fromHex('#AAAAAA'),
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
