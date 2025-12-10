// lib/services/export_service.dart
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../services/statistics_service.dart';

/// Model for export data
class ExportData {
  final List<Map<String, dynamic>> detections;
  final Map<String, dynamic> summary;
  final List<DiseaseStats> diseaseStats;
  final DateTime exportedAt;

  ExportData({
    required this.detections,
    required this.summary,
    required this.diseaseStats,
    required this.exportedAt,
  });
}

/// Service for exporting detection data to CSV and PDF formats
class ExportService {
  static const String _csvFileName = 'agrisense_detections_';
  static const String _pdfFileName = 'agrisense_report_';

  /// Export disease statistics to CSV format
  static Future<File> exportToCSV({
    required List<Map<String, dynamic>> detections,
  }) async {
    try {
      print('📊 Exporting to CSV...');

      // Prepare CSV data from disease statistics
      List<List<dynamic>> csvData = [
        // Header row
        [
          'Disease',
          'Detection Count',
          'Percentage (%)',
          'Last Detected',
        ],
      ];

      // Data rows - detections here are already formatted disease stats
      for (var detection in detections) {
        csvData.add([
          detection['disease'] ?? 'Unknown',
          detection['count'] ?? '0',
          detection['percentage'] ?? '0%',
          detection['last_detected'] ?? 'N/A',
        ]);
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);

      // Get downloads directory or fall back to documents
      Directory? directory;
      try {
        directory = await getDownloadsDirectory();
      } catch (e) {
        print('⚠️ Downloads directory not available, using app documents directory');
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Unable to access file storage directory');
      }

      final fileName =
          '$_csvFileName${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');

      // Write to file
      await file.writeAsString(csvString);
      print('✅ CSV exported to: ${file.path}');

      return file;
    } catch (e) {
      print('❌ CSV export error: $e');
      throw Exception('Failed to export CSV: $e');
    }
  }

  /// Export statistics and disease breakdown to PDF report
  static Future<File> exportToPDF({
    required List<Map<String, dynamic>> detections,
    required Map<String, dynamic> summary,
    required List<DiseaseStats> diseaseStats,
  }) async {
    try {
      print('📄 Exporting to PDF...');

      final pdf = pw.Document();

      // Calculate some stats for the report
      final totalDetections = summary['total_detections'] ?? 0;
      final healthyPercentage = summary['healthy_percentage'] ?? '0.0';
      final diseased = summary['diseased_percentage'] ?? '0.0';
      final mostCommon = summary['most_common_disease'] ?? 'None';
      final uniqueDiseases = summary['unique_diseases'] ?? 0;

      // Add page with title and summary
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Text(
                'AgriSense Farm Health Report',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // Export date
              pw.Text(
                'Generated: ${DateTime.now().toString().split('.')[0]}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 24),

              // Summary section header
              pw.Text(
                'Executive Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              // Summary statistics in a clean format
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Scans:', style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('$totalDetections', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Unique Issues:', style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('$uniqueDiseases', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Farm Health:', style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('${healthyPercentage.toString()}%', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Issues Found:', style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('${diseased.toString()}%', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Most Common:', style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('$mostCommon', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Disease breakdown section
              pw.Text(
                'Disease Breakdown',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              // Disease table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Disease',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Count',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Percentage',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11)),
                      ),
                    ],
                  ),
                  // Disease rows from statistics
                  ...diseaseStats.map((stat) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(stat.disease, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${stat.count}', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                            '${stat.percentage.toStringAsFixed(1)}%',
                            style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 24),

              // Footer note
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Report Notes:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      '• This report shows the aggregated disease statistics for your farm',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      '• Percentages are calculated from total scans',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      '• Review the smart recommendations in the app for actionable insights',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      // Save to file
      Directory? directory;
      try {
        directory = await getDownloadsDirectory();
      } catch (e) {
        print('⚠️ Downloads directory not available, using app documents directory');
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Unable to access file storage directory');
      }

      final fileName =
          '$_pdfFileName${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(await pdf.save());
      print('✅ PDF exported to: ${file.path}');

      return file;
    } catch (e) {
      print('❌ PDF export error: $e');
      throw Exception('Failed to export PDF: $e');
    }
  }

  /// Share file via system share dialog
  static Future<void> shareFile(File file) async {
    try {
      print('📤 Sharing file...');

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'AgriSense Detection Report',
        text: 'Here is my AgriSense detection report',
      );

      print('✅ File shared successfully');
    } catch (e) {
      print('❌ Share error: $e');
      throw Exception('Failed to share file: $e');
    }
  }

  /// Generate both CSV and PDF and return paths
  static Future<Map<String, File>> exportBoth({
    required List<Map<String, dynamic>> detections,
    required Map<String, dynamic> summary,
    required List<DiseaseStats> diseaseStats,
  }) async {
    try {
      print('📊 Exporting to both CSV and PDF...');

      final csv = await exportToCSV(detections: detections);
      final pdf = await exportToPDF(
        detections: detections,
        summary: summary,
        diseaseStats: diseaseStats,
      );

      return {
        'csv': csv,
        'pdf': pdf,
      };
    } catch (e) {
      print('❌ Dual export error: $e');
      throw Exception('Failed to export both formats: $e');
    }
  }
}
