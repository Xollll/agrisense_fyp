# Phase 2.2: Data Export Implementation Guide

## Quick Reference

### What Was Implemented
✅ CSV export of detection history  
✅ PDF report generation  
✅ System file sharing  
✅ UI integration with Statistics Dashboard  
✅ Error handling and user feedback  

### Key Files
- `lib/services/export_service.dart` - Core export logic
- `lib/pages/statistics_page.dart` - UI integration
- `pubspec.yaml` - Dependencies

---

## Step-by-Step Implementation

### 1. Export Service Creation

The `ExportService` class provides static methods for exporting data:

```dart
// Export to CSV
final csvFile = await ExportService.exportToCSV(
  detections: detections,
);

// Export to PDF
final pdfFile = await ExportService.exportToPDF(
  detections: detections,
  summary: summary,
  diseaseStats: diseaseStats,
);

// Share file
await ExportService.shareFile(csvFile);
```

### 2. UI Integration Points

**StatisticsPage** has been updated with:

#### A. Export Options Dialog
```dart
void _showExportOptions() {
  // Shows CSV and PDF options
  // Calls export methods on selection
}
```

#### B. CSV Export Method
```dart
Future<void> _exportAsCSV() async {
  // 1. Show loading dialog
  // 2. Get detection history
  // 3. Call ExportService.exportToCSV()
  // 4. Show success notification
  // 5. Offer share option
}
```

#### C. PDF Export Method
```dart
Future<void> _exportAsPDF() async {
  // 1. Show loading dialog
  // 2. Get detection history and summary
  // 3. Call ExportService.exportToPDF()
  // 4. Show success notification
  // 5. Offer share option
}
```

#### D. File Sharing
```dart
Future<void> _shareFile(dynamic file) async {
  // Calls ExportService.shareFile()
  // Shows error notification if fails
}
```

### 3. Data Flow

```
User taps "Export Data"
    ↓
_showExportOptions() dialog shown
    ↓
User selects format (CSV/PDF)
    ↓
_exportAsCSV() or _exportAsPDF() called
    ↓
_showLoadingDialog() shown
    ↓
StatisticsService.getDetectionHistory() retrieves data
    ↓
ExportService.exportToCSV/PDF() generates file
    ↓
File saved to temporary directory
    ↓
Success SnackBar shown with SHARE action
    ↓
Optional: User taps SHARE
    ↓
_shareFile() opens system share dialog
```

### 4. Export Formats

#### CSV Output
- Header: Date, Disease Label, Confidence, Recommendation, Timestamp
- Data rows with formatted timestamps
- Easy import to Excel/Sheets

#### PDF Output
- Professional report layout
- Summary section with key metrics
- Disease breakdown table
- Detection history table (limited to 20 most recent)
- Generation date in header

---

## Integration with Existing Code

### StatisticsProvider Integration
```dart
// Getting summary data for PDF
final statsProvider = context.read<StatisticsProvider>();
final summary = statsProvider.summary;
final diseaseStats = statsProvider.diseaseStats;
```

### StatisticsService Integration
```dart
// Getting detection history
final detections = await StatisticsService().getDetectionHistory();
```

---

## Dependencies Used

### csv (6.0.0)
Converts detection data to CSV format:
```dart
import 'package:csv/csv.dart';
List<List<dynamic>> csvData = [...];
String csvString = const ListToCsvConverter().convert(csvData);
```

### pdf (3.10.0)
Creates PDF documents:
```dart
import 'package:pdf/widgets.dart' as pw;
final pdf = pw.Document();
pdf.addPage(pw.Page(...));
await pdf.save();
```

### path_provider (2.1.0)
Accesses temporary directory:
```dart
import 'package:path_provider/path_provider.dart';
final directory = await getTemporaryDirectory();
```

### share_plus (7.0.0)
Opens system share dialog:
```dart
import 'package:share_plus/share_plus.dart';
await Share.shareXFiles([XFile(file.path)]);
```

---

## Error Handling

### Empty Data Check
```dart
if (detections.isEmpty) {
  // Show "No detection data to export" message
  return;
}
```

### Export Exceptions
```dart
try {
  final file = await ExportService.exportToCSV(...);
} catch (e) {
  // Show error snackbar
  // Close loading dialog
}
```

### Share Exceptions
```dart
try {
  await ExportService.shareFile(file);
} catch (e) {
  // Show "Share failed" error
}
```

### Mounted State Check
```dart
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(...);
```

---

## Code Examples

### Complete CSV Export Flow
```dart
Future<void> _exportAsCSV() async {
  if (!mounted) return;
  
  try {
    _showLoadingDialog('Exporting to CSV...');
    
    final detections = await StatisticsService().getDetectionHistory();
    
    if (detections.isEmpty) {
      Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No detection data to export')),
      );
      return;
    }
    
    final csvFile = await ExportService.exportToCSV(
      detections: detections,
    );
    
    Navigator.pop(context);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('CSV exported successfully'),
        action: SnackBarAction(
          label: 'SHARE',
          onPressed: () => _shareFile(csvFile),
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

### Complete PDF Export Flow
```dart
Future<void> _exportAsPDF() async {
  if (!mounted) return;
  
  try {
    _showLoadingDialog('Exporting to PDF...');
    
    final statsProvider = context.read<StatisticsProvider>();
    final detections = await StatisticsService().getDetectionHistory();
    
    if (detections.isEmpty) {
      Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No detection data to export')),
      );
      return;
    }
    
    final pdfFile = await ExportService.exportToPDF(
      detections: detections,
      summary: statsProvider.summary,
      diseaseStats: statsProvider.diseaseStats,
    );
    
    Navigator.pop(context);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('PDF exported successfully'),
        action: SnackBarAction(
          label: 'SHARE',
          onPressed: () => _shareFile(pdfFile),
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

## Testing Recommendations

### Manual Testing Checklist
- [ ] Verify "Export Data" button appears in Statistics page
- [ ] Tap button and confirm dialog shows CSV and PDF options
- [ ] Select CSV export
- [ ] Loading dialog appears and disappears
- [ ] Success message shows with SHARE action
- [ ] Tap SHARE and system share dialog opens
- [ ] Repeat for PDF export
- [ ] Test with no detection history (should show empty message)
- [ ] Test share failure by denying permissions

### Data Validation
- [ ] CSV file contains correct headers
- [ ] CSV data is properly formatted
- [ ] PDF displays summary statistics correctly
- [ ] PDF shows disease breakdown table
- [ ] PDF shows detection history
- [ ] Timestamps are formatted correctly
- [ ] Confidence scores show 2 decimal places

---

## Troubleshooting

### CSV Export Empty
**Issue**: CSV file exports but has no data  
**Solution**: Check that `StatisticsService().getDetectionHistory()` returns data

### PDF Shows Blank Summary
**Issue**: PDF exports but summary section is empty  
**Solution**: Verify `StatisticsProvider.summary` has data before exporting

### Share Dialog Doesn't Appear
**Issue**: Share action doesn't open system dialog  
**Solution**: 
- Ensure `share_plus` package is installed
- Check platform-specific permissions
- Verify app has file access rights

### Null Exception in Export
**Issue**: Export throws null exception  
**Solution**:
- Add null checks for optional fields
- Verify detection data structure matches expectations
- Check that summary keys are correct

---

## Next Steps

### Enhancements to Consider
1. **Email Integration**: Send exports directly via email
2. **Cloud Backup**: Save exports to cloud storage
3. **Scheduled Exports**: Automatic periodic exports
4. **Custom Filters**: Export specific date ranges or diseases
5. **Multiple Formats**: Add Excel, JSON formats

### Phase 2.3: Push Notifications
Next phase will implement:
- Background notification service
- Disease alert notifications
- Notification scheduling
- User preference settings

---

## Summary

Phase 2.2 successfully integrates comprehensive data export functionality into AgriSense with:
- ✅ CSV export for data analysis
- ✅ PDF reports for sharing
- ✅ System integration for easy file sharing
- ✅ Professional UI/UX with loading states
- ✅ Comprehensive error handling
- ✅ Real data integration from detection history

The feature is production-ready and provides users with powerful tools to export and share their agricultural analysis data.
