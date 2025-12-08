// lib/pages/statistics_page_redesigned.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';
import '../widgets/app_bar.dart';
import '../services/statistics_service.dart';

class StatisticsPageRedesigned extends StatefulWidget {
  const StatisticsPageRedesigned({Key? key}) : super(key: key);

  @override
  State<StatisticsPageRedesigned> createState() =>
      _StatisticsPageRedesignedState();
}

class _StatisticsPageRedesignedState extends State<StatisticsPageRedesigned> {
  int _selectedTimeRange = 0; // 0: All, 1: 30 Days, 2: 7 Days

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<StatisticsProvider>().loadStatistics();
    });
  }

  void _refreshData() async {
    await context.read<StatisticsProvider>().loadStatistics();
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
                  title: "Farm Analytics",
                  subtitle: "Understand your crop health story",
                  icon: Icons.trending_up,
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
                    _refreshData();
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
              const Icon(Icons.spa_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No Detection History Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start scanning your crops to build your farm analytics story',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Start Scanning'),
                onPressed: () {
                  // Navigate to Dashboard
                  // This will be implemented in main.dart
                },
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
          // 1. HEALTH STATUS STORY CARD
          _buildHealthStoryCard(context, provider),
          const SizedBox(height: 24),

          // 2. TIME RANGE FILTER
          _buildTimeRangeFilter(context),
          const SizedBox(height: 24),

          // 3. KEY METRICS SECTION - Story Format
          _buildKeyMetricsStory(context, provider),
          const SizedBox(height: 24),

          // 4. DISEASE THREAT ASSESSMENT
          _buildDiseaseThreatAssessment(context, provider),
          const SizedBox(height: 24),

          // 5. CROP HEALTH JOURNEY TIMELINE
          _buildCropHealthJourney(context, provider),
          const SizedBox(height: 24),

          // 6. RECOMMENDATIONS SECTION
          _buildSmartRecommendations(context, provider),
          const SizedBox(height: 24),

          // 7. COMPARISON SECTION
          _buildCropComparison(context, provider),
          const SizedBox(height: 24),

          // 8. ACTION BUTTONS
          _buildActionButtons(context, provider),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 1. HEALTH STATUS STORY CARD
  Widget _buildHealthStoryCard(BuildContext context, StatisticsProvider provider) {
    final summary = provider.summary;
    final totalDetections = summary['total_detections'] ?? 0;
    final healthyPercentage =
        double.tryParse(summary['healthy_percentage']?.toString() ?? '0') ?? 0;
    final diseasedPercentage = 100 - healthyPercentage;

    // Determine health status
    String healthStatus;
    Color statusColor;
    String statusMessage;
    IconData statusIcon;

    if (healthyPercentage >= 80) {
      healthStatus = 'Excellent Health';
      statusColor = Colors.green;
      statusMessage = 'Your crops are thriving! Keep up the good work.';
      statusIcon = Icons.sentiment_very_satisfied;
    } else if (healthyPercentage >= 60) {
      healthStatus = 'Good Health';
      statusColor = Colors.lightGreen;
      statusMessage = 'Most crops are healthy. Monitor for early signs.';
      statusIcon = Icons.sentiment_satisfied;
    } else if (healthyPercentage >= 40) {
      healthStatus = 'Caution Required';
      statusColor = Colors.orange;
      statusMessage = 'Multiple issues detected. Consider intervention.';
      statusIcon = Icons.sentiment_neutral;
    } else {
      healthStatus = 'Critical Attention Needed';
      statusColor = Colors.red;
      statusMessage = 'Significant health issues. Immediate action recommended.';
      statusIcon = Icons.sentiment_very_dissatisfied;
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm Health Status',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      healthStatus,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 32,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Health Meter with Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Health Score',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${healthyPercentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: healthyPercentage / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade900,
                      height: 1.5,
                    ),
              ),
            ),

            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatsItem(
                    context,
                    'Scans Done',
                    totalDetections.toString(),
                    Icons.camera_alt,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatsItem(
                    context,
                    'Healthy',
                    '${healthyPercentage.toStringAsFixed(0)}%',
                    Icons.favorite,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatsItem(
                    context,
                    'Issues Found',
                    '${diseasedPercentage.toStringAsFixed(0)}%',
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for stats items
  Widget _buildStatsItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 2. TIME RANGE FILTER
  Widget _buildTimeRangeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Period',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFilterChip('All Time', 0),
            const SizedBox(width: 12),
            _buildFilterChip('Last 30 Days', 1),
            const SizedBox(width: 12),
            _buildFilterChip('Last 7 Days', 2),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedTimeRange == index;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedTimeRange = index;
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: Colors.green.shade100,
      side: BorderSide(
        color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
      ),
    );
  }

  // 3. KEY METRICS STORY
  Widget _buildKeyMetricsStory(BuildContext context, StatisticsProvider provider) {
    final summary = provider.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Crop Story',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStoryLine(
                  context,
                  '🔍 Total Detections',
                  summary['total_detections']?.toString() ?? '0',
                  'Times you\'ve scanned your crops for health assessment',
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 16),
                _buildStoryLine(
                  context,
                  '🦠 Disease Types Found',
                  summary['unique_diseases']?.toString() ?? '0',
                  'Different health issues detected across your farm',
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 16),
                _buildStoryLine(
                  context,
                  '🏆 Most Common Issue',
                  summary['most_common_disease'] ?? 'None detected',
                  'The primary health challenge in your crops',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryLine(
    BuildContext context,
    String title,
    String value,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
          ),
        ),
      ],
    );
  }

  // 4. DISEASE THREAT ASSESSMENT
  Widget _buildDiseaseThreatAssessment(BuildContext context, StatisticsProvider provider) {
    if (provider.diseaseStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disease Threat Assessment',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.diseaseStats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final disease = provider.diseaseStats[index];
            final threatLevel = _getThreatLevel(disease.percentage);

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                disease.disease,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Threat Level: $threatLevel',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getThreatColor(disease.percentage)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${disease.percentage.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getThreatColor(disease.percentage),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: disease.percentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getThreatColor(disease.percentage),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Detected ${disease.count} time${disease.count != 1 ? 's' : ''} • Last seen: ${_formatDate(disease.lastDetected)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 5. CROP HEALTH JOURNEY TIMELINE
  Widget _buildCropHealthJourney(BuildContext context, StatisticsProvider provider) {
    if (provider.timelineData.isEmpty) {
      return const SizedBox.shrink();
    }

    final recentData = provider.timelineData.take(7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Crop Health Journey',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detection Activity (Last 7 Days)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 120,
                  child: _buildSimpleBarChart(recentData),
                ),
                const SizedBox(height: 16),
                Text(
                  'You\'ve been actively monitoring your crops. Keep up the good habits!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Simple bar chart visualization
  Widget _buildSimpleBarChart(List<TimelineData> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxCount = data.isNotEmpty
        ? data.map((e) => e.count).reduce((a, b) => a > b ? a : b)
        : 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: data.map((item) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                width: 30,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                height: (item.count / maxCount) * 100,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.count.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateShort(item.date),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  // 6. SMART RECOMMENDATIONS
  Widget _buildSmartRecommendations(BuildContext context, StatisticsProvider provider) {
    final summary = provider.summary;
    final healthyPercentage =
        double.tryParse(summary['healthy_percentage']?.toString() ?? '0') ?? 0;
    final diseaseStats = provider.diseaseStats;

    List<String> recommendations = [];

    if (healthyPercentage >= 80) {
      recommendations.add('✅ Maintain current care practices');
      recommendations.add('📋 Continue regular monitoring schedule');
    } else if (healthyPercentage >= 60) {
      recommendations.add('⚠️ Increase monitoring frequency');
      recommendations.add('🧪 Consider preventive treatments');
    } else if (healthyPercentage >= 40) {
      recommendations.add('🚨 Implement intervention plan');
      recommendations.add('👨‍🌾 Consult agricultural specialist');
    } else {
      recommendations.add('🚨 Urgent action required');
      recommendations.add('📞 Contact farm management support');
    }

    if (diseaseStats.isNotEmpty) {
      final topDisease = diseaseStats.first;
      recommendations.add(
          '🔍 Focus treatment on ${topDisease.disease} (${topDisease.percentage.toStringAsFixed(1)}%)');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI-Powered Recommendations',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recommendations
                  .asMap()
                  .entries
                  .map((entry) {
                    final index = entry.key;
                    final rec = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < recommendations.length - 1 ? 12 : 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rec,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    height: 1.6,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  // 7. CROP COMPARISON
  Widget _buildCropComparison(BuildContext context, StatisticsProvider provider) {
    final summary = provider.summary;
    final totalDetections = summary['total_detections'] ?? 0;
    final healthyPercentage =
        double.tryParse(summary['healthy_percentage']?.toString() ?? '0') ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Metrics Comparison',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Monitoring Score',
                _calculateMonitoringScore(totalDetections),
                'Based on scan frequency',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                'Health Index',
                healthyPercentage.toStringAsFixed(0),
                'Current farm health',
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trending_up,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$value%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 8. ACTION BUTTONS
  Widget _buildActionButtons(BuildContext context, StatisticsProvider provider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Export Health Report'),
            onPressed: () => _showExportOptions(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Data'),
            onPressed: () {
              context.read<StatisticsProvider>().loadStatistics();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // HELPER METHODS
  String _getThreatLevel(double percentage) {
    if (percentage >= 50) return '🔴 Critical';
    if (percentage >= 30) return '🟠 High';
    if (percentage >= 10) return '🟡 Medium';
    return '🟢 Low';
  }

  Color _getThreatColor(double percentage) {
    if (percentage >= 50) return Colors.red;
    if (percentage >= 30) return Colors.orange;
    if (percentage >= 10) return Colors.amber;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _calculateMonitoringScore(int detections) {
    if (detections >= 20) return '100';
    if (detections >= 10) return '80';
    if (detections >= 5) return '60';
    return '${(detections * 10).clamp(0, 50)}';
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Health Report'),
        content: const Text('Choose your preferred format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.table_chart),
            label: const Text('CSV'),
            onPressed: () {
              // Export CSV
              Navigator.pop(context);
              _exportAsCSV();
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
            onPressed: () {
              // Export PDF
              Navigator.pop(context);
              _exportAsPDF();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportAsCSV() async {
    // Implementation similar to original
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting CSV...')),
    );
  }

  Future<void> _exportAsPDF() async {
    // Implementation similar to original
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting PDF...')),
    );
  }
}
