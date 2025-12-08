# Phase 2.2 Export Service API Reference
## Complete API Documentation

**Version**: 1.0.0  
**Status**: ✅ Complete  
**Last Updated**: 2024

---

## 📚 Table of Contents

1. [Overview](#overview)
2. [Service Classes](#service-classes)
3. [Methods](#methods)
4. [Data Models](#data-models)
5. [Error Handling](#error-handling)
6. [Usage Examples](#usage-examples)
7. [Integration Guide](#integration-guide)

---

## Overview

The Export Service provides functionality to export detection history and statistics to CSV and PDF formats, with support for file sharing via native platform APIs.

### Key Features
- ✅ CSV export with full detection history
- ✅ PDF export with statistics summary and top detections
- ✅ Native file sharing integration
- ✅ Comprehensive error handling
- ✅ Automatic file naming with timestamps
- ✅ Support for large datasets

### File Location
```
lib/services/export_service.dart
```

### Dependencies
```yaml
csv: ^6.0.0
pdf: ^3.10.0
path_provider: ^2.1.0
share_plus: ^7.0.0
```

---

## Service Classes

### ExportData Model

Data container for complete export information.

```dart
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
```

**Fields**:
- `detections`: List of detection records to export
- `summary`: Statistics summary containing totals and percentages
- `diseaseStats`: Disease frequency and distribution data
- `exportedAt`: Timestamp of export operation

---

### ExportService Class

Static service providing export and sharing functionality.

```dart
class ExportService {
  static const String _csvFileName = 'agrisense_detections_';
  static const String _pdfFileName = 'agrisense_report_';
  
  // Methods listed below
}
```

**Constants**:
- `_csvFileName`: Base name for CSV exports (gets timestamp appended)
- `_pdfFileName`: Base name for PDF exports (gets timestamp appended)

---

## Methods

### 1. exportToCSV()

Export detection history to CSV format.

```dart
static Future<File> exportToCSV({
  required List<Map<String, dynamic>> detections,
}) async
```

**Parameters**:
- `detections` *(required)*: List of detection records with keys:
  - `disease_label`: String - Disease identified
  - `confidence`: double - Confidence score (0-1)
  - `recommendation`: String - Suggested treatment
  - `timestamp`: String - ISO 8601 timestamp

**Returns**: 
- `Future<File>`: File object pointing to generated CSV

**Throws**:
- `Exception`: If CSV generation fails

**CSV Structure**:
```
Date,Disease Label,Confidence,Recommendation,Timestamp
2024-01-15 10:30:45,Leaf Blight,0.92,Apply fungicide,2024-01-15T10:30:45.000Z
2024-01-15 11:20:30,Powdery Mildew,0.87,Increase ventilation,2024-01-15T11:20:30.000Z
```

**Example**:
```dart
final detections = [
  {
    'disease_label': 'Leaf Blight',
    'confidence': 0.92,
    'recommendation': 'Apply fungicide',
    'timestamp': '2024-01-15T10:30:45.000Z',
  },
];

try {
  final csvFile = await ExportService.exportToCSV(
    detections: detections,
  );
  print('CSV exported to: ${csvFile.path}');
} catch (e) {
  print('Export failed: $e');
}
```

---

### 2. exportToPDF()

Export statistics and detections to professional PDF report.

```dart
static Future<File> exportToPDF({
  required List<Map<String, dynamic>> detections,
  required Map<String, dynamic> summary,
  required List<DiseaseStats> diseaseStats,
}) async
```

**Parameters**:
- `detections` *(required)*: List of detection records
- `summary` *(required)*: Statistics summary with keys:
  - `healthy_percentage`: double - Healthy plants %
  - `diseased_percentage`: double - Diseased plants %
  - `most_common_disease`: String - Top disease
  - `unique_diseases`: int - Count of unique diseases
  - `total_detections`: int - Total detections
- `diseaseStats` *(required)*: List of DiseaseStats objects

**Returns**: 
- `Future<File>`: File object pointing to generated PDF

**Throws**:
- `Exception`: If PDF generation fails

**PDF Structure**:
- **Page 1**: Title, export date, summary statistics table, disease breakdown table
- **Page 2**: Detection history table (first 20 records) + note if more exist

**Example**:
```dart
final summary = {
  'healthy_percentage': 78.5,
  'diseased_percentage': 21.5,
  'most_common_disease': 'Powdery Mildew',
  'unique_diseases': 3,
  'total_detections': 45,
};

final diseaseStats = [
  DiseaseStats(
    disease: 'Powdery Mildew',
    count: 20,
    percentage: 44.4,
  ),
  DiseaseStats(
    disease: 'Leaf Blight',
    count: 15,
    percentage: 33.3,
  ),
];

try {
  final pdfFile = await ExportService.exportToPDF(
    detections: detections,
    summary: summary,
    diseaseStats: diseaseStats,
  );
  print('PDF exported to: ${pdfFile.path}');
} catch (e) {
  print('Export failed: $e');
}
```

---

### 3. shareFile()

Share file via native platform share dialog.

```dart
static Future<void> shareFile(File file) async
```

**Parameters**:
- `file` *(required)*: File object to share (CSV or PDF)

**Returns**: 
- `Future<void>`: Completes when share operation finishes

**Throws**:
- `Exception`: If sharing fails

**Supported Destinations**:
- Email
- Messaging apps
- Cloud storage (Drive, OneDrive, iCloud)
- File transfer apps
- Custom sharing apps

**Example**:
```dart
try {
  final file = File('/path/to/report.pdf');
  await ExportService.shareFile(file);
  print('File shared successfully');
} catch (e) {
  print('Share failed: $e');
}
```

---

### 4. exportBoth()

Export data to both CSV and PDF formats simultaneously.

```dart
static Future<Map<String, File>> exportBoth({
  required List<Map<String, dynamic>> detections,
  required Map<String, dynamic> summary,
  required List<DiseaseStats> diseaseStats,
}) async
```

**Parameters**:
- `detections` *(required)*: List of detection records
- `summary` *(required)*: Statistics summary
- `diseaseStats` *(required)*: Disease statistics

**Returns**: 
- `Future<Map<String, File>>`: Map with keys 'csv' and 'pdf', values are File objects

**Throws**:
- `Exception`: If either export format fails

**Example**:
```dart
try {
  final files = await ExportService.exportBoth(
    detections: detections,
    summary: summary,
    diseaseStats: diseaseStats,
  );
  
  final csvFile = files['csv']!;
  final pdfFile = files['pdf']!;
  
  print('CSV: ${csvFile.path}');
  print('PDF: ${pdfFile.path}');
} catch (e) {
  print('Dual export failed: $e');
}
```

---

## Data Models

### DiseaseStats

```dart
class DiseaseStats {
  final String disease;
  final int count;
  final double percentage;
  
  DiseaseStats({
    required this.disease,
    required this.count,
    required this.percentage,
  });
}
```

**Usage in Statistics Service**:
```dart
final diseaseStats = await StatisticsService().getDiseaseStats();
// Returns list of DiseaseStats objects for export
```

---

## Error Handling

### Common Exceptions

#### 1. No Detection Data
```dart
if (detections.isEmpty) {
  throw Exception('No detection data to export');
}
```

**Handle with**:
```dart
try {
  final file = await ExportService.exportToCSV(detections: []);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('No data to export')),
  );
}
```

#### 2. File System Error
```dart
// Thrown if temporary directory not accessible
Exception('Failed to export CSV: ...')
```

**Handle with**:
```dart
try {
  final file = await ExportService.exportToCSV(detections: detections);
} on FileSystemException catch (e) {
  print('File system error: ${e.message}');
}
```

#### 3. Share Dialog Cancelled
```dart
// Share returns without error if user cancels
// No exception thrown
```

---

## Usage Examples

### Example 1: Basic CSV Export with Share

```dart
import '../services/export_service.dart';
import '../services/statistics_service.dart';

Future<void> exportAndShare() async {
  try {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Exporting...'),
        content: CircularProgressIndicator(),
      ),
    );

    // Get detections
    final detections = await StatisticsService().getDetectionHistory();
    
    if (detections.isEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No data to export')),
      );
      return;
    }

    // Export to CSV
    final csvFile = await ExportService.exportToCSV(
      detections: detections,
    );

    // Close loading dialog
    Navigator.pop(context);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV exported successfully'),
        action: SnackBarAction(
          label: 'SHARE',
          onPressed: () => ExportService.shareFile(csvFile),
        ),
      ),
    );
  } catch (e) {
    Navigator.pop(context); // Close loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export failed: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Example 2: Complete Statistics Export

```dart
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';
import '../services/export_service.dart';
import '../services/statistics_service.dart';

Future<void> exportCompleteReport() async {
  try {
    final provider = context.read<StatisticsProvider>();
    final service = StatisticsService();

    // Gather all data
    final detections = await service.getDetectionHistory();
    final diseaseStats = provider.diseaseStats;
    final summary = provider.summary;

    // Generate PDF report
    final pdfFile = await ExportService.exportToPDF(
      detections: detections,
      summary: summary,
      diseaseStats: diseaseStats,
    );

    // Share the report
    await ExportService.shareFile(pdfFile);
  } catch (e) {
    print('Error: $e');
  }
}
```

### Example 3: Dual Format Export

```dart
Future<void> exportAllFormats() async {
  try {
    final files = await ExportService.exportBoth(
      detections: detections,
      summary: summary,
      diseaseStats: diseaseStats,
    );

    print('Exports completed:');
    print('CSV: ${files['csv']!.path}');
    print('PDF: ${files['pdf']!.path}');

    // Share CSV first
    await ExportService.shareFile(files['csv']!);
  } catch (e) {
    print('Export failed: $e');
  }
}
```

---

## Integration Guide

### Step 1: Import the Service

```dart
import '../services/export_service.dart';
import '../services/statistics_service.dart';
```

### Step 2: Create Export UI Button

```dart
ElevatedButton.icon(
  icon: Icon(Icons.download),
  label: Text('Export Data'),
  onPressed: _showExportOptions,
)
```

### Step 3: Implement Export Handler

```dart
void _showExportOptions() {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Export Format'),
      actions: [
        ElevatedButton(
          onPressed: _exportAsCSV,
          child: Text('CSV'),
        ),
        ElevatedButton(
          onPressed: _exportAsPDF,
          child: Text('PDF'),
        ),
      ],
    ),
  );
}

Future<void> _exportAsCSV() async {
  // Implementation here
}

Future<void> _exportAsPDF() async {
  // Implementation here
}
```

### Step 4: Handle Errors Gracefully

```dart
Future<void> _handleExport(Future<File> Function() exportFn) async {
  if (!mounted) return;
  
  try {
    _showLoadingDialog('Exporting...');
    
    final file = await exportFn();
    
    Navigator.pop(context); // Close loading dialog
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export successful'),
        action: SnackBarAction(
          label: 'SHARE',
          onPressed: () => ExportService.shareFile(file),
        ),
      ),
    );
  } catch (e) {
    Navigator.pop(context);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export failed: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## Performance Considerations

### Optimization Tips

1. **Large Datasets**: Use `take()` and `skip()` for pagination
   ```dart
   final recentDetections = detections.skip(0).take(100).toList();
   ```

2. **Async Operations**: Always use `async`/`await` on main thread
   ```dart
   final file = await ExportService.exportToCSV(detections: detections);
   ```

3. **Memory Management**: Files are stored in temporary directory and can be cleared
   ```dart
   // Files auto-cleanup, but can manually delete if needed
   await file.delete();
   ```

4. **UI Responsiveness**: Show progress during long exports
   ```dart
   showDialog(
     barrierDismissible: false,
     builder: (ctx) => AlertDialog(
       title: Text('Exporting...'),
       content: CircularProgressIndicator(),
     ),
   );
   ```

---

## Troubleshooting

### CSV Export Issues

| Issue | Solution |
|-------|----------|
| Empty file | Check detections list is not empty |
| Encoding issues | CSV uses UTF-8 (Unicode supported) |
| Truncated data | Check timestamp format is valid |

### PDF Export Issues

| Issue | Solution |
|-------|----------|
| Blank pages | Verify disease stats are populated |
| Missing data | Ensure summary dict has all required keys |
| File too large | Limit to first 20 detections in PDF |

### Share Issues

| Issue | Solution |
|-------|----------|
| Share dialog not showing | Check file exists and permissions granted |
| Share fails silently | User likely canceled action |
| File not received | Check file format and app permissions |

---

## Testing the API

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import '../services/export_service.dart';

void main() {
  group('ExportService', () {
    test('exportToCSV generates valid CSV', () async {
      final detections = [
        {
          'disease_label': 'Test Disease',
          'confidence': 0.95,
          'recommendation': 'Test treatment',
          'timestamp': '2024-01-15T10:30:45.000Z',
        },
      ];

      final file = await ExportService.exportToCSV(
        detections: detections,
      );

      expect(file.existsSync(), true);
      expect(file.path.endsWith('.csv'), true);

      final content = await file.readAsString();
      expect(content.contains('Test Disease'), true);
      expect(content.contains('0.95'), true);
    });

    test('exportToPDF generates valid PDF', () async {
      final file = await ExportService.exportToPDF(
        detections: testDetections,
        summary: testSummary,
        diseaseStats: testDiseaseStats,
      );

      expect(file.existsSync(), true);
      expect(file.path.endsWith('.pdf'), true);
    });
  });
}
```

---

## API Changelog

### Version 1.0.0 (Current)
- ✅ Initial release
- ✅ CSV export with full history
- ✅ PDF export with statistics
- ✅ Native file sharing
- ✅ Comprehensive error handling

---

## Support & Questions

For issues or questions about the Export Service API:
1. Check this documentation
2. Review code comments in `export_service.dart`
3. Check test examples in `statistics_page.dart`
4. Contact development team

---

**Document Version**: 1.0.0  
**Last Updated**: 2024  
**Maintained By**: Development Team
