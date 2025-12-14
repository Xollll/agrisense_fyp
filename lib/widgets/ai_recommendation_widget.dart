import 'package:flutter/material.dart';
import '../detection_service.dart';
import '../gemini_service.dart';
import '../services/supabase_service.dart';

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

  @override
  void didUpdateWidget(AIRecommendationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When disease changes, clear old AI text
    if (oldWidget.lastDetectionPersistent != null &&
        widget.lastDetectionPersistent != null &&
        oldWidget.lastDetectionPersistent!.label !=
            widget.lastDetectionPersistent!.label) {
      setState(() => _geminiText = "");
    }

    // When disease is cleared entirely
    if (oldWidget.lastDetectionPersistent != null &&
        widget.lastDetectionPersistent == null) {
      widget.onDiseaseCleared();
    }
  }

  // User manually requested a fresh recommendation (force refresh)
  Future<void> _requestAIRecommendation() async {
    if (widget.lastDetectionPersistent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No disease detected. Healthy plant!")),
      );
      return;
    }

    final detectionsToAnalyze = widget.currentDetections.isNotEmpty
        ? widget.currentDetections
        : [widget.lastDetectionPersistent!];

    setState(() => _isLoadingAI = true);

    try {
      // User triggered = FORCE REFRESH (ignore cache)
      // Hybrid system will:
      // 1. Build smart cache key (disease names + rounded confidence)
      // 2. Detect if anything changed significantly
      // 3. If forceRefresh=true, always generate fresh
      final ai = await GeminiService.generateMultipleRecommendation(
        detectionsToAnalyze,
        forceRefresh: true, // User explicitly asked for tips
      );

      // ✅ OPTION A: Save recommendation to Supabase
      if (ai.isNotEmpty && widget.lastDetectionPersistent != null) {
        try {
          final supabase = SupabaseService();
          await supabase.saveDetection(
            label: widget.lastDetectionPersistent!.label,
            confidence: widget.lastDetectionPersistent!.confidence,
            solution: ai,
            timestamp: DateTime.now().toIso8601String(),
          );
          print('✅ Recommendation saved to Supabase');
        } catch (e) {
          print('⚠️ Failed to save recommendation to Supabase: $e');
        }
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
    // Show healthy plant message if no disease ever detected
    if (widget.lastDetectionPersistent == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.green.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Plant Status",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "✅ Your plant looks healthy! No disease detected. Keep up the good care!",
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show AI recommendations when disease is detected
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
                color: Colors.orange.withOpacity(0.1),
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
                            Icons.lightbulb,
                            color: Colors.orange.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Get AI Tips",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.currentDetections.isEmpty
                                  ? widget.lastDetectionPersistent!.label
                                  : "${widget.currentDetections.length} issue${widget.currentDetections.length > 1 ? 's' : ''} found",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
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
                        color: widget.isCurrentlyDetected
                            ? Colors.red.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.isCurrentlyDetected
                              ? Colors.red.shade400
                              : Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.isCurrentlyDetected
                            ? "🔴 Active"
                            : "⏸️ Resolved",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.isCurrentlyDetected
                              ? Colors.red.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // AI Recommendation text (if available)
                if (_geminiText.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _geminiText,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Action button
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
                        : Icon(Icons.auto_awesome,
                            color: Colors.orange.shade600),
                    label: Text(
                      _isLoadingAI ? 'Getting Recommendation...' : 'Ask AI Again',
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

                // Helper text
                if (_geminiText.isEmpty && !_isLoadingAI)
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
