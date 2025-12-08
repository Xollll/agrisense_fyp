import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modern Card Widget with consistent styling
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final Border? border;

  const ModernCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius = AppRadius.lg,
    this.onTap,
    this.isLoading = false,
    this.backgroundColor,
    this.shadows,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ??
              (isDark ? const Color(0xFF1F2937) : Colors.white),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows ?? AppShadows.elevationLight,
          border: border,
        ),
        child: isLoading
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            : child,
      ),
    );
  }
}

/// Modern Stat Card for displaying key metrics
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;

    return ModernCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern Alert Card for warnings/info/success messages
class AlertCard extends StatelessWidget {
  final String title;
  final String message;
  final AlertType type;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AlertCard({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
  });

  Color get _backgroundColor {
    return switch (type) {
      AlertType.success => AppColors.success.withOpacity(0.1),
      AlertType.warning => AppColors.warning.withOpacity(0.1),
      AlertType.error => AppColors.danger.withOpacity(0.1),
      AlertType.info => AppColors.info.withOpacity(0.1),
    };
  }

  Color get _accentColor {
    return switch (type) {
      AlertType.success => AppColors.success,
      AlertType.warning => AppColors.warning,
      AlertType.error => AppColors.danger,
      AlertType.info => AppColors.info,
    };
  }

  IconData get _icon {
    return switch (type) {
      AlertType.success => Icons.check_circle,
      AlertType.warning => Icons.warning,
      AlertType.error => Icons.error,
      AlertType.info => Icons.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _icon,
                color: _accentColor,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: _accentColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                ),
                child: Text(actionLabel ?? 'Action'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum AlertType {
  success,
  warning,
  error,
  info,
}
