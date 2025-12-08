# Phase 2.2 Developer Integration Guide
## Data Export Feature Integration

**Version**: 1.0.0  
**Status**: ✅ Complete  
**Target Audience**: Flutter Developers  
**Date**: 2024

---

## 🎯 Quick Start (5 Minutes)

### For Developers New to Phase 2.2

1. **Read**: `PHASE_2_2_QUICKSTART.md` (2 min)
2. **Review**: `lib/services/export_service.dart` (2 min)
3. **Check**: `lib/pages/statistics_page.dart` integration (1 min)

### Key Files to Know
```
lib/
├── services/
│   ├── export_service.dart         # Export functionality
│   ├── statistics_service.dart    # Data provider
│   └── validation_service.dart    # Input validation
├── providers/
│   └── statistics_provider.dart   # State management
├── pages/
│   └── statistics_page.dart       # UI integration
└── widgets/
    └── disease_chart.dart         # Statistics widgets
```

---

## 📦 Project Structure

### Complete File Tree

```
agrisense/
├── lib/
│   ├── services/
│   │   ├── export_service.dart           ← NEW: Export/Share
│   │   ├── statistics_service.dart       ← UPDATED: Data provider
│   │   ├── http_retry_service.dart
│   │   ├── local_cache_service.dart
│   │   ├── sync_service.dart
│   │   ├── validation_service.dart
│   │   └── detection_manager.dart
│   ├── providers/
│   │   ├── statistics_provider.dart      ← UPDATED: Charts/Export
│   │   └── app_settings_provider.dart
│   ├── pages/
│   │   ├── statistics_page.dart          ← UPDATED: Export UI
│   │   ├── settings_page.dart
│   │   └── [other pages]
│   ├── widgets/
│   │   ├── disease_chart.dart            ← UPDATED: New widgets
│   │   ├── live_stream_widget.dart
│   │   ├── mjpeg_stream.dart
│   │   ├── ai_recommendation_widget.dart
│   │   └── app_bar.dart
│   ├── main.dart
│   ├── detection_service.dart
│   └── gemini_service.dart
├── test/
│   └── widget_test.dart
├── pubspec.yaml                          ← UPDATED: New deps
├── pubspec.lock
├── analysis_options.yaml
├── devtools_options.yaml
├── agrisense.iml
└── [documentation files]
```

---

## 🔧 Setup Instructions

### Step 1: Verify Dependencies

```bash
# Check pubspec.yaml has all exports dependencies
cd c:\Users\nain2\Desktop\flutter_app\agrisense

# Verify these are present:
# csv: ^6.0.0
# pdf: ^3.10.0
# path_provider: ^2.1.0
# share_plus: ^7.0.0

flutter pub get
```

### Step 2: Build & Run

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build and run
flutter run

# Or build for specific platform
flutter build apk --release
flutter build ios --release
```

### Step 3: Test the Feature

1. Navigate to Statistics page
2. Click "Export Data" button
3. Select CSV or PDF
4. Verify export succeeds
5. Test file sharing

---

## 🏗️ Architecture Overview

### Data Flow Diagram

```
┌─────────────────────────────────────────┐
│        Statistics Page (UI)             │
│  - Shows statistics charts              │
│  - Export button trigger                │
│  - Error/success handling               │
└─────────────────┬───────────────────────┘
                  │
                  ├─ Retrieves data from
                  │
┌─────────────────▼───────────────────────┐
│   Statistics Provider (State)           │
│  - Manages statistics state             │
│  - Holds charts data                    │
│  - Summary statistics                   │
└─────────────────┬───────────────────────┘
                  │
                  ├─ Fetches data from
                  │
┌─────────────────▼───────────────────────┐
│   Statistics Service (Data Layer)       │
│  - Retrieves detection history          │
│  - Calculates statistics                │
│  - Returns formatted data               │
└─────────────────┬───────────────────────┘
                  │
                  ├─ Sends to
                  │
┌─────────────────▼───────────────────────┐
│    Export Service (Processing)          │
│  - Formats CSV                          │
│  - Generates PDF                        │
│  - Returns File objects                 │
└─────────────────┬───────────────────────┘
                  │
                  ├─ Shares via
                  │
┌─────────────────▼───────────────────────┐
│   Share Plus (Platform APIs)            │
│  - Email                                │
│  - Messaging                            │
│  - Cloud Storage                        │
└─────────────────────────────────────────┘
```

### Class Dependencies

```
ExportService (Static methods)
├─ uses: csv (CsvConverter)
├─ uses: pdf (PDF generation)
├─ uses: path_provider (File system)
├─ uses: share_plus (Platform sharing)
└─ imports: DiseaseStats (from statistics_service)

StatisticsPage (Widget)
├─ uses: StatisticsProvider (Provider)
├─ uses: ExportService (Export)
├─ uses: StatisticsService (Data)
└─ widgets: DiseaseChart, HealthMeter, etc.

StatisticsProvider (ChangeNotifier)
├─ uses: StatisticsService
├─ properties: diseaseStats, summary, etc.
└─ methods: loadStatistics(), clearHistory(), etc.

StatisticsService (Singleton)
├─ queries: LocalCacheService
├─ processes: Detection history
└─ returns: DiseaseStats, summary data
```

---

## 💻 Code Examples

### Example 1: Adding Export to a New Page

```dart
import '../services/export_service.dart';
import '../services/statistics_service.dart';

class MyCustomPage extends StatefulWidget {
  @override
  _MyCustomPageState createState() => _MyCustomPageState();
}

class _MyCustomPageState extends State<MyCustomPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Page')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _exportDetections,
            child: Text('Export'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDetections() async {
    try {
      // Show loading
      _showLoadingDialog('Exporting...');

      // Get data
      final service = StatisticsService();
      final detections = await service.getDetectionHistory();

      if (detections.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No data to export')),
        );
        return;
      }

      // Export
      final file = await ExportService.exportToCSV(
        detections: detections,
      );

      Navigator.pop(context);

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported successfully'),
          action: SnackBarAction(
            label: 'SHARE',
            onPressed: () => ExportService.shareFile(file),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Example 2: Custom Export Formatting

```dart
Future<void> customExport() async {
  final service = StatisticsService();
  final detections = await service.getDetectionHistory();

  // Add custom filtering
  final recentDetections = detections
      .where((d) => DateTime.parse(d['timestamp'])
          .isAfter(DateTime.now().subtract(Duration(days: 7))))
      .toList();

  // Custom CSV with additional fields
  List<List<dynamic>> csvData = [
    ['Date', 'Disease', 'Confidence', 'Recommendation', 'Severity'],
  ];

  for (var detection in recentDetections) {
    csvData.add([
      detection['timestamp'],
      detection['disease_label'],
      detection['confidence'],
      detection['recommendation'],
      _calculateSeverity(detection['confidence']),
    ]);
  }

  // Export
  final csvString = const ListToCsvConverter().convert(csvData);
  // Save to file...
}

String _calculateSeverity(double confidence) {
  if (confidence > 0.8) return 'High';
  if (confidence > 0.5) return 'Medium';
  return 'Low';
}
```

### Example 3: Batch Export Operations

```dart
Future<void> batchExport() async {
  try {
    final service = StatisticsService();
    final provider = context.read<StatisticsProvider>();

    // Load statistics
    await provider.loadStatistics();

    // Get all data
    final detections = await service.getDetectionHistory();
    final summary = provider.summary;
    final diseaseStats = provider.diseaseStats;

    // Export both formats
    final files = await ExportService.exportBoth(
      detections: detections,
      summary: summary,
      diseaseStats: diseaseStats,
    );

    // Share CSV
    await ExportService.shareFile(files['csv']!);

    // Then offer PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV shared. PDF also ready.'),
        action: SnackBarAction(
          label: 'SHARE PDF',
          onPressed: () => ExportService.shareFile(files['pdf']!),
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Batch export failed: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## 🧪 Testing the Integration

### Unit Tests for Export Service

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:agrisense/services/export_service.dart';

void main() {
  group('ExportService Tests', () {
    test('CSV export creates valid file', () async {
      final detections = [
        {
          'disease_label': 'Powdery Mildew',
          'confidence': 0.95,
          'recommendation': 'Apply sulfur',
          'timestamp': '2024-01-15T10:30:45.000Z',
        },
      ];

      final file = await ExportService.exportToCSV(
        detections: detections,
      );

      expect(file.existsSync(), true);
      expect(file.path.contains('agrisense_detections_'), true);
      expect(file.path.endsWith('.csv'), true);

      final content = await file.readAsString();
      expect(content.contains('Powdery Mildew'), true);
      expect(content.contains('0.95'), true);
    });

    test('PDF export creates valid file', () async {
      final diseaseStats = [
        DiseaseStats(
          disease: 'Powdery Mildew',
          count: 20,
          percentage: 44.4,
        ),
      ];

      final file = await ExportService.exportToPDF(
        detections: [],
        summary: {
          'total_detections': 45,
          'unique_diseases': 2,
          'healthy_percentage': 50.0,
          'diseased_percentage': 50.0,
          'most_common_disease': 'Powdery Mildew',
        },
        diseaseStats: diseaseStats,
      );

      expect(file.existsSync(), true);
      expect(file.path.endsWith('.pdf'), true);
    });

    test('Empty detections throw error', () async {
      expect(
        () => ExportService.exportToCSV(detections: []),
        returnsNormally,
      );
      // CSV will succeed but file will be mostly headers
    });
  });
}
```

### Widget Tests for UI

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrisense/pages/statistics_page.dart';

void main() {
  group('Statistics Page Export Tests', () {
    testWidgets('Export button is visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsPage(),
        ),
      );

      expect(find.byIcon(Icons.download), findsOneWidget);
      expect(find.text('Export Data'), findsOneWidget);
    });

    testWidgets('Export dialog shows format options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsPage(),
        ),
      );

      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.table_chart), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });
  });
}
```

---

## 🔍 Debugging Guide

### Common Issues & Solutions

#### Issue 1: Export Service Not Importing
```dart
// ❌ Wrong
import 'export_service.dart';

// ✅ Correct
import '../services/export_service.dart';
```

#### Issue 2: File Path Issues
```dart
// ❌ Wrong - Path might not exist
File('/path/to/file.csv')

// ✅ Correct - Use path_provider
final directory = await getTemporaryDirectory();
final file = File('${directory.path}/file.csv');
```

#### Issue 3: Share Dialog Not Showing
```dart
// ✅ Check permissions first
try {
  await ExportService.shareFile(file);
} catch (e) {
  print('Share error: $e');
  // Show error to user
}
```

#### Issue 4: Null Safety Issues
```dart
// ❌ Wrong - May throw null reference
detection['confidence'].toString()

// ✅ Correct - Handle nulls
(detection['confidence'] as num?)?.toStringAsFixed(2) ?? 'N/A'
```

### Debug Logging

Enable debug output in export operations:

```dart
// In export_service.dart, prints are already included:
print('📊 Exporting to CSV...');
print('✅ CSV exported to: ${file.path}');
print('❌ CSV export error: $e');

// Check console output for these messages
```

### Testing Export Manually

```bash
# Build and run on emulator
flutter run -v

# Then in app:
# 1. Open Statistics page
# 2. Scan a plant to create detection
# 3. Click Export Data
# 4. Select CSV or PDF
# 5. Check debug console for success message
# 6. Click SHARE and send to yourself via email
```

---

## 📋 Checklist for New Developers

- [ ] Read this integration guide
- [ ] Review `export_service.dart`
- [ ] Check `statistics_page.dart` integration
- [ ] Review data models in `statistics_service.dart`
- [ ] Understand error handling patterns
- [ ] Run project without errors
- [ ] Test export feature manually
- [ ] Review API reference documentation
- [ ] Understand file paths and sharing
- [ ] Know how to debug export issues

---

## 🚀 Next Steps

### After Understanding Phase 2.2

1. **Familiarize with Phase 1 Foundation**
   - Read: `PHASE_1_COMPLETE.md`
   - Review: All Phase 1 services

2. **Understand Related Features**
   - Statistics Service: Data retrieval
   - Statistics Provider: State management
   - Statistics Page: UI implementation

3. **Prepare for Phase 2.3**
   - Push Notifications system
   - Works alongside export feature
   - Uses similar patterns

### Common Development Tasks

#### Task 1: Add Export Button to New Page
```dart
ElevatedButton.icon(
  icon: Icon(Icons.download),
  label: Text('Export'),
  onPressed: () => _showExportDialog(),
)
```

#### Task 2: Customize Export Data
```dart
// Filter detections
final recentDetections = detections
    .where((d) => DateTime.parse(d['timestamp']).year == 2024)
    .toList();

// Export filtered data
final file = await ExportService.exportToCSV(
  detections: recentDetections,
);
```

#### Task 3: Handle Export Errors
```dart
try {
  final file = await ExportService.exportToCSV(...);
} catch (e) {
  print('Error: $e');
  // Show user-friendly error
}
```

---

## 📞 Support Resources

### Documentation
- `PHASE_2_2_QUICKSTART.md` - Quick reference
- `PHASE_2_2_API_REFERENCE.md` - Complete API docs
- `PHASE_2_2_TESTING_GUIDE.md` - Testing procedures

### Code Examples
- `lib/pages/statistics_page.dart` - Full implementation
- `lib/services/export_service.dart` - Service code
- `lib/widgets/disease_chart.dart` - UI widgets

### Contact
- Development Team for questions
- Code reviews before merging
- Testing before production

---

## 🎓 Learning Path

### Week 1: Foundations
- [ ] Day 1: Read setup docs
- [ ] Day 2: Review source code
- [ ] Day 3: Run project locally
- [ ] Day 4-5: Test features manually

### Week 2: Development
- [ ] Day 1: Small feature addition
- [ ] Day 2: Code review
- [ ] Day 3: Bug fixes
- [ ] Day 4-5: Testing & refinement

### Week 3: Optimization
- [ ] Performance review
- [ ] Error handling improvements
- [ ] Documentation updates
- [ ] Final testing

---

## 📈 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024 | Initial release |
| Future | TBD | Export enhancements |

---

**Document Version**: 1.0.0  
**Last Updated**: 2024  
**Status**: Complete & Ready for Development
