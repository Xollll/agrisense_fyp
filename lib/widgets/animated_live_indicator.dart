import 'package:flutter/material.dart';

/// Animated Live Status Indicator Widget
/// Shows camera connection status with visual feedback
/// 
/// States:
/// - CONNECTED (Green): Camera is live, slowly flickering
/// - CONNECTING (Yellow): Attempting to connect, pulsing
/// - DISCONNECTED (Red): Camera not connected, static
class AnimatedLiveIndicator extends StatefulWidget {
  /// Current connection status
  final LiveStatus status;
  
  /// Optional callback when user taps the indicator
  final VoidCallback? onTap;

  const AnimatedLiveIndicator({
    super.key,
    required this.status,
    this.onTap,
  });

  @override
  State<AnimatedLiveIndicator> createState() => _AnimatedLiveIndicatorState();
}

/// Live connection status enum
enum LiveStatus {
  connected,    // Camera is live and streaming
  connecting,   // Attempting to connect to camera
  disconnected, // Camera is not connected
}

class _AnimatedLiveIndicatorState extends State<AnimatedLiveIndicator>
    with TickerProviderStateMixin {
  late AnimationController _flickerController;
  late AnimationController _pulseController;
  late Animation<double> _flickerAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Flicker animation (for CONNECTED state)
    // Makes the indicator blink slowly to show "live" status
    _flickerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _flickerAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut),
    );

    // Pulse animation (for CONNECTING state)
    // Makes the indicator pulse to show "waiting" status
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedLiveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update animations if status changes
    if (oldWidget.status != widget.status) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    switch (widget.status) {
      case LiveStatus.connected:
        _flickerController.forward();
        _pulseController.stop();
        break;
      case LiveStatus.connecting:
        _pulseController.forward();
        _flickerController.stop();
        break;
      case LiveStatus.disconnected:
        _flickerController.stop();
        _pulseController.stop();
        break;
    }
  }

  @override
  void dispose() {
    _flickerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case LiveStatus.connected:
        return Colors.green.shade500;
      case LiveStatus.connecting:
        return Colors.amber.shade500;
      case LiveStatus.disconnected:
        return Colors.red.shade500;
    }
  }

  String _getStatusText() {
    switch (widget.status) {
      case LiveStatus.connected:
        return "LIVE";
      case LiveStatus.connecting:
        return "CONNECTING...";
      case LiveStatus.disconnected:
        return "OFFLINE";
    }
  }

  String _getStatusSubtext() {
    switch (widget.status) {
      case LiveStatus.connected:
        return "Camera streaming";
      case LiveStatus.connecting:
        return "Attempting connection";
      case LiveStatus.disconnected:
        return "Camera not available";
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getStatusColor().withOpacity(0.8),
              _getStatusColor().withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _getStatusColor().withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Status Dot
            _buildStatusDot(),
            const SizedBox(width: 8),
            
            // Status Text
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _getStatusSubtext(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot() {
    switch (widget.status) {
      case LiveStatus.connected:
        // Flicker animation for connected
        return ScaleTransition(
          scale: _flickerAnimation,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );

      case LiveStatus.connecting:
        // Pulse animation for connecting
        return ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );

      case LiveStatus.disconnected:
        // Static dot for disconnected
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
        );
    }
  }
}

/// Helper function to determine status based on stream health
/// You can use this to automatically set the status
LiveStatus determineLiveStatus({
  required bool isStreamConnected,
  required bool isAttemptingConnection,
}) {
  if (isAttemptingConnection) {
    return LiveStatus.connecting;
  } else if (isStreamConnected) {
    return LiveStatus.connected;
  } else {
    return LiveStatus.disconnected;
  }
}
