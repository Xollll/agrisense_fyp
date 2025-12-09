import 'package:flutter/material.dart';
import '../detection_service.dart';
import 'mjpeg_stream.dart';
import 'modern_card.dart';
import '../theme/app_theme.dart';
import 'animated_live_indicator.dart';

// =============================================================
// LIVE STREAM WIDGET
// Handles: MJPEG camera stream + detection results UI only
// No AI API calls here - purely presentational
// Includes: Animated live indicator for connection status
// =============================================================
class LiveStreamWidget extends StatefulWidget {
  final List<NormalizedDetection> detections;
  final String streamUrl;

  const LiveStreamWidget({
    super.key,
    required this.detections,
    required this.streamUrl,
  });

  @override
  State<LiveStreamWidget> createState() => _LiveStreamWidgetState();
}

class _LiveStreamWidgetState extends State<LiveStreamWidget> {
  /// Current live status
  /// Determined by the actual MJPEG stream connection state
  LiveStatus _liveStatus = LiveStatus.disconnected;

  /// Callback for MJPEG stream to update status
  void _updateStreamStatus(bool isConnected, bool isConnecting) {
    if (!mounted) return;

    setState(() {
      if (isConnected) {
        // Stream is actively receiving video
        _liveStatus = LiveStatus.connected;
      } else if (isConnecting) {
        // Stream is attempting to connect
        _liveStatus = LiveStatus.connecting;
      } else {
        // Stream is disconnected or failed
        _liveStatus = LiveStatus.disconnected;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize status as disconnected (will be updated by MJPEGStream)
    _liveStatus = LiveStatus.disconnected;
  }

  @override
  void didUpdateWidget(LiveStreamWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to disconnected when stream URL changes
    if (oldWidget.streamUrl != widget.streamUrl) {
      setState(() {
        _liveStatus = LiveStatus.disconnected;
      });
    }
  }

  void _onLiveIndicatorTapped() {
    // Optional: Show more details about connection status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _liveStatus == LiveStatus.connected
              ? '✅ Camera is streaming live'
              : _liveStatus == LiveStatus.connecting
                  ? '⏳ Attempting to connect to camera'
                  : '❌ Camera is not connected. Check camera settings.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CAMERA STREAM CARD (Modern)
        ModernCard(
          padding: EdgeInsets.zero,
          borderRadius: 20,
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: MJPEGStream(
                    url: widget.streamUrl,
                    onStatusChanged: _updateStreamStatus,
                  ),
                ),
              ),
              // Animated Live Indicator (replaces static LIVE badge)
              Positioned(
                top: 16,
                right: 16,
                child: AnimatedLiveIndicator(
                  status: _liveStatus,
                  onTap: _onLiveIndicatorTapped,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // DETECTIONS SECTION HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Current Detections",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // DETECTIONS LIST
        widget.detections.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: AppColors.success.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No diseases detected",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Your plants look healthy!",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: widget.detections
                    .where((d) => d.label.toLowerCase() != "healthy")
                    .map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  d.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.warning.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    "${(d.confidence * 100).toStringAsFixed(0)}%",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: d.confidence,
                                minHeight: 6,
                                backgroundColor: AppColors.warning.withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
      ],
    );
  }
}
