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

  /// Export detections to CSV format
  static Future<File> exportToCSV({
    required List<Map<String, dynamic>> detections,
  }) async {
    try {
      print('📊 Exporting to CSV...');

      // Prepare CSV data
      List<List<dynamic>> csvData = [
        // Header row
        [
          'Date',
          'Disease Label',
          'Confidence',
          'Recommendation',
          'Timestamp',
        ],
      ];

      // Data rows
      for (var detection in detections) {
        final timestamp = detection['timestamp'] as String? ?? 'N/A';
        final date = timestamp.isNotEmpty
            ? DateTime.tryParse(timestamp)?.toLocal().toString().split('.')[0] ?? 'N/A'
            : 'N/A';

        csvData.add([
          date,
          detection['disease_label'] ?? 'Unknown',
          (detection['confidence'] as num?)?.toStringAsFixed(2) ?? 'N/A',
          detection['recommendation'] ?? 'None',
          timestamp,
        ]);
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);

      // Get temporary directory
      final directory = await getTemporaryDirectory();
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

  /// Export statistics and detections to PDF report
  static Future<File> exportToPDF({
    required List<Map<String, dynamic>> detections,
    required Map<String, dynamic> summary,
    required List<DiseaseStats> diseaseStats,
  }) async {
    try {
      print('📄 Exporting to PDF...');

      final pdf = pw.Document();

      // Calculate some stats for the report
      final totalDetections = detections.length;
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
                'AgriSense Detection Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // Export date
              pw.Text(
                'Generated: ${DateTime.now().toString().split('.')[0]}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),

              // Summary section
              pw.Text(
                'Summary',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // Summary table
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Metric',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Value',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Data rows
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total Detections'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('$totalDetections'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Unique Diseases'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('$uniqueDiseases'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Healthy (%)',
                            textAlign: pw.TextAlign.left),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('$healthyPercentage%'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Diseased (%)',
                            textAlign: pw.TextAlign.left),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('$diseased%'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Most Common Disease'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('$mostCommon'),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Disease breakdown section
              pw.Text(
                'Disease Breakdown',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // Disease table
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Disease',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Count',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Percentage',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Disease rows
                  ...diseaseStats.map((stat) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(stat.disease),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${stat.count}'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                            '${stat.percentage.toStringAsFixed(2)}%'),
                      ),
                    ],
                  )),
                ],
              ),
            ],
          ),
        ),
      );

      // Add detailed detections page if there are many
      if (detections.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Detection History',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                // Detections table (limited to first 20 for space)
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(2.5),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Date',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Disease',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Confidence',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Recommendation',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                        ),
                      ],
                    ),
                    // Data rows (limit to 20)
                    ...detections.take(20).map((detection) {
                      final timestamp =
                          detection['timestamp'] as String? ?? 'N/A';
                      final date = timestamp.isNotEmpty
                          ? DateTime.tryParse(timestamp)
                                  ?.toLocal()
                                  .toString()
                                  .split('.')[0] ??
                              'N/A'
                          : 'N/A';
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(date, style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                                detection['disease_label'] ?? 'Unknown',
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                                '${((detection['confidence'] as num?)?.toStringAsFixed(2)) ?? 'N/A'}',
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                                detection['recommendation'] ?? 'None',
                                style: const pw.TextStyle(fontSize: 8)),
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                if (detections.length > 20)
                  pw.SizedBox(
                    height: 10,
                  ),
                if (detections.length > 20)
                  pw.Text(
                    'Note: Showing first 20 detections. Export CSV for complete history.',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      // Save to file
      final directory = await getTemporaryDirectory();
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
