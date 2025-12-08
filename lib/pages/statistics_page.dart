// lib/pages/statistics_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';
import '../widgets/disease_chart.dart';
import '../widgets/app_bar.dart';
import '../services/export_service.dart';
import '../services/statistics_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  void initState() {
    super.initState();
    // Refresh statistics when page loads
    Future.microtask(() {
      context.read<StatisticsProvider>().loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Modern App Bar
              SliverToBoxAdapter(
                child: ModernAppBar(
                  title: "Statistics & Analytics",
                  subtitle: "Insights into your crops",
                  icon: Icons.bar_chart,
                  onMenuPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),

              // Pull-to-Refresh with Content
              SliverFillRemaining(
                hasScrollBody: true,
                child: RefreshIndicator(
                  onRefresh: () async {
                    await context.read<StatisticsProvider>().loadStatistics();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildContent(context, provider),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, StatisticsProvider provider) {
    if (provider.isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.error != null) {
      return SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(provider.error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<StatisticsProvider>().loadStatistics();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.summary.isEmpty) {
      return SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No detection data yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Start scanning plants to see statistics',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(context, provider),

          const SizedBox(height: 24),

          // Health Meter
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FutureBuilder<double>(
                future: provider.getHealthyPercentage(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final healthyPercentage = snapshot.data ?? 0.0;
                  return HealthMeter(healthyPercentage: healthyPercentage);
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Disease Frequency Chart
          Text(
            'Disease Distribution',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 300,
                child: DiseaseFrequencyChart(
                  diseaseStats: provider.diseaseStats,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Disease Ranking
          Text(
            'Disease Rankings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DiseaseRankingTable(
                diseaseStats: provider.diseaseStats,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Timeline Chart
          Text(
            'Detection Timeline (Last 30 Days)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 300,
                child: DetectionTimelineChart(
                  timelineData: provider.timelineData,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Export Data'),
                  onPressed: _showExportOptions,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear History'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                  ),
                  onPressed: _showClearConfirmation,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Build summary statistics cards
  Widget _buildSummaryCards(BuildContext context, StatisticsProvider provider) {
    final summary = provider.summary;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard(
          context,
          'Total Detections',
          summary['total_detections']?.toString() ?? '0',
          Icons.grid_3x3,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Unique Diseases',
          summary['unique_diseases']?.toString() ?? '0',
          Icons.bug_report,
          Colors.red,
        ),
        _buildStatCard(
          context,
          'Healthy',
          '${summary['healthy_percentage']}%',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Diseased',
          '${summary['diseased_percentage']}%',
          Icons.warning,
          Colors.orange,
        ),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withAlpha(50), color.withAlpha(20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show export options dialog
  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Statistics'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.table_chart),
            onPressed: () {
              _exportAsCSV();
              Navigator.pop(context);
            },
            label: const Text('CSV'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              _exportAsPDF();
              Navigator.pop(context);
            },
            label: const Text('PDF'),
          ),
        ],
      ),
    );
  }

  /// Export statistics as CSV
  Future<void> _exportAsCSV() async {
    if (!mounted) return;

    try {
      _showLoadingDialog('Exporting to CSV...');

      // Get detection history from statistics service
      final detections = await StatisticsService().getDetectionHistory();

      if (detections.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No detection data to export')),
        );
        return;
      }

      // Export to CSV
      final csvFile = await ExportService.exportToCSV(
        detections: detections,
      );

      Navigator.pop(context); // Close loading dialog

      if (!mounted) return;

      // Show success and share options
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('CSV exported successfully'),
          action: SnackBarAction(
            label: 'SHARE',
            onPressed: () => _shareFile(csvFile),
          ),
        ),
      );

      print('📊 CSV exported: ${csvFile.path}');
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Export statistics as PDF
  Future<void> _exportAsPDF() async {
    if (!mounted) return;

    try {
      _showLoadingDialog('Exporting to PDF...');

      final statsProvider = context.read<StatisticsProvider>();
      final detections = await StatisticsService().getDetectionHistory();

      if (detections.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No detection data to export')),
        );
        return;
      }

      // Export to PDF
      final pdfFile = await ExportService.exportToPDF(
        detections: detections,
        summary: statsProvider.summary,
        diseaseStats: statsProvider.diseaseStats,
      );

      Navigator.pop(context); // Close loading dialog

      if (!mounted) return;

      // Show success and share options
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF exported successfully'),
          action: SnackBarAction(
            label: 'SHARE',
            onPressed: () => _shareFile(pdfFile),
          ),
        ),
      );

      print('📄 PDF exported: ${pdfFile.path}');
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Share exported file
  Future<void> _shareFile(dynamic file) async {
    try {
      await ExportService.shareFile(file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show loading dialog
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  /// Show clear history confirmation
  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to delete all detection history? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<StatisticsProvider>().clearHistory();
              Navigator.pop(context);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
