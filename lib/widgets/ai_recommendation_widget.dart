import 'package:flutter/material.dart';
import 'dart:math';
import '../detection_service.dart';
import '../gemini_service.dart';
import '../services/supabase_service.dart';
import 'package:agrisense/utils/app_log.dart';

// =============================================================
// AI RECOMMENDATION WIDGET
// Handles: Hybrid auto/manual recommendation logic + UI
// Manages: GeminiService calls, caching, forced refresh, loading state
// Scalable: Works with single or multiple disease detections
// =============================================================
class AIRecommendationWidget extends StatefulWidget {
  final List<NormalizedDetection> currentDetections;
  final NormalizedDetection? lastDetectionPersistent;
  final bool isCurrentlyDetected;
  final VoidCallback onDiseaseCleared;

  const AIRecommendationWidget({
    super.key,
    required this.currentDetections,
    required this.lastDetectionPersistent,
    required this.isCurrentlyDetected,
    required this.onDiseaseCleared,
  });

  @override
  State<AIRecommendationWidget> createState() =>
      _AIRecommendationWidgetState();
}

class _AIRecommendationWidgetState extends State<AIRecommendationWidget> {
  String _geminiText = "";
  bool _isLoadingAI = false;

  // Selected disease label for AI requests when multiple diseases are detected.
  // null means "All detected diseases".
  String? _selectedDiseaseLabel;

  @override
  void didUpdateWidget(AIRecommendationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When disease changes, clear old AI text
    // Only clear if switching between different DISEASES (not when going to/from healthy)
    if (oldWidget.lastDetectionPersistent != null &&
        widget.lastDetectionPersistent != null &&
        oldWidget.lastDetectionPersistent!.label !=
            widget.lastDetectionPersistent!.label) {
      final isOldHealthy = _isHealthyLabel(oldWidget.lastDetectionPersistent!.label);
      final isNewHealthy = _isHealthyLabel(widget.lastDetectionPersistent!.label);
      
      // Only clear AI text if BOTH are diseases (different diseases)
      // Don't clear if switching to/from healthy (preserve AI text)
      if (!isOldHealthy && !isNewHealthy) {
        // Both are diseases but different ones - clear old text
        setState(() => _geminiText = "");
      }
    }

    // When disease is cleared entirely
    if (oldWidget.lastDetectionPersistent != null &&
        widget.lastDetectionPersistent == null) {
      widget.onDiseaseCleared();
    }
  }

  /// Check if a label represents a healthy plant
  bool _isHealthyLabel(String label) {
    final normalizedLabel = label.toLowerCase().trim();
    return normalizedLabel == 'healthy' || normalizedLabel.contains('healthy');
  }

  // User manually requested a fresh recommendation (force refresh)
  Future<void> _requestAIRecommendation() async {
    if (widget.lastDetectionPersistent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No disease detected. Healthy plant!")),
      );
      return;
    }

    // Use current detections if available, otherwise fall back to the persistent one.
    final baseDetections = widget.currentDetections.isNotEmpty
        ? widget.currentDetections
        : [widget.lastDetectionPersistent!];

    // Filter out healthy for AI tips.
    final diseaseDetections = baseDetections
        .where((d) => !_isHealthyLabel(d.label))
        .toList();

    // If user selected a specific disease, only analyze that disease.
    final detectionsToAnalyze = (_selectedDiseaseLabel == null)
        ? diseaseDetections
        : diseaseDetections
            .where((d) => d.label == _selectedDiseaseLabel)
            .toList();

    if (detectionsToAnalyze.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No disease selected to analyze.")),
      );
      return;
    }

    setState(() => _isLoadingAI = true);

    try {
      final ai = await GeminiService.generateMultipleRecommendation(
        detectionsToAnalyze,
        forceRefresh: true, // User explicitly asked for tips
      );

      // ✅ UPDATE the solution column of the latest detection record
      if (ai.isNotEmpty && widget.lastDetectionPersistent != null) {
        try {
          final supabase = SupabaseService();
          final diseaseLabel = (_selectedDiseaseLabel ?? widget.lastDetectionPersistent!.label);
          
          appLog('📝 About to save recommendation for disease: "$diseaseLabel"');
          appLog('💡 Recommendation text: "${ai.substring(0, min(100, ai.length))}"');
          
          // Get the latest detection ID for this disease
          final detectionId = await supabase.getLatestDetectionId(diseaseLabel);
          
          if (detectionId != null) {
            // Update the solution column of the existing detection
            final success = await supabase.updateDetectionSolution(
              detectionId: detectionId,
              solution: ai,
            );
            
            if (success) {
              appLog('✅ Successfully updated solution for detection ID: $detectionId');
            } else {
              appLog('❌ Failed to update solution in database');
            }
          } else {
            appLog('⚠️ No detection found for label: "$diseaseLabel" - cannot update solution');
          }
        } catch (e) {
          appLog('❌ Exception while saving recommendation: $e');
        }
      } else {
        appLog('⚠️ Skipped save: ai.isEmpty=${ai.isEmpty}, lastDetection=${widget.lastDetectionPersistent == null}');
      }

      if (mounted) {
        setState(() {
          _geminiText = ai;
          _isLoadingAI = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✓ Recommendation updated")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error getting AI recommendation: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the state: no detection, healthy, or disease
    final hasDetection = widget.lastDetectionPersistent != null;
    final isHealthy = hasDetection && _isHealthyLabel(widget.lastDetectionPersistent!.label);
    final isDisease = hasDetection && !isHealthy;

    // Build unique disease labels for selector.
    final uniqueDiseaseLabels = widget.currentDetections
        .where((d) => !_isHealthyLabel(d.label))
        .map((d) => d.label)
        .toSet()
        .toList();

    // Keep selection valid when detections change.
    if (_selectedDiseaseLabel != null &&
        !uniqueDiseaseLabels.contains(_selectedDiseaseLabel)) {
      _selectedDiseaseLabel = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "AI Recommendations",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.shade50,
                Colors.yellow.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            hasDetection
                                ? (isHealthy ? Icons.check_circle : Icons.lightbulb)
                                : Icons.camera_alt,
                            color: hasDetection
                                ? (isHealthy ? Colors.green.shade600 : Colors.orange.shade600)
                                : Colors.grey.shade400,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasDetection
                                  ? (isHealthy ? "Plant Status" : "Get AI Tips")
                                  : "Ready to Scan",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasDetection
                                  ? widget.lastDetectionPersistent!.label
                                  : "Point at a plant",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: hasDetection
                                    ? (isHealthy ? Colors.green.shade700 : Colors.orange.shade700)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: hasDetection
                            ? (isHealthy
                                ? Colors.green.shade100
                                : (widget.isCurrentlyDetected
                                    ? Colors.red.shade100
                                    : Colors.grey.shade200))
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasDetection
                              ? (isHealthy
                                  ? Colors.green.shade400
                                  : (widget.isCurrentlyDetected
                                      ? Colors.red.shade400
                                      : Colors.grey.shade400))
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        hasDetection
                            ? (isHealthy
                                ? "✅ Healthy"
                                : (widget.isCurrentlyDetected ? "🔴 Active" : "⏸️ Resolved"))
                            : "👀 Idle",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasDetection
                              ? (isHealthy
                                  ? Colors.green.shade700
                                  : (widget.isCurrentlyDetected
                                      ? Colors.red.shade700
                                      : Colors.grey.shade700))
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CASE 1: No detection - Idle message
                if (!hasDetection)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🎯 Point your camera at a plant leaf to get started. I'll analyze it and provide care recommendations!",
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  )
                // CASE 2: Healthy leaf - Status message
                else if (isHealthy)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "✅ Your plant looks healthy! No disease detected. Keep up the good care!",
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  )
                // CASE 3: Disease detected - Show AI recommendation text
                else if (_geminiText.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _geminiText,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // When multiple diseases are detected, let user choose which one to ask AI about.
                if (isDisease && uniqueDiseaseLabels.length > 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt, size: 18, color: Colors.orange.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              isExpanded: true,
                              value: _selectedDiseaseLabel,
                              hint: const Text('All detected diseases'),
                              items: <DropdownMenuItem<String?>>[
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All detected diseases'),
                                ),
                                ...uniqueDiseaseLabels.map(
                                  (label) => DropdownMenuItem<String?>(
                                    value: label,
                                    child: Text(label),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDiseaseLabel = value;
                                  _geminiText = ""; // Clear old result when target changes
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action button - only show for diseases, not for healthy leaves or no detection
                if (isDisease)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingAI ? null : _requestAIRecommendation,
                      icon: _isLoadingAI
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange.shade600,
                                ),
                              ),
                            )
                          : Icon(Icons.auto_awesome, color: Colors.orange.shade600),
                      label: Text(
                        _isLoadingAI ? 'Getting Recommendation...' : 'Get Recommendation',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                // Helper text - only for diseases
                if (isDisease && _geminiText.isEmpty && !_isLoadingAI)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      widget.isCurrentlyDetected
                          ? "⚠️ Disease detected! Click the button to get AI-powered treatment recommendations."
                          : "ℹ️ Disease was detected earlier. Click the button to review AI-powered recommendations.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
