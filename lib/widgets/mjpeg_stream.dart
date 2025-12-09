import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  bool _isConnected = false;
  bool _isConnecting = true;
  Timer? _reconnectTimer;
  bool _shouldShowFrame = false; // Only show frame if we have an active connection

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
      print('🔄 Stream URL changed, restarting...');
      _subscription?.cancel();
      _reconnectTimer?.cancel();
      _currentFrame = null;
      _shouldShowFrame = false;
      _startStream();
    }
  }

  void _startStream() async {
    try {
      // Skip if URL is empty
      if (widget.url.isEmpty) {
        setState(() {
          _isConnecting = false;
          _isConnected = false;
          _shouldShowFrame = false;
        });
        widget.onStatusChanged?.call(false, false);
        return;
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.url));
      
      // Add timeout to connection attempt
      final response = await client.send(request).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Stream connection timeout');
        },
      );

      // Connection successful
      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _shouldShowFrame = true; // Start showing frames
      });
      widget.onStatusChanged?.call(true, false);
      print('✅ MJPEG Stream connected');

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
                    if (mounted && _shouldShowFrame) setState(() {});
                  } catch (_) {}
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
          print('❌ MJPEG Stream error: $e');
          // Connection error - attempt to reconnect
          if (mounted) {
            setState(() {
              _isConnecting = false;
              _isConnected = false;
              _shouldShowFrame = false;
              _currentFrame = null; // Clear the last frame
            });
            widget.onStatusChanged?.call(false, false);
            
            // Auto-reconnect after 3 seconds
            _reconnectTimer?.cancel();
            _reconnectTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) {
                print('🔄 Attempting to reconnect to stream...');
                setState(() {
                  _isConnecting = true;
                  _currentFrame = null;
                });
                _startStream();
              }
            });
          }
        },
        onDone: () {
          print('⏹️ MJPEG Stream closed');
          // Connection closed - attempt to reconnect
          if (mounted) {
            setState(() {
              _isConnecting = false;
              _isConnected = false;
              _shouldShowFrame = false;
              _currentFrame = null; // Clear the last frame
            });
            widget.onStatusChanged?.call(false, false);
            
            // Auto-reconnect after 3 seconds
            _reconnectTimer?.cancel();
            _reconnectTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) {
                print('🔄 Attempting to reconnect to stream...');
                setState(() {
                  _isConnecting = true;
                  _currentFrame = null;
                });
                _startStream();
              }
            });
          }
        },
      );
    } catch (e) {
      print("❌ MJPEG error: $e");
      // Connection failed
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _shouldShowFrame = false;
        _currentFrame = null; // Clear on error
      });
      widget.onStatusChanged?.call(false, false);
      
      // Retry connection after 3 seconds
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          print('🔄 Retrying stream connection after error...');
          setState(() {
            _isConnecting = true;
            _currentFrame = null;
          });
          _startStream();
        }
      });
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
