import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:agrisense/utils/app_log.dart';

// =============================================================
// MJPEG STREAM WIDGET
// Handles: Live camera stream parsing and display
// Exposes: Connection state (connected, connecting, disconnected)
// =============================================================
class MJPEGStream extends StatefulWidget {
  final String url;
  final Function(bool isConnected, bool isConnecting)? onStatusChanged;

  const MJPEGStream({
    super.key,
    required this.url,
    this.onStatusChanged,
  });

  @override
  State<MJPEGStream> createState() => _MJPEGStreamState();
}

class _MJPEGStreamState extends State<MJPEGStream> {
  Uint8List? _currentFrame;
  StreamSubscription<List<int>>? _subscription;
  http.Client? _httpClient;
  bool _isConnected = false;
  bool _isConnecting = true;
  Timer? _reconnectTimer;
  Timer? _watchdogTimer; // Watchdog to detect stalled connections
  bool _shouldShowFrame = false; // Only show frame if we have an active connection
  DateTime? _lastFrameTime; // Track when we last received a frame
  DateTime? _connectionAttemptTime; // Track when we last attempted to connect

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  @override
  void didUpdateWidget(MJPEGStream oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If URL changed, restart the stream
    if (oldWidget.url != widget.url) {
      appLog('Stream URL changed, restarting...');
      _subscription?.cancel();
      _reconnectTimer?.cancel();
      _currentFrame = null;
      _shouldShowFrame = false;
      _startStream();
    }
  }

  /// Helper to attempt reconnection with proper cleanup
  void _attemptReconnect() {
    _reconnectTimer?.cancel();
    appLog('⏳ Scheduling reconnect in 1 second...');
    _reconnectTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        appLog('🔄 Attempting to reconnect to stream...');
        setState(() {
          _isConnecting = true;
          _currentFrame = null;
          _lastFrameTime = null;
        });
        _startStream();
      }
    });
  }

  void _startStream() async {
    try {
      // Skip if URL is empty
      if (widget.url.isEmpty) {
        appLog('📺 Stream URL is empty, waiting for initialization...');
        setState(() {
          _isConnecting = false;
          _isConnected = false;
          _shouldShowFrame = false;
        });
        widget.onStatusChanged?.call(false, false);
        return;
      }

      // Clean up any existing client and subscription
      _subscription?.cancel();
      _httpClient?.close();
      
      // Create a fresh HTTP client for this stream
      _httpClient = http.Client();
      _connectionAttemptTime = DateTime.now();
      
      appLog('🔌 Initiating MJPEG stream connection to: ${widget.url}');
      final request = http.Request('GET', Uri.parse(widget.url));
      
      // Add timeout to connection attempt (allow enough time for TCP + TLS handshake)
      final response = await _httpClient!.send(request).timeout(
        const Duration(milliseconds: 3000),
        onTimeout: () {
          throw TimeoutException('Stream connection timeout after 3 seconds');
        },
      );

      // Connection successful
      if (!mounted) return;
      
      appLog('✅ MJPEG Stream connected, status: ${response.statusCode}');
      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _shouldShowFrame = true; // Start showing frames
        _lastFrameTime = DateTime.now();
      });
      widget.onStatusChanged?.call(true, false);
      appLog('📺 MJPEG Stream connection established, waiting for frames...');

      // Start watchdog timer to detect stalled streams (no frames for 5 seconds)
      _watchdogTimer?.cancel();
      _watchdogTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
        // Check 1: No frames received for 5 seconds
        if (_lastFrameTime != null) {
          final timeSinceLastFrame = DateTime.now().difference(_lastFrameTime!);
          if (timeSinceLastFrame.inSeconds > 5) {
            appLog('⚠️ No frames received for 5 seconds - stream stalled, reconnecting...');
            _subscription?.cancel();
            _watchdogTimer?.cancel();
            _httpClient?.close();
            if (mounted) {
              setState(() {
                _isConnecting = false;
                _isConnected = false;
                _shouldShowFrame = false;
              });
              widget.onStatusChanged?.call(false, false);
            }
            _attemptReconnect();
          }
        }
        
        // Check 2: Connected but no progress in the past 10 seconds (frozen connection)
        if (_isConnected && _connectionAttemptTime != null) {
          final timeSinceConnection = DateTime.now().difference(_connectionAttemptTime!);
          if (_lastFrameTime == null && timeSinceConnection.inSeconds > 10) {
            appLog('⚠️ Connected but no frames received for 10 seconds - stream frozen, reconnecting...');
            _subscription?.cancel();
            _watchdogTimer?.cancel();
            _httpClient?.close();
            if (mounted) {
              setState(() {
                _isConnecting = false;
                _isConnected = false;
                _shouldShowFrame = false;
              });
              widget.onStatusChanged?.call(false, false);
            }
            _attemptReconnect();
          }
        }
      });

      List<int> buffer = [];

      _subscription = response.stream.listen(
        (chunk) {
          buffer.addAll(chunk);

          while (true) {
            int start = buffer.indexOf(0xFF);
            if (start != -1 &&
                start + 1 < buffer.length &&
                buffer[start + 1] == 0xD8) {
              int end = buffer.indexOf(0xFF, start + 2);
              while (end != -1 && end + 1 < buffer.length) {
                if (buffer[end + 1] == 0xD9) {
                  try {
                    _currentFrame = Uint8List.fromList(
                      buffer.sublist(start, end + 2),
                    );
                    _lastFrameTime = DateTime.now(); // Update frame timestamp
                    if (mounted && _shouldShowFrame) setState(() {});
                  } catch (e) {
                    appLog('⚠️ Error processing frame: $e');
                  }
                  buffer = buffer.sublist(end + 2);
                  break;
                } else {
                  end = buffer.indexOf(0xFF, end + 1);
                }
              }
              break;
            } else {
              break;
            }
          }
        },
        onError: (e) {
          appLog('❌ MJPEG Stream error: $e');
          // Connection error - attempt to reconnect
          _subscription?.cancel();
          _httpClient?.close();
          if (mounted) {
            setState(() {
              _isConnecting = false;
              _isConnected = false;
              _shouldShowFrame = false;
              _currentFrame = null; // Clear the last frame
              _lastFrameTime = null;
            });
            _watchdogTimer?.cancel();
            widget.onStatusChanged?.call(false, false);
            _attemptReconnect();
          }
        },
        onDone: () {
          appLog('⚠️ MJPEG Stream closed by server');
          // Connection closed - attempt to reconnect
          _subscription?.cancel();
          _httpClient?.close();
          if (mounted) {
            setState(() {
              _isConnecting = false;
              _isConnected = false;
              _shouldShowFrame = false;
              _currentFrame = null; // Clear the last frame
              _lastFrameTime = null;
            });
            _watchdogTimer?.cancel();
            widget.onStatusChanged?.call(false, false);
            _attemptReconnect();
          }
        },
      );
    } catch (e) {
      appLog('❌ MJPEG connection error: $e');
      // Connection failed
      _httpClient?.close();
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isConnected = false;
          _shouldShowFrame = false;
          _currentFrame = null; // Clear on error
          _lastFrameTime = null;
        });
        _watchdogTimer?.cancel();
        widget.onStatusChanged?.call(false, false);

        // Retry connection after 1 second
        _attemptReconnect();
      }
    }
  }

  /// Check if stream is connected
  bool get isConnected => _isConnected;

  /// Check if stream is connecting
  bool get isConnecting => _isConnecting;

  @override
  void dispose() {
    _subscription?.cancel();
    _reconnectTimer?.cancel();
    _watchdogTimer?.cancel();
    _httpClient?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _currentFrame == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  "Connecting to camera...",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        : Image.memory(
            _currentFrame!,
            gaplessPlayback: true,
            fit: BoxFit.cover,
          );
  }
}
