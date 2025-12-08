# Phase 2.2: Data Export - Visual Guide & Architecture

## UI Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│           STATISTICS PAGE                                    │
│  ┌───────────────────────────────────────────────────────┐   │
│  │ Summary Cards                                         │   │
│  │  [25]    [3]     [68%]   [32%]                       │   │
│  │ Total  Diseases Healthy Disease                       │   │
│  └───────────────────────────────────────────────────────┘   │
│  ┌───────────────────────────────────────────────────────┐   │
│  │ Field Health Status: 68% ✅ Excellent               │   │
│  └───────────────────────────────────────────────────────┘   │
│  ┌───────────────────────────────────────────────────────┐   │
│  │ Disease Distribution (Pie Chart)                      │   │
│  └───────────────────────────────────────────────────────┘   │
│  ┌───────────────────────────────────────────────────────┐   │
│  │ Disease Rankings (Table)                              │   │
│  └───────────────────────────────────────────────────────┘   │
│  ┌───────────────────────────────────────────────────────┐   │
│  │ Detection Timeline (Line Chart)                       │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────┬──────────────────┐                     │
│  │  📥 EXPORT DATA │ 🗑️ CLEAR HISTORY │                     │
│  └─────────────────┴──────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
         │
         │ User taps "Export Data"
         ↓
┌─────────────────────────────────────┐
│  EXPORT OPTIONS DIALOG              │
│                                     │
│  Choose export format:              │
│                                     │
│  ┌────────────────────────────────┐ │
│  │ Cancel  [CSV]  [PDF]           │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
         │
         ├─ CSV selected     ├─ PDF selected
         ↓                   ↓
  ┌────────────────┐   ┌─────────────────┐
  │ LOADING DIALOG │   │ LOADING DIALOG  │
  │ 🔄             │   │ 🔄              │
  │ Exporting to   │   │ Exporting to    │
  │ CSV...         │   │ PDF...          │
  └────────────────┘   └─────────────────┘
         │                   │
         ↓                   ↓
  ┌────────────────┐   ┌─────────────────┐
  │ SUCCESS        │   │ SUCCESS         │
  │ ✅ CSV         │   │ ✅ PDF          │
  │ exported       │   │ exported        │
  │ [SHARE]        │   │ [SHARE]         │
  └────────────────┘   └─────────────────┘
         │                   │
         ├─ SHARE tapped    ├─ SHARE tapped
         ↓                   ↓
  ┌────────────────┐   ┌─────────────────┐
  │ SYSTEM SHARE   │   │ SYSTEM SHARE    │
  │ DIALOG         │   │ DIALOG          │
  │ - Gmail        │   │ - Gmail         │
  │ - WhatsApp     │   │ - WhatsApp      │
  │ - Drive        │   │ - Drive         │
  │ - Files        │   │ - Files         │
  └────────────────┘   └─────────────────┘
```

## Data Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATA SOURCES                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  SharedPreferences (via StatisticsService)                      │
│  ├─ detection_history (List of JSON strings)                   │
│  │  ├─ disease_label: "Powdery Mildew"                        │
│  │  ├─ confidence: 0.95                                        │
│  │  ├─ recommendation: "Apply fungicide"                       │
│  │  └─ timestamp: "2024-01-15T10:30:45.000Z"                 │
│  │                                                             │
│  │  ├─ disease_label: "Leaf Spot"                             │
│  │  ├─ confidence: 0.87                                        │
│  │  ├─ recommendation: "Improve ventilation"                   │
│  │  └─ timestamp: "2024-01-15T11:15:20.000Z"                 │
│  │                                                             │
│  └─ ... (more detections)                                      │
│                                                                 │
│  StatisticsProvider (ChangeNotifier)                            │
│  ├─ summary: Map<String, dynamic>                              │
│  │  ├─ total_detections: 25                                   │
│  │  ├─ healthy_percentage: "68.0"                             │
│  │  ├─ diseased_percentage: "32.0"                            │
│  │  ├─ unique_diseases: 3                                     │
│  │  └─ most_common_disease: "Leaf Spot"                       │
│  │                                                             │
│  ├─ diseaseStats: List<DiseaseStats>                          │
│  │  ├─ DiseaseStats(disease: "Leaf Spot", count: 8, ...)     │
│  │  ├─ DiseaseStats(disease: "Powdery Mildew", count: 6, ...) │
│  │  └─ DiseaseStats(disease: "Rust", count: 4, ...)          │
│  │                                                             │
│  └─ timelineData: List<TimelineData>                          │
│     ├─ TimelineData(date: 2024-01-01, count: 2)              │
│     ├─ TimelineData(date: 2024-01-02, count: 3)              │
│     └─ ... (30 days)                                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
         │
         │ StatisticsPage._exportAsCSV()
         │ StatisticsPage._exportAsPDF()
         ↓
┌─────────────────────────────────────────────────────────────────┐
│                   EXPORT SERVICE                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  exportToCSV(List<Map> detections)                             │
│  ├─ Process: Format → Rows → String → File                    │
│  ├─ Output: CSV file with headers and data                    │
│  └─ Save: /tmp/agrisense_detections_[timestamp].csv           │
│                                                                 │
│  exportToPDF(detections, summary, diseaseStats)                │
│  ├─ Process: Create Document → Add Pages → Format → File      │
│  ├─ Pages:                                                     │
│  │  ├─ Page 1: Summary + Disease Breakdown                    │
│  │  └─ Page 2: Detection History                              │
│  └─ Save: /tmp/agrisense_report_[timestamp].pdf               │
│                                                                 │
│  shareFile(File file)                                          │
│  ├─ Process: Open System Share Dialog                         │
│  └─ Options: Email, WhatsApp, Drive, Files, etc.             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
         │
         │ File generated and saved
         ↓
┌─────────────────────────────────────────────────────────────────┐
│          FILE SYSTEM (TEMPORARY DIRECTORY)                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  agrisense_detections_1705339445000.csv                        │
│  ├─ Date,Disease Label,Confidence,Recommendation,Timestamp   │
│  ├─ 2024-01-15 10:30:45,Powdery Mildew,0.95,...             │
│  ├─ 2024-01-15 11:15:20,Leaf Spot,0.87,...                  │
│  └─ ... (25 rows)                                             │
│                                                                 │
│  agrisense_report_1705339450000.pdf                            │
│  ├─ Page 1: Summary & Disease Analysis                        │
│  ├─ Page 2: Detection History Table                           │
│  └─ Generated: 2024-01-15 14:30:50                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
         │
         │ File ready for sharing
         ↓
┌─────────────────────────────────────────────────────────────────┐
│            SYSTEM SHARE DIALOG                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  User selects destination:                                      │
│  - Email client                                               │
│  - Cloud storage (Google Drive, OneDrive)                     │
│  - Messaging apps (WhatsApp, Telegram)                        │
│  - File manager                                               │
│  - Other apps                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## CSV Format Structure

```
┌──────────────────────────────────────────────────────────────────┐
│ DETECTION HISTORY EXPORT (CSV)                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│ Date              │Disease Label    │Confidence│Recommendation  │
├──────────────────────────────────────────────────────────────────┤
│ 2024-01-15 10:30:45 │ Powdery Mildew │ 0.95   │ Apply fungicide│
│ 2024-01-15 11:15:20 │ Leaf Spot      │ 0.87   │ Improve ventilation
│ 2024-01-15 14:22:10 │ Rust           │ 0.92   │ Use sulfur dust│
│ 2024-01-16 09:45:15 │ Powdery Mildew │ 0.91   │ Apply fungicide│
│ 2024-01-16 13:30:40 │ Healthy Leaf   │ 0.98   │ None           │
│ ...                                                             │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## PDF Report Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│              AgriSense Detection Report                          │
│                                                                 │
│  Generated: 2024-01-15 14:30:50                                │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Summary                                                        │
│  ┌────────────────────────┬──────────────────┐                │
│  │ Metric                 │ Value            │                │
│  ├────────────────────────┼──────────────────┤                │
│  │ Total Detections       │ 25               │                │
│  │ Unique Diseases        │ 3                │                │
│  │ Healthy (%)            │ 68.0%            │                │
│  │ Diseased (%)           │ 32.0%            │                │
│  │ Most Common Disease    │ Leaf Spot        │                │
│  └────────────────────────┴──────────────────┘                │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Disease Breakdown                                             │
│  ┌──────────────┬────────┬───────────┐                        │
│  │ Disease      │ Count  │ Percentage│                        │
│  ├──────────────┼────────┼───────────┤                        │
│  │ Leaf Spot    │ 8      │ 32.00%    │                        │
│  │ Powdery Mid. │ 6      │ 24.00%    │                        │
│  │ Rust         │ 4      │ 16.00%    │                        │
│  └──────────────┴────────┴───────────┘                        │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Detection History (First 20)                                  │
│  ┌──────────┬──────────────┬────────┬─────────────────┐       │
│  │ Date     │ Disease      │ Conf.  │ Recommendation  │       │
│  ├──────────┼──────────────┼────────┼─────────────────┤       │
│  │ 2024-01-15│Powdery Mildew│ 0.95  │ Apply fungicide │       │
│  │ 2024-01-15│Leaf Spot    │ 0.87   │ Improve ventil. │       │
│  │ ...      │ ...          │ ...    │ ...             │       │
│  └──────────┴──────────────┴────────┴─────────────────┘       │
│                                                                 │
│  Note: Showing first 20 detections.                           │
│  Export CSV for complete history.                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Class Diagram

```
┌──────────────────────┐
│  ExportService       │
├──────────────────────┤
│ (static methods)     │
├──────────────────────┤
│ + exportToCSV()      │
│ + exportToPDF()      │
│ + shareFile()        │
│ + exportBoth()       │
└──────────────────────┘

┌──────────────────────┐
│ StatisticsPage       │
├──────────────────────┤
│ - Consumer           │
│   <StatisticsProvider│
│                      │
│ Methods:             │
│ - _showExportOptions()
│ - _exportAsCSV()     │
│ - _exportAsPDF()     │
│ - _shareFile()       │
│ - _showLoadingDialog()
│ - _showClearConfirm()
└──────────────────────┘
         │
         │ uses
         ↓
┌──────────────────────┐
│ StatisticsProvider   │
├──────────────────────┤
│ - summary            │
│ - diseaseStats       │
│ - timelineData       │
│ - isLoading          │
│ - error              │
├──────────────────────┤
│ + loadStatistics()   │
│ + addDetection()     │
│ + clearHistory()     │
│ + exportAsJson()     │
└──────────────────────┘
         │
         │ reads from
         ↓
┌──────────────────────┐
│ StatisticsService    │
├──────────────────────┤
│ - _prefs (shared)    │
│ - _historyKey        │
├──────────────────────┤
│ + getDetectionHistory()
│ + getDiseaseStats()  │
│ + getTimelineData()  │
│ + getSummary()       │
│ + addDetection()     │
│ + clearHistory()     │
│ + exportAsJson()     │
└──────────────────────┘
         │
         │ reads from
         ↓
┌──────────────────────┐
│ SharedPreferences    │
├──────────────────────┤
│ detection_history    │
│ (List<String> JSON)  │
└──────────────────────┘
```

## Sequence Diagram

```
User              StatisticsPage      ExportService      FileSystem
  │                    │                    │                 │
  ├─ Tap "Export" ────→│                    │                 │
  │                    │                    │                 │
  │                    ├─ Show Dialog ─────→ User             │
  │                    │                    │                 │
  │                    │←─ Select CSV ──────┤                 │
  │                    │                    │                 │
  │                    ├─ Show Loading ────→ User             │
  │                    │                    │                 │
  │                    ├─ Get Data ────────→│                 │
  │                    │←─ Return Data ─────┤                 │
  │                    │                    │                 │
  │                    ├─ exportToCSV() ───→│                 │
  │                    │                    │                 │
  │                    │                    ├─ Format Data    │
  │                    │                    │                 │
  │                    │                    ├─ Create File ──→│
  │                    │                    │                 │
  │                    │                    ├─ Write Data ───→│
  │                    │                    │                 │
  │                    │←─ Return File ─────┤                 │
  │                    │                    │                 │
  │                    ├─ Close Loading    │                 │
  │                    │                    │                 │
  │                    ├─ Show Success ────→ User             │
  │                    │                    │                 │
  │                    │←─ Tap SHARE ──────┤                 │
  │                    │                    │                 │
  │                    ├─ shareFile() ─────→│                 │
  │                    │                    │                 │
  │                    │                    ├─ Open System    │
  │                    │                    │  Share Dialog   │
  │                    │                    │                 │
  │                    │                    ├─────────────────→ User
```

## State Flow

```
                    ┌─────────────────┐
                    │  INITIAL STATE  │
                    │ isLoading: false│
                    │ error: null     │
                    └────────┬────────┘
                             │
                             ↓
                    ┌─────────────────┐
                    │ User taps Export│
                    └────────┬────────┘
                             │
                             ↓
                    ┌─────────────────┐
                    │ Show Dialog     │
                    │ (User chooses)  │
                    └────────┬────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
      CSV selected      PDF selected     Cancel
           │                 │                 │
           ↓                 ↓                 ↓
   ┌──────────────┐  ┌──────────────┐  Return to
   │Show Loading  │  │Show Loading  │  Normal State
   │Exporting to  │  │Exporting to  │
   │CSV...        │  │PDF...        │
   └──────┬───────┘  └──────┬───────┘
          │                 │
          ↓                 ↓
   ┌──────────────┐  ┌──────────────┐
   │ Export CSV   │  │ Export PDF   │
   │ (async)      │  │ (async)      │
   └──────┬───────┘  └──────┬───────┘
          │                 │
    ┌─────┴─────┐     ┌─────┴─────┐
    │           │     │           │
Success        Error Success      Error
    │           │     │           │
    ↓           ↓     ↓           ↓
Close       Show    Close       Show
Loading     Error   Loading     Error
Dialog      Message Dialog      Message
    │           │     │           │
    ↓           ↓     ↓           ↓
Show        Return Show        Return
Success     to Norm Success     to Norm
Message     State   Message     State
with SHARE        with SHARE
option            option
```

---

## Summary

The Data Export feature provides a complete, user-friendly solution for exporting agricultural data in multiple formats with professional presentation and seamless system integration.
