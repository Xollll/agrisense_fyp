import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// =============================================================
// MJPEG STREAM WIDGET
// Handles: Live camera stream parsing and display
// =============================================================
class MJPEGStream extends StatefulWidget {
  final String url;

  const MJPEGStream({super.key, required this.url});

  @override
  State<MJPEGStream> createState() => _MJPEGStreamState();
}

class _MJPEGStreamState extends State<MJPEGStream> {
  Uint8List? _currentFrame;
  StreamSubscription<List<int>>? _subscription;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  void _startStream() async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.url));
      final response = await client.send(request);

      List<int> buffer = [];

      _subscription = response.stream.listen((chunk) {
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
                  if (mounted) setState(() {});
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
      });
    } catch (e) {
      print("MJPEG error: $e");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
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
