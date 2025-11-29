import 'package:flutter/material.dart';
import '../widgets/app_bar.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,

      appBar: const ModernAppBar(
        title: "Detection History",
        subtitle: "Past detections overview",
        icon: Icons.history,
      ),
      body: const Center(
        child: Text(
          "History page content here...",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
