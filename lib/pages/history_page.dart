// lib/pages/history_page.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../widgets/enhanced_app_bar.dart';

// ============================================================
// SEVERITY CLASSIFICATION ENUM & LOGIC
// ============================================================

enum SeverityType { healthy, low, warning, critical }

/// Classifies detection severity based on BOTH label AND confidence
/// 
/// Rules:
/// - If label is "healthy" → Always HEALTHY (green)
/// - If disease detected:
///   - confidence >= 0.80 → CRITICAL (red)
///   - confidence 0.50-0.79 → WARNING (yellow)
///   - confidence < 0.50 → LOW (green)
SeverityType classifySeverity(String label, double confidence) {
  final normalized = label.toLowerCase().trim();

  // Healthy should ALWAYS be healthy severity, regardless of confidence
  if (normalized == 'healthy' || normalized == 'normal' || normalized == 'good') {
    return SeverityType.healthy;
  }

  // Disease severity based on confidence
  if (confidence >= 0.80) return SeverityType.critical;
  if (confidence >= 0.50) return SeverityType.warning;
  
  return SeverityType.low;
}

/// Returns color for severity badge
Color _getSeverityColor(SeverityType severity) {
  switch (severity) {
    case SeverityType.healthy:
      return const Color(0xFF10B981); // Green
    case SeverityType.low:
      return const Color(0xFF10B981); // Green
    case SeverityType.warning:
      return const Color(0xFFF59E0B); // Yellow/Amber
    case SeverityType.critical:
      return const Color(0xFFDC2626); // Red
  }
}

/// Returns text label for severity badge
String _getSeverityLabel(SeverityType severity) {
  switch (severity) {
    case SeverityType.healthy:
      return 'Healthy';
    case SeverityType.low:
      return 'Low Risk';
    case SeverityType.warning:
      return 'Warning';
    case SeverityType.critical:
      return 'Critical';
  }
}

/// Returns a user-friendly story based on label and severity
String _getSeverityStory(String label, SeverityType severity) {
  final normalizedLabel = label.toLowerCase().trim();
  
  if (normalizedLabel == 'healthy' || normalizedLabel == 'normal' || normalizedLabel == 'good') {
    return 'Your plant looks healthy. No action needed.';
  }
  
  switch (severity) {
    case SeverityType.healthy:
      return 'Your plant looks healthy. No action needed.';
    case SeverityType.critical:
      return 'Severe disease detected. Immediate action recommended.';
    case SeverityType.warning:
      return 'Early symptoms detected. Monitor closely.';
    case SeverityType.low:
      return 'Minor symptoms detected. Monitor casually.';
  }
}

/// Returns the DIAGNOSIS CONFIDENCE color (how sure the model is)
///
/// NOTE:
/// Users were interpreting this color as a "risk" indicator.
/// To keep UI consistent with the Severity badge (Low=green, Warning=yellow, Critical=red),
/// this now maps confidence colors to the same thresholds used by [classifySeverity].
Color _getDiagnosisConfidenceColor(double confidence, {String? label}) {
  // Keep explicit "healthy" always green.
  if (label != null) {
    final normalized = label.toLowerCase().trim();
    if (normalized == 'healthy' || normalized == 'normal' || normalized == 'good') {
      return const Color(0xFF10B981); // Green
    }
  }

  // Match severity thresholds:
  // <0.50 => Low Risk (green)
  // 0.50-0.79 => Warning (yellow)
  // >=0.80 => Critical (red)
  if (confidence >= 0.80) return const Color(0xFFDC2626); // Red
  if (confidence >= 0.50) return const Color(0xFFF59E0B); // Yellow/Amber
  if (confidence >= 0.0) return const Color(0xFF10B981); // Green

  // Fallback (shouldn't normally happen)
  return const Color(0xFFF59E0B); // Orange
}

/// Returns the HEALTH STATUS based on label
/// This tells us if the plant is healthy or has a disease
Color _getHealthStatusColor(String label) {
  final lowerLabel = label.toLowerCase();
  
  // If label indicates disease or problem
  if (lowerLabel.contains('healthy') || lowerLabel.contains('normal') || lowerLabel.contains('good')) {
    return const Color(0xFF10B981); // Green = Healthy
  } else if (lowerLabel.contains('leaf') || lowerLabel.contains('spot') || lowerLabel.contains('blight')) {
    return const Color(0xFFDC2626); // Red = Disease detected
  } else if (lowerLabel.contains('curl') || lowerLabel.contains('wilt') || lowerLabel.contains('yellow')) {
    return const Color(0xFFEF4444); // Red = Disease detected
  }
  
  return const Color(0xFFF59E0B); // Orange = Unknown/Uncertain
}

String _getHealthStatusLabel(String label) {
  final lowerLabel = label.toLowerCase();
  
  if (lowerLabel.contains('healthy') || lowerLabel.contains('normal') || lowerLabel.contains('good')) {
    return 'Healthy';
  } else if (lowerLabel.contains('leaf') || lowerLabel.contains('spot') || lowerLabel.contains('blight') ||
             lowerLabel.contains('curl') || lowerLabel.contains('wilt') || lowerLabel.contains('yellow')) {
    return 'Disease Detected';
  }
  
  return 'Unknown';
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  String _sortBy = 'Newest'; // Newest, Oldest, Confidence
  bool _expandedToday = true;
  bool _expandedThisWeek = true;
  bool _expandedThisMonth = true;
  bool _expandedOlder = false;
  
  late SupabaseService _supabaseService;
  late Future<List<Map<String, dynamic>>> _detectionHistoryFuture;

  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService();
    _detectionHistoryFuture = _supabaseService.getDetectionHistory();
  }

  // Refresh the detection history
  void _refreshDetectionHistory() {
    setState(() {
      _detectionHistoryFuture = _supabaseService.getDetectionHistory();
    });
  }

  List<Map<String, dynamic>> _filterDetections(List<Map<String, dynamic>> items) {
    var filtered = items.toList();
    
    // Apply filter based on severity
    if (_selectedFilter != 'All') {
      filtered = filtered.where((item) {
        final label = (item['label'] ?? '').toString();
        final confidence = (item['confidence'] is num)
            ? (item['confidence'] as num).toDouble()
            : double.tryParse('${item['confidence']}') ?? 0.0;
        
        final severity = classifySeverity(label, confidence);
        final severityLabel = _getSeverityLabel(severity);
        
        return _selectedFilter == severityLabel;
      }).toList();
    }
    
    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final label = (item['label'] ?? '').toString().toLowerCase();
        return label.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply sorting
    if (_sortBy == 'Newest') {
      filtered.sort((a, b) => (b['timestamp'] ?? '').toString().compareTo((a['timestamp'] ?? '').toString()));
    } else if (_sortBy == 'Oldest') {
      filtered.sort((a, b) => (a['timestamp'] ?? '').toString().compareTo((b['timestamp'] ?? '').toString()));
    } else if (_sortBy == 'Confidence') {
      filtered.sort((a, b) {
        final confA = (a['confidence'] is num)
            ? (a['confidence'] as num).toDouble()
            : double.tryParse('${a['confidence']}') ?? 0.0;
        final confB = (b['confidence'] is num)
            ? (b['confidence'] as num).toDouble()
            : double.tryParse('${b['confidence']}') ?? 0.0;
        return confB.compareTo(confA);
      });
    }
    
    return filtered;
  }

  Map<String, List<Map<String, dynamic>>> _groupDetectionsByDate(List<Map<String, dynamic>> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = today.subtract(const Duration(days: 30));

    final grouped = <String, List<Map<String, dynamic>>>{
      'Today': [],
      'This Week': [],
      'This Month': [],
      'Older': [],
    };

    for (var item in items) {
      try {
        final timestamp = item['timestamp'] as String?;
        if (timestamp == null || timestamp.isEmpty) continue;
        
        final dateStr = timestamp.contains('T') ? timestamp.split('T')[0] : timestamp;
        final itemDate = DateTime.parse(dateStr);
        final itemDateOnly = DateTime(itemDate.year, itemDate.month, itemDate.day);

        if (itemDateOnly == today) {
          grouped['Today']!.add(item);
        } else if (itemDateOnly.isAfter(weekAgo)) {
          grouped['This Week']!.add(item);
        } else if (itemDateOnly.isAfter(monthAgo)) {
          grouped['This Month']!.add(item);
        } else {
          grouped['Older']!.add(item);
        }
      } catch (e) {
        grouped['Older']!.add(item);
      }
    }

    return grouped;
  }

  String _getDiseaseCountSummary(List<Map<String, dynamic>> items) {
    final Set<String> uniqueDiseases = {};
    for (var item in items) {
      final label = (item['label'] ?? '').toString().toLowerCase();
      if (label.isNotEmpty && !label.contains('healthy')) {
        uniqueDiseases.add(label);
      }
    }
    return '${uniqueDiseases.length} disease${uniqueDiseases.length != 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: RefreshIndicator(
        onRefresh: _refreshWithDelay,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Enhanced App Bar with Status Indicators
            SliverToBoxAdapter(
              child: AppBarBuilder.history(
                context: context,
                onMenuPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),

            // Pull-to-Refresh Content
            SliverFillRemaining(
              hasScrollBody: true,
              child: _buildHistoryContent(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshWithDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _refreshDetectionHistory();
  }

  Widget _buildHistoryContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _detectionHistoryFuture,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading detections...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        // Empty state
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history,
                    size: 50,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "No detections yet",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start scanning plants to build your history",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final detections = snapshot.data!;
        final filteredDetections = _filterDetections(detections);
        final groupedDetections = _groupDetectionsByDate(filteredDetections);

        return Column(
          children: [
            // Quick Stats Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${filteredDetections.length}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                        Text(
                          'Detections',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                    ),
                    Column(
                      children: [
                        Text(
                          _getDiseaseCountSummary(filteredDetections),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                        Text(
                          'Found',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Search & Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar + Sort Button Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search disease...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => setState(() => _searchQuery = ''),
                                    child: Icon(Icons.clear, color: Colors.grey.shade600),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Sort Dropdown Button
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          setState(() => _sortBy = value);
                        },
                        itemBuilder: (BuildContext context) {
                          return ['Newest', 'Oldest', 'Confidence']
                              .map((sort) => PopupMenuItem(
                                    value: sort,
                                    child: Text(
                                      sort,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ))
                              .toList();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Tooltip(
                            message: 'Sort: $_sortBy',
                            child: Icon(
                              Icons.sort,
                              color: Theme.of(context).primaryColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Healthy', 'Low Risk', 'Warning', 'Critical']
                          .map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedFilter = filter);
                            },
                            backgroundColor: Colors.grey.shade200,
                            selectedColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Timeline grouped detections
            Expanded(
              child: filteredDetections.isEmpty
                  ? Center(
                      child: Text(
                        'No detections found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                      child: Column(
                        children: [
                        // Today Section
                        if (groupedDetections['Today']!.isNotEmpty)
                          _buildDateSection(
                            context,
                            'Today',
                            groupedDetections['Today']!,
                            _expandedToday,
                            (value) => setState(() => _expandedToday = value),
                          ),
                        // This Week Section
                        if (groupedDetections['This Week']!.isNotEmpty)
                          _buildDateSection(
                            context,
                            'This Week',
                            groupedDetections['This Week']!,
                            _expandedThisWeek,
                            (value) => setState(() => _expandedThisWeek = value),
                          ),
                        // This Month Section
                        if (groupedDetections['This Month']!.isNotEmpty)
                          _buildDateSection(
                            context,
                            'This Month',
                            groupedDetections['This Month']!,
                            _expandedThisMonth,
                            (value) => setState(() => _expandedThisMonth = value),
                          ),
                        // Older Section
                        if (groupedDetections['Older']!.isNotEmpty)
                          _buildDateSection(
                            context,
                            'Older',
                            groupedDetections['Older']!,
                            _expandedOlder,
                            (value) => setState(() => _expandedOlder = value),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
    bool isExpanded,
    Function(bool) onExpandChanged,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => onExpandChanged(!isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${items.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          ...items.map((item) {
            final label = item['label'] ?? 'Unknown';
            final confidence = (item['confidence'] is num)
                ? (item['confidence'] as num).toDouble()
                : double.tryParse('${item['confidence']}') ?? 0.0;
            final solution = item['solution'] ?? '';
            final timestamp = item['timestamp'] ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DetectionCard(
                label: label,
                confidence: confidence,
                timestamp: timestamp,
                solution: solution,
              ),
            );
          }).toList(),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _DetectionCard extends StatelessWidget {
  final String label;
  final double confidence;
  final String timestamp;
  final String solution;

  const _DetectionCard({
    required this.label,
    required this.confidence,
    required this.timestamp,
    required this.solution,
  });

  /// Extract first 2-3 lines of recommendation
  String _getTruncatedSolution(String fullSolution, {int lines = 3}) {
    if (fullSolution.isEmpty) return '';
    final solLines = fullSolution.split('\n');
    final truncated = solLines.take(lines).join('\n');
    if (solLines.length > lines) {
      return truncated + '...';
    }
    return truncated;
  }

  @override
  Widget build(BuildContext context) {
    // Classify severity based on both label AND confidence
    final severity = classifySeverity(label, confidence);
    final severityColor = _getSeverityColor(severity);
    final severityLabel = _getSeverityLabel(severity);
    final storyText = _getSeverityStory(label, severity);

    final diagnosisConfidenceColor =
        _getDiagnosisConfidenceColor(confidence, label: label);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final formattedDate =
        timestamp.contains("T") ? timestamp.split("T").first : timestamp;
    final truncatedSolution = _getTruncatedSolution(solution);

    return GestureDetector(
      onTap: () => _showDetailsModal(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title + Date + Severity Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Severity Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: severityColor.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        severityLabel,
                        style: TextStyle(
                          color: severityColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),

                // Story Text
                Text(
                  storyText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                // Diagnosis Confidence bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Prediction Confidence',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                        ),
                        Text(
                          '${(confidence * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: diagnosisConfidenceColor,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: confidence,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(diagnosisConfidenceColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'How sure the AI is about the label (not disease severity).',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),

                // Truncated recommendation preview (if available)
                if (truncatedSolution.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Recommended Action',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    truncatedSolution,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                          fontSize: 12,
                          height: 1.5,
                        ),
                  ),
                  if (solution.split('\n').length > 3) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showFullRecommendationModal(context),
                      child: Text(
                        'View Full Recommendation',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 8),
                
                // Tap hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Tap for details',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullRecommendationModal(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Full Recommendation',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Full recommendation text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    solution.isEmpty ? 'No recommendation available' : solution,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.8,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailsModal(BuildContext context) {
    final severity = classifySeverity(label, confidence);
    final severityColor = _getSeverityColor(severity);
    final severityLabel = _getSeverityLabel(severity);
    final storyText = _getSeverityStory(label, severity);

    final healthStatusColor = _getHealthStatusColor(label);
    final healthStatus = _getHealthStatusLabel(label);
    final diagnosisConfidenceColor =
        _getDiagnosisConfidenceColor(confidence, label: label);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final formattedDate =
        timestamp.contains("T") ? timestamp.split("T").first : timestamp;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Header with Severity indicator
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: severityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        severityLabel,
                        style: TextStyle(
                          color: severityColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Story Text
                Text(
                  storyText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.5,
                      ),
                ),

                const SizedBox(height: 24),

                // Health Status section
                Text(
                  'Plant Health Status',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: healthStatusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          healthStatus == 'Healthy' ? Icons.check_circle : Icons.warning_amber,
                          color: healthStatusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              healthStatus,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: healthStatusColor,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              healthStatus == 'Healthy'
                                  ? 'Your plant appears to be in good condition'
                                  : 'Your plant may have health issues that need attention',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Diagnosis Confidence section
                Text(
                  'Prediction Confidence',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: confidence,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade300,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(diagnosisConfidenceColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: diagnosisConfidenceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: diagnosisConfidenceColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'How sure the AI is about this label (not disease severity).',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                ),

                const SizedBox(height: 24),

                // Recommendation section
                Text(
                  'Recommended Action',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    solution.isEmpty ? 'No recommendation available' : solution,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),

                const SizedBox(height: 24),

                // Details section
                Text(
                  'Detection Details',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Disease', label, isDarkMode),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Status', healthStatus, isDarkMode),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Severity', severityLabel, isDarkMode),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Date', formattedDate, isDarkMode),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
