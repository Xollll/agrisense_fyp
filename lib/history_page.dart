// lib/pages/history_page.dart
import 'package:flutter/material.dart';
import '../widgets/app_bar.dart';
import '../services/supabase_service.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const ModernAppBar(
        title: "Detection History",
        subtitle: "Past detections overview",
        icon: Icons.history,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabaseService.getDetectionHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No detections found.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final detections = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: detections.length,
            itemBuilder: (context, index) {
              final item = detections[index];

              final label = item['label']?.toString() ?? 'Unknown';
              final confidence = (item['confidence'] is num)
                  ? (item['confidence'] as num).toDouble()
                  : double.tryParse('${item['confidence']}') ?? 0.0;
              final solution = item['solution']?.toString() ?? '';
              final timestamp = item['timestamp']?.toString() ?? '';

              String subtitleText = 'Confidence: ${(confidence * 100).toStringAsFixed(2)}%\n';
              subtitleText += 'Suggestion: ${solution.length > 200 ? solution.substring(0, 200) + "..." : solution}';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(subtitleText),
                  isThreeLine: true,
                  trailing: Text(
                    timestamp.split('T').first,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    // Optional: show full solution in dialog
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(label),
                        content: SingleChildScrollView(child: Text(solution)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          )
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
