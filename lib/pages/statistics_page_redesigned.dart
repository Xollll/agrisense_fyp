// lib/pages/statistics_page_modern.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import '../providers/statistics_provider.dart';
import '../services/statistics_service.dart';
import '../widgets/enhanced_app_bar.dart';
import '../services/export_service.dart';
import 'package:agrisense/utils/app_log.dart';

class StatisticsPageModern extends StatefulWidget {
  const StatisticsPageModern({Key? key}) : super(key: key);

  @override
  State<StatisticsPageModern> createState() => _StatisticsPageModernState();
}

class _StatisticsPageModernState extends State<StatisticsPageModern>
    with TickerProviderStateMixin {
  int _selectedTimeRange = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  // Agriculture-themed color palette
  static const Color earthBrown = Color(0xFF8B7355);
  static const Color cropGreen = Color(0xFF6B8E23);
  static const Color sunYellow = Color(0xFFFFB347);
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color soilDark = Color(0xFF3E2723);
  static const Color leafGreen = Color(0xFF90C695);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    Future.microtask(() {
      context.read<StatisticsProvider>().loadStatistics();
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<StatisticsProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: AppBarBuilder.statistics(
                  context: context,
                  onMenuPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: true,
                child: RefreshIndicator(
                  onRefresh: () async {
                    await context.read<StatisticsProvider>().loadStatistics();
                    _fadeController.reset();
                    _fadeController.forward();
                  },
                  color: cropGreen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildContent(context, provider, isDarkMode),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, StatisticsProvider provider, bool isDarkMode) {
    if (provider.isLoading) {
      return SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(cropGreen),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Growing your insights...',
                style: TextStyle(
                  color: isDarkMode 
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.error != null) {
      return _buildErrorState(provider);
    }

    if (provider.summary.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthHeroCard(context, provider, isDarkMode),
            const SizedBox(height: 24),
            _buildHealthTrendsAndForecast(context, provider, isDarkMode),
            const SizedBox(height: 24),
            _buildQuickStats(context, provider, isDarkMode),
            const SizedBox(height: 24),
            _buildDiseaseThreatCards(context, provider, isDarkMode),
            const SizedBox(height: 24),
            _buildHealthTrendChart(context, provider, isDarkMode),
            const SizedBox(height: 24),
            _buildSmartInsights(context, provider, isDarkMode),
            const SizedBox(height: 24),
            _buildActionButtons(context, provider, isDarkMode),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthHeroCard(BuildContext context, StatisticsProvider provider, bool isDarkMode) {
    final summary = provider.summary;
    final totalDetections = summary['total_detections'] ?? 0;
    final healthyPercentage =
        double.tryParse(summary['healthy_percentage']?.toString() ?? '0') ?? 0;

    Color statusColor;
    String statusEmoji;
    String statusText;

    if (healthyPercentage >= 80) {
      statusColor = leafGreen;
      statusEmoji = '🌱';
      statusText = 'Thriving';
    } else if (healthyPercentage >= 60) {
      statusColor = cropGreen;
      statusEmoji = '🌿';
      statusText = 'Growing Well';
    } else if (healthyPercentage >= 40) {
      statusColor = sunYellow;
      statusEmoji = '⚠️';
      statusText = 'Needs Care';
    } else {
      statusColor = const Color(0xFFFF6B35);
      statusEmoji = '🚨';
      statusText = 'Critical';
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.15),
              statusColor.withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.02),
                        ]
                      : [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.1),
                        ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Farm Health',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode 
                                  ? Colors.grey.shade400
                                  : soilDark.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                statusEmoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: healthyPercentage / 100),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return SizedBox(
                            width: 100,
                            height: 100,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 8,
                                    backgroundColor: isDarkMode
                                        ? Colors.white.withOpacity(0.15)
                                        : Colors.white.withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${(value * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                    Text(
                                      'Health',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: soilDark.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickStat('🔍', totalDetections.toString(), 'Scans'),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        _buildQuickStat(
                          '🌾',
                          summary['unique_diseases']?.toString() ?? '0',
                          'Issues',
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        _buildQuickStat(
                          '📊',
                          '${healthyPercentage.toInt()}%',
                          'Healthy',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthTrendsAndForecast(BuildContext context, StatisticsProvider provider, bool isDarkMode) {
    final summary = provider.summary;
    final currentHealth = double.tryParse(summary['healthy_percentage']?.toString() ?? '0') ?? 0;
    final previousHealth = double.tryParse(summary['previous_month_health']?.toString() ?? '0') ?? currentHealth;
    
    // Calculate month-over-month change
    final healthChange = currentHealth - previousHealth;
    final healthChangePercent = previousHealth > 0 ? (healthChange / previousHealth * 100) : 0;
    final isHealthImproving = healthChange >= 0;
    
    // Calculate disease progression forecast
    String forecastText = '';
    String forecastEmoji = '📊';
    Color forecastColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    
    if (provider.diseaseStats.isNotEmpty) {
      final topDisease = provider.diseaseStats.first;
      final daysToProject = 14; // Project 2 weeks ahead
      
      // Calculate detection trend (simple linear projection)
      double projectedPercentage = topDisease.percentage;
      
      if (provider.timelineData.isNotEmpty && provider.timelineData.length >= 2) {
        final recent = provider.timelineData.first.count as int? ?? 0;
        final previous = provider.timelineData.length > 1 
            ? (provider.timelineData[1].count as int? ?? 0)
            : recent;
        
        if (previous > 0 && recent > 0) {
          final dailyChange = (recent - previous) / 1.0;
          projectedPercentage = (topDisease.percentage + (dailyChange * daysToProject)).clamp(0, 100);
        }
      }
      
      // Generate forecast message
      if (projectedPercentage > 80) {
        forecastEmoji = '🚨';
        forecastColor = const Color(0xFFFF6B35);
        forecastText = 'CRITICAL: ${topDisease.disease} could peak above 80% in 2 weeks - immediate action required';
      } else if (projectedPercentage > 60) {
        forecastEmoji = '⚠️';
        forecastColor = const Color(0xFFFFA500);
        forecastText = '${topDisease.disease} may reach ${projectedPercentage.toStringAsFixed(0)}% in 2 weeks - monitor closely';
      } else if (projectedPercentage > topDisease.percentage + 10) {
        forecastEmoji = '📈';
        forecastColor = sunYellow;
        forecastText = '${topDisease.disease} trend is upward - preventive action recommended';
      } else if (projectedPercentage < topDisease.percentage - 10) {
        forecastEmoji = '✅';
        forecastColor = leafGreen;
        forecastText = '${topDisease.disease} trending downward - treatments appear to be working!';
      } else {
        forecastEmoji = '📊';
        forecastColor = cropGreen;
        forecastText = '${topDisease.disease} stable - maintain current monitoring';
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Health Trends & Forecast',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : soilDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Month-over-Month Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isHealthImproving 
                      ? leafGreen.withOpacity(0.15)
                      : const Color(0xFFFFA500).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHealthImproving 
                        ? leafGreen.withOpacity(0.3)
                        : const Color(0xFFFFA500).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isHealthImproving ? leafGreen : const Color(0xFFFFA500)).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Month-over-Month',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode 
                            ? Colors.grey.shade300
                            : soilDark.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          isHealthImproving ? '📈' : '📉',
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${isHealthImproving ? '+' : ''}${healthChangePercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isHealthImproving 
                                    ? leafGreen 
                                    : Colors.orange.shade600,
                              ),
                            ),                                            Text(
                                              isHealthImproving 
                                                  ? 'Improving' 
                                                  : 'Declining',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDarkMode 
                                                    ? Colors.grey.shade300
                                                    : soilDark.withOpacity(0.6),
                                              ),
                                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isHealthImproving 
                            ? '✨ Great progress!'
                            : '⚠️ Needs attention',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: soilDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 2-Week Forecast Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: forecastColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: forecastColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: forecastColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '14-Day Forecast',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode 
                            ? Colors.grey.shade300
                            : soilDark.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      forecastEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Disease Outlook',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: forecastColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Forecast Detail
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: forecastColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: forecastColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: forecastColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(forecastEmoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(              child: Text(
                forecastText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : soilDark,
                  height: 1.4,
                ),
              ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildModernFilterChip(String label, int index, IconData icon) {
    final isSelected = _selectedTimeRange == index;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedTimeRange = index;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? cropGreen
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? cropGreen
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cropGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : soilDark.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : soilDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, StatisticsProvider provider, bool isDarkMode) {
    final summary = provider.summary;
    final mostCommon = summary['most_common_disease'] ?? 'None';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🌾 Farm Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : soilDark,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStatRow(
                '🔍 Total Detections',
                summary['total_detections']?.toString() ?? '0',
                'scans completed',
                isDarkMode,
              ),
              Divider(height: 32, color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
              _buildStatRow(
                '🦠 Disease Types',
                summary['unique_diseases']?.toString() ?? '0',
                'unique issues found',
                isDarkMode,
              ),
              Divider(height: 32, color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
              _buildStatRow(
                '🏆 Top Issue',
                mostCommon.length > 20
                    ? '${mostCommon.substring(0, 20)}...'
                    : mostCommon,
                'most common detection',
                isDarkMode,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, String subtitle, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : soilDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : cropGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildDiseaseThreatCards(BuildContext context, StatisticsProvider provider, bool isDarkMode) {
    if (provider.diseaseStats.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show top diseases by confidence risk (not list format like History)
    // This is different from History page which shows individual detections
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚠️ Risk Ranking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : soilDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Diseases ranked by detection frequency and confidence level',
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(
              provider.diseaseStats.length > 5 ? 5 : provider.diseaseStats.length,
              (index) {
                final disease = provider.diseaseStats[index];
                final threatColor = _getThreatColor(disease.percentage);
                final riskRank = index + 1;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: index < (provider.diseaseStats.length > 5 ? 4 : provider.diseaseStats.length - 1) ? 12 : 0,
                        ),
                        child: Row(
                          children: [
                            // Rank badge
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [threatColor, threatColor.withOpacity(0.8)],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: threatColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '#$riskRank',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Disease name and risk
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    disease.disease,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : soilDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getThreatLabel(disease.percentage),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDarkMode 
                                          ? threatColor.withOpacity(0.8) 
                                          : threatColor.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Percentage indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    threatColor.withOpacity(0.2),
                                    threatColor.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: threatColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '${disease.percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: threatColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < (provider.diseaseStats.length > 5 ? 4 : provider.diseaseStats.length - 1))
                        Divider(
                          height: 12,
                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '💡 For detailed history of individual detections, visit the History page',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTrendChart(BuildContext context, StatisticsProvider provider, bool isDarkMode) {
    if (provider.timelineData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine days and data based on selected time range
    int daysToShow;
    String timeRangeLabel;
    switch (_selectedTimeRange) {
      case 0: // All Time
        daysToShow = -1; // -1 means all time
        timeRangeLabel = 'All Time';
        break;
      case 1: // 30 Days
        daysToShow = 30;
        timeRangeLabel = 'Last 30 Days';
        break;
      case 2: // 7 Days (default)
        daysToShow = 7;
        timeRangeLabel = 'Last 7 Days';
        break;
      default:
        daysToShow = 7;
        timeRangeLabel = 'Last 7 Days';
    }

    // Get the filtered data based on selection
    // Filter by actual date range, not just item count
    final List<TimelineData> recentData;
    if (daysToShow < 0) {
      // All time - show all data
      recentData = provider.timelineData;
    } else {
      // Calculate date range based on the most recent data point (not today)
      if (provider.timelineData.isEmpty) {
        recentData = [];
      } else {
        final mostRecentDate = provider.timelineData.last.date;
        final startDate = mostRecentDate.subtract(Duration(days: daysToShow));
        recentData = provider.timelineData
            .where((data) => data.date.isAfter(startDate) || data.date.isAtSameMomentAs(startDate))
            .toList();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📈 Activity Timeline',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : soilDark,
          ),
        ),
        const SizedBox(height: 16),
        // Time range filter - directly above the chart
        Row(
          children: [
            _buildModernFilterChip('All Time', 0, Icons.all_inclusive),
            const SizedBox(width: 12),
            _buildModernFilterChip('30 Days', 1, Icons.calendar_month),
            const SizedBox(width: 12),
            _buildModernFilterChip('7 Days', 2, Icons.calendar_today),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title shows the selected time range
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detection Activity ($timeRangeLabel)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : soilDark.withOpacity(0.7),
                    ),
                  ),
                  // Show data point count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cropGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cropGreen.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${recentData.length} day${recentData.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cropGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 95,
                child: _buildAnimatedBarChart(recentData, isDarkMode),
              ),
              const SizedBox(height: 16),
              // Contextual insight message based on time range
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800.withOpacity(0.6) : leafGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade700 : leafGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: isDarkMode ? sunYellow : cropGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getTimeRangeInsight(timeRangeLabel, recentData.length),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade200 : soilDark.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get contextual insight message based on selected time range
  String _getTimeRangeInsight(String timeRange, int dataPoints) {
    if (dataPoints == 0) {
      return 'No data available for this period - start monitoring to see trends!';
    }
    
    switch (timeRange) {
      case 'Last 7 Days':
        return '📅 Viewing last 7 days - great for weekly monitoring and trend spotting';
      case 'Last 30 Days':
        return '📅 Viewing last 30 days - perfect for monthly health assessment and progress tracking';
      case 'All Time':
        return '📅 Viewing all history - see complete farm health evolution over time';
      default:
        return 'Consistent monitoring leads to healthier crops';
    }
  }

  Widget _buildAnimatedBarChart(List<dynamic> data, bool isDarkMode) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxCount = data.fold<int>(0, (prev, item) {
      final count = item.count is int ? item.count : 0;
      return count > prev ? count : prev;
    });

    if (maxCount == 0) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final itemCount = item.count is int ? item.count : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SizedBox(
            width: 35,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 600 + (index * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              leafGreen,
                              cropGreen,
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cropGreen.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        height: ((itemCount / maxCount) * 120 * value),
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            itemCount.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDateShort(item.date ?? DateTime.now()),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.grey.shade400 : soilDark.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSmartInsights(BuildContext context, StatisticsProvider provider, bool isDarkMode) {
    final summary = provider.summary;
    final healthyPercentage =
        double.tryParse(summary['healthy_percentage']?.toString() ?? '0') ?? 0;

    List<Map<String, dynamic>> insights = [];

    // ============================================================
    // INSIGHT 1: Overall Farm Health Status
    // ============================================================
    if (healthyPercentage >= 80) {
      insights.add({
        'emoji': '✅',
        'text': 'Excellent farm health - keep maintaining your current practices',
        'color': leafGreen,
      });
    } else if (healthyPercentage >= 60) {
      insights.add({
        'emoji': '⚠️',
        'text': 'Moderate health - increase monitoring to catch issues early',
        'color': sunYellow,
      });
    } else {
      insights.add({
        'emoji': '🚨',
        'text': 'Critical health - urgent intervention needed',
        'color': Colors.red.shade600,
      });
    }

    // ============================================================
    // INSIGHT 2: Disease Diversity Analysis
    // ============================================================
    final diseaseCount = provider.diseaseStats.length;
    if (diseaseCount >= 5) {
      insights.add({
        'emoji': '📊',
        'text': 'Multiple diseases detected ($diseaseCount types) - prioritize treating top 2-3 diseases',
        'color': earthBrown,
      });
    } else if (diseaseCount >= 3) {
      insights.add({
        'emoji': '🌾',
        'text': 'Several disease types found - focus on prevention to reduce diversity',
        'color': Colors.orange,
      });
    }

    // ============================================================
    // INSIGHT 3: Top Disease Specific Advice
    // ============================================================
    if (provider.diseaseStats.isNotEmpty) {
      final top = provider.diseaseStats.first;
      final topPercentage = top.percentage;

      if (topPercentage > 50) {
        insights.add({
          'emoji': '🎯',
          'text': '${top.disease} is dominant (${topPercentage.toStringAsFixed(0)}%) - prioritize treating this first',
          'color': Colors.red.shade600,
        });
      } else if (topPercentage > 30) {
        insights.add({
          'emoji': '�',
          'text': '${top.disease} is your main concern (${topPercentage.toStringAsFixed(0)}%) - develop treatment plan',
          'color': Colors.orange.shade600,
        });
      } else {
        insights.add({
          'emoji': '🔍',
          'text': '${top.disease} is most common (${topPercentage.toStringAsFixed(0)}%) - monitor closely',
          'color': sunYellow,
        });
      }
    }

    // ============================================================
    // INSIGHT 4: Activity Trends
    // ============================================================
    if (provider.timelineData.isNotEmpty && provider.timelineData.length >= 2) {
      final recent = provider.timelineData.first.count as int? ?? 0;
      final previous = provider.timelineData.length > 1 
          ? (provider.timelineData[1].count as int? ?? 0)
          : recent;

      if (recent > 0 && previous > 0) {
        final percentageChange = ((recent - previous) / previous * 100);
        
        if (percentageChange > 20) {
          insights.add({
            'emoji': '📈',
            'text': 'Detection rate increased ${percentageChange.toStringAsFixed(0)}% - boost monitoring frequency',
            'color': Colors.red.shade600,
          });
        } else if (percentageChange < -20) {
          insights.add({
            'emoji': '📉',
            'text': 'Detection rate decreasing ${(percentageChange.abs()).toStringAsFixed(0)}% - treatments working',
            'color': leafGreen,
          });
        }
      }
    }

    // ============================================================
    // INSIGHT 5: General Recommendations Based on Health
    // ============================================================
    if (healthyPercentage >= 80) {
      insights.add({
        'emoji': '📋',
        'text': 'Continue regular monitoring schedule',
        'color': cropGreen,
      });
    } else if (healthyPercentage >= 60) {
      insights.add({
        'emoji': '🧪',
        'text': 'Consider preventive treatments before issues worsen',
        'color': Colors.orange,
      });
    } else {
      insights.add({
        'emoji': '👨‍🌾',
        'text': 'Consult with agricultural specialist for immediate intervention',
        'color': Colors.red.shade700,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '💡 Farm Insights',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : soilDark,
              ),
            ),
            Tooltip(
              message: 'Data-driven insights from your farm\'s detection patterns and health metrics',
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: soilDark.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      Colors.grey.shade800.withOpacity(0.6),
                      Colors.grey.shade800.withOpacity(0.3),
                    ]
                  : [
                      skyBlue.withOpacity(0.1),
                      leafGreen.withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade700 : Colors.white.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: insights.asMap().entries.map((entry) {
              final index = entry.key;
              final insight = entry.value;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 500 + (index * 150)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(30 * (1 - value), 0),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index < insights.length - 1 ? 16 : 0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? insight['color'].withOpacity(0.25)
                              : insight['color'].withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? insight['color'].withOpacity(0.4)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          insight['emoji'],
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight['text'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.grey.shade200 : soilDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, StatisticsProvider provider, bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cropGreen, leafGreen],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cropGreen.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text(
              'Export Health Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            onPressed: () => _showExportOptions(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Icon(Icons.refresh, color: cropGreen),
            label: Text(
              'Refresh Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cropGreen,
              ),
            ),
            onPressed: () async {
              await context.read<StatisticsProvider>().loadStatistics();
              _fadeController.reset();
              _fadeController.forward();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: cropGreen, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 500,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: leafGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.eco,
                  size: 80,
                  color: cropGreen,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Detection History Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: soilDark,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Start scanning your crops to build your farm analytics story',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cropGreen, leafGreen],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cropGreen.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  'Start Scanning',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  // Navigate to Dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(StatisticsProvider provider) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: soilDark,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                provider.error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: () {
                context.read<StatisticsProvider>().loadStatistics();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cropGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThreatLabel(double percentage) {
    if (percentage >= 50) return '🔴 Critical Threat';
    if (percentage >= 30) return '🟠 High Risk';
    if (percentage >= 10) return '🟡 Medium Risk';
    return '🟢 Low Risk';
  }

  Color _getThreatColor(double percentage) {
    if (percentage >= 50) return Colors.red.shade600;
    if (percentage >= 30) return Colors.orange.shade600;
    if (percentage >= 10) return Colors.amber.shade600;
    return leafGreen;
  }

  String _formatDateShort(DateTime date) {
    return '${date.month}/${date.day}';
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Export Health Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: soilDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your preferred format',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            _buildExportOption(
              icon: Icons.table_chart,
              label: 'CSV Report',
              subtitle: 'Spreadsheet format',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _exportAsCSV();
              },
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              icon: Icons.picture_as_pdf,
              label: 'PDF Report',
              subtitle: 'Printable document',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _exportAsPDF();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: soilDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportAsCSV() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.downloading, color: Colors.white),
              SizedBox(width: 12),
              Text('Exporting CSV...'),
            ],
          ),
          backgroundColor: cropGreen,
          duration: const Duration(seconds: 1),
        ),
      );

      final stats = context.read<StatisticsProvider>();
      final detections = stats.diseaseStats.map((ds) => {
        'disease': ds.disease,
        'count': ds.count.toString(),
        'percentage': '${ds.percentage.toStringAsFixed(1)}%',
        'last_detected': ds.lastDetected.toIso8601String(),
      }).toList();

      final file = await ExportService.exportToCSV(detections: detections);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('CSV saved: ${file.path.split('/').last}'),
                ),
              ],
            ),
            backgroundColor: leafGreen,
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () {
                _openFile(file);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Export failed: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _exportAsPDF() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.downloading, color: Colors.white),
              SizedBox(width: 12),
              Text('Exporting PDF...'),
            ],
          ),
          backgroundColor: cropGreen,
          duration: const Duration(seconds: 1),
        ),
      );

      final stats = context.read<StatisticsProvider>();
      final detections = stats.diseaseStats.map((ds) => {
        'disease': ds.disease,
        'count': ds.count.toString(),
        'percentage': '${ds.percentage.toStringAsFixed(1)}%',
        'last_detected': ds.lastDetected.toIso8601String(),
      }).toList();

      final file = await ExportService.exportToPDF(
        detections: detections,
        summary: stats.summary,
        diseaseStats: stats.diseaseStats,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('PDF saved: ${file.path.split('/').last}'),
                ),
              ],
            ),
            backgroundColor: leafGreen,
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () {
                _openFile(file);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Export failed: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  /// Open folder where file is saved
  Future<void> _openFile(File file) async {
    try {
      final directory = file.parent;
      final directoryPath = directory.path;
      final fileName = file.path.split('/').last;
      final isCSV = fileName.toLowerCase().endsWith('.csv');
      
      appLog('Opening: $fileName');
      
      // Platform-specific code to open the folder
      if (Platform.isWindows) {
        // On Windows, use 'explorer.exe' to open the folder and select the file
        await Process.run(
          'explorer.exe',
          ['/select,', file.path],
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.folder_open, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Opening folder with your file',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: leafGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (Platform.isMacOS) {
        // On macOS, use 'open' command to open the folder
        await Process.run('open', ['-R', file.path]);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.folder_open, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Opening folder with your file',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: leafGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (Platform.isLinux) {
        // On Linux, use file manager or open the file
        await Process.run('xdg-open', [directoryPath]);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.folder_open, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Opening folder with your file',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: leafGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (Platform.isMacOS) {
        // On macOS, show the file location instead (open_filex plugin not available)
        _showFileLocationBottomSheet(file, isCSV);
      } else {
        // For mobile platforms (Android, iOS)
        await OpenFilex.open(file.path);
        
        if (mounted) {
          // File opened or app selection was shown
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.file_open, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Opening file...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: leafGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      appLog('Error opening file/folder: $e');
      _showFileLocationBottomSheet(
        file,
        file.path.split('/').last.toLowerCase().endsWith('.csv'),
      );
    }
  }

  /// Show bottom sheet with file location and instructions
  void _showFileLocationBottomSheet(File file, bool isCSV) {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              isCSV ? Icons.table_chart : Icons.picture_as_pdf,
              size: 48,
              color: isCSV ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              isCSV ? 'CSV File Ready' : 'PDF File Ready',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: soilDark,
              ),
            ),
            const SizedBox(height: 12),
            if (isCSV) ...[
              Text(
                'No CSV app found on your device',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Install a spreadsheet app:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Google Sheets (free)\n• Microsoft Excel\n• WPS Office\n• LibreOffice Calc',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Your PDF file is ready to view',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder, size: 20, color: soilDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'File Location:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: soilDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          file.path,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: leafGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Got it!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
