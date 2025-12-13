// smart_ai_recommendation_widget.dart
//
// User-facing widget for AI recommendations with manual trigger
// ==============================================================
// Features:
// - Displays cached or auto-generated recommendation
// - "Ask AI Again" button for manual refresh
// - Loading state with elegant animation
// - Error handling with retry
// - Shows when AI was last generated

import 'package:flutter/material.dart';
import '../detection_service.dart';
import '../services/ai_recommendation_service.dart';

class SmartAIRecommendationWidget extends StatefulWidget {
  final NormalizedDetection detection;
  final VoidCallback? onRecommendationUpdated;

  const SmartAIRecommendationWidget({
    super.key,
    required this.detection,
    this.onRecommendationUpdated,
  });

  @override
  State<SmartAIRecommendationWidget> createState() =>
      _SmartAIRecommendationWidgetState();
}

class _SmartAIRecommendationWidgetState
    extends State<SmartAIRecommendationWidget>
    with SingleTickerProviderStateMixin {
  String? _recommendation;
  bool _isLoading = false;
  bool _isManualRefresh = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadRecommendation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendation() async {
    setState(() => _isLoading = true);
    _animationController.forward();

    try {
      // Try to get cached recommendation first
      final cached = AIRecommendationService.getCachedRecommendation(
        widget.detection.label,
      );

      if (cached != null) {
        setState(() => _recommendation = cached);
      } else {
        // No cache available, recommendation will be generated via automatic trigger
        // during the polling cycle
        setState(() =>
            _recommendation =
                'Recommendation will be generated automatically for new diseases.');
      }
    } catch (e) {
      setState(() => _recommendation = 'Error loading recommendation: $e');
    } finally {
      setState(() => _isLoading = false);
      _animationController.reverse();
    }
  }

  Future<void> _manuallyRequestAI() async {
    setState(() {
      _isLoading = true;
      _isManualRefresh = true;
    });
    _animationController.forward();

    try {
      final recommendation =
          await AIRecommendationService.manuallyRequestAI(widget.detection);
      setState(() => _recommendation = recommendation);
      widget.onRecommendationUpdated?.call();

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Fresh recommendation generated!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _recommendation = 'Error generating recommendation: $e');

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isManualRefresh = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      ),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: isDarkMode
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFFAFAFA),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Recommendation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.amber[600]!,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Recommendation content
              if (_recommendation != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey[900]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _recommendation!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 12),
              ] else if (!_isLoading) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey[900]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Recommendation will be generated automatically for new diseases. Use the button below to request a fresh analysis.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _manuallyRequestAI,
                  icon: _isManualRefresh
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _isManualRefresh
                        ? 'Generating...'
                        : 'Ask AI Again',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Info text
              const SizedBox(height: 8),
              Text(
                '💡 Tip: AI is automatically triggered only for new diseases. Click above to request a fresh analysis anytime.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
