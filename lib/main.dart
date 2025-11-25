import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AgriSenseApp());
}

class AgriSenseApp extends StatelessWidget {
  const AgriSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSense Live Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class NormalizedDetection {
  final String label;
  final double confidence;
  final String? time;

  NormalizedDetection({
    required this.label,
    required this.confidence,
    this.time,
  });
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<NormalizedDetection> currentDetections = [];
  String geminiText = "Waiting for analysis...";

  Timer? _detectionTimer;
  Timer? _geminiTimer;

  @override
  void initState() {
    super.initState();

    // Poll Node-RED every 500ms
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      fetchDetections();
    });

    // Trigger Gemini API every 10 seconds based on latest detection
    _geminiTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (currentDetections.isNotEmpty) {
        generateGeminiRecommendation(currentDetections[0]);
      }
    });
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _geminiTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------
  // NORMALIZE DETECTION
  // ---------------------------------------------
  NormalizedDetection _normalizeMap(Map m) {
    final label = (m["label"] ?? m["Label"] ?? "Unknown").toString();

    double conf = 0.0;
    final raw = m["confidence"] ?? m["Confidence"];

    if (raw != null) {
      if (raw is num) {
        conf = raw.toDouble();
        if (conf > 1.0) conf = conf / 100.0;
      } else {
        String s = raw.toString().replaceAll("%", "");
        final p = double.tryParse(s);
        if (p != null) conf = p > 1.0 ? p / 100.0 : p;
      }
    }

    final time = (m["time"] ?? "").toString();

    return NormalizedDetection(label: label, confidence: conf, time: time);
  }

  // ---------------------------------------------
  // FETCH DETECTIONS FROM NODE-RED HTTP
  // ---------------------------------------------
  Future<void> fetchDetections() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.8.76:1880/latest_detection"),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["status"] == "no_data") {
          setState(() {
            currentDetections = [];
          });
          return;
        }

        final detection = NormalizedDetection(
          label: decoded["message"] ?? "Unknown",
          confidence: 1.0,
          time: decoded["timestamp"] ?? "",
        );

        setState(() {
          currentDetections = [detection];
        });
      }
    } catch (e) {
      print("HTTP Fetch Error: $e");
    }
  }

  // ---------------------------------------------
  // GEMINI API CALL
  // ---------------------------------------------
  Future<void> generateGeminiRecommendation(NormalizedDetection detection) async {
    try {
      final apiKey = "AIzaSyC2Xk6A_6A6IkxhKvfeo-0osIlWZdUCojU"; // <--- Replace with your API key
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey",
      );

      final prompt = """
You are an agriculture assistant AI.

Based on the detection below, give a clear recommendation for the farmer:
Detection: ${detection.label}
Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%

Rules:
- Explain clearly what action should be taken
- Keep it short (3-5 sentences)
""";

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          geminiText = json["candidates"][0]["content"]["parts"][0]["text"];
        });
      } else {
        print("Gemini API Error: ${response.body}");
        setState(() {
          geminiText = "Error generating recommendation.";
        });
      }
    } catch (e) {
      print("Gemini Exception: $e");
      setState(() {
        geminiText = "Error generating recommendation.";
      });
    }
  }

  // ---------------------------------------------
  // UI
  // ---------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AgriSense Live Monitor")),
      body: Column(
        children: [
          // CAMERA STREAM
          SizedBox(
            height: 250,
            width: double.infinity,
            child: MJPEGStream(url: "http://192.168.8.76:5000/video_feed"),
          ),
          const SizedBox(height: 12),

          const Chip(
            label: Text(
              "HTTP Connected",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),

          // REALTIME DETECTIONS
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: const [
              Icon(Icons.eco, color: Colors.green),
              SizedBox(width: 8),
              Text("Current Detections",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            ]),
          ),

          Expanded(
            child: currentDetections.isEmpty
                ? const Center(child: Text("No detections yet"))
                : ListView.builder(
                    itemCount: currentDetections.length,
                    itemBuilder: (context, i) {
                      final d = currentDetections[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.local_florist,
                              color: Colors.green),
                          title: Text(d.label),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(),

          // AI RECOMMENDATIONS
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: const [
              Icon(Icons.lightbulb, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "AI Recommendations",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ]),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade50,
              width: double.infinity,
              child: Text(
                geminiText,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------
// MJPEG CAMERA STREAM WIDGET
// -----------------------------------------------------------
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
                  _currentFrame =
                      Uint8List.fromList(buffer.sublist(start, end + 2));
                  setState(() {});
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
        ? const Center(child: CircularProgressIndicator())
        : Image.memory(
            _currentFrame!,
            gaplessPlayback: true,
            fit: BoxFit.cover,
          );
  }
}
