// lib/pages/history_page.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

/// Returns the DIAGNOSIS CONFIDENCE color (how sure the model is)
Color _getDiagnosisConfidenceColor(double confidence) {
  if (confidence >= 0.8) return const Color(0xFF06B6D4); // Strong confidence
  if (confidence >= 0.6) return const Color(0xFF0EA5E9); // Moderate confidence
  if (confidence >= 0.4) return const Color(0xFFF59E0B); // Weak confidence
  return const Color(0xFFEF4444); // Very weak confidence
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
    if (_selectedFilter == 'All') return items;
    
    return items.where((item) {
      final confidence = (item['confidence'] is num)
          ? (item['confidence'] as num).toDouble()
          : double.tryParse('${item['confidence']}') ?? 0.0;
      
      if (_selectedFilter == 'Healthy') return confidence >= 0.75;
      if (_selectedFilter == 'Warning') return confidence >= 0.5 && confidence < 0.75;
      if (_selectedFilter == 'Critical') return confidence < 0.5;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: const SizedBox.shrink(),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.history, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Detection History",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Your detection records",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _refreshDetectionHistory,
                    tooltip: "Refresh data",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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

          return Column(
            children: [
              // Modern filter pills
              SizedBox(
                height: 50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: ['All', 'Healthy', 'Warning', 'Critical']
                        .map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filter);
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              // Detection count info
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredDetections.length} detection${filteredDetections.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),

              // List view
              Expanded(
                child: filteredDetections.isEmpty
                    ? Center(
                        child: Text(
                          'No ${_selectedFilter.toLowerCase()} detections',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filteredDetections.length,
                        itemBuilder: (context, index) {
                          final item = filteredDetections[index];
                          final label = item['label'] ?? 'Unknown';
                          final confidence = (item['confidence'] is num)
                              ? (item['confidence'] as num).toDouble()
                              : double.tryParse('${item['confidence']}') ?? 0.0;
                          final solution = item['solution'] ?? '';
                          final timestamp = item['timestamp'] ?? '';

                          return _DetectionCard(
                            label: label,
                            confidence: confidence,
                            timestamp: timestamp,
                            solution: solution,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
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

  @override
  Widget build(BuildContext context) {
    final healthStatusColor = _getHealthStatusColor(label);
    final healthStatus = _getHealthStatusLabel(label);
    final diagnosisConfidenceColor = _getDiagnosisConfidenceColor(confidence);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = timestamp.contains("T") ? timestamp.split("T").first : timestamp;

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
                // Header: Disease name + Health Status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Color dot indicator (Health Status)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: healthStatusColor,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: healthStatusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        healthStatus,
                        style: TextStyle(
                          color: healthStatusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 14),

                // Diagnosis Confidence bar (how sure the model is)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Diagnosis Confidence',
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
                        valueColor: AlwaysStoppedAnimation<Color>(diagnosisConfidenceColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How confident the AI is in this diagnosis',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),

                // Solution preview
                if (solution.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    solution.length > 100
                        ? solution.substring(0, 100) + '...'
                        : solution,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          height: 1.5,
                        ),
                  ),
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

  void _showDetailsModal(BuildContext context) {
    final healthStatusColor = _getHealthStatusColor(label);
    final healthStatus = _getHealthStatusLabel(label);
    final diagnosisConfidenceColor = _getDiagnosisConfidenceColor(confidence);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = timestamp.contains("T") ? timestamp.split("T").first : timestamp;

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

                // Header
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: healthStatusColor,
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
                        color: healthStatusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        healthStatus,
                        style: TextStyle(
                          color: healthStatusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
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
                  'Diagnosis Confidence',
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
                          valueColor: AlwaysStoppedAnimation<Color>(diagnosisConfidenceColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  'How confident the AI model is in this diagnosis',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                ),

                const SizedBox(height: 24),

                // Solution section
                Text(
                  'Recommended Solution',
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
                    solution.isEmpty ? 'No solution available' : solution,
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
