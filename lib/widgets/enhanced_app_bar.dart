import 'package:flutter/material.dart';

/// A modern, minimalist app bar builder that provides consistent,
/// clean app bars across all pages in the AgriSense app.
/// Features smooth animations and beautiful design.
class AppBarBuilder {
  /// Builds a modern animated app bar for the Dashboard page
  static Widget dashboard({
    required BuildContext context,
    required VoidCallback onMenuPressed,
  }) {
    return ModernAnimatedAppBar(
      title: 'Dashboard',
      subtitle: 'Crop Monitoring',
      icon: Icons.dashboard_rounded,
      onMenuPressed: onMenuPressed,
    );
  }

  /// Builds a modern animated app bar for the History page
  static Widget history({
    required BuildContext context,
    required VoidCallback onMenuPressed,
  }) {
    return ModernAnimatedAppBar(
      title: 'History',
      subtitle: 'Detection Records',
      icon: Icons.history_rounded,
      onMenuPressed: onMenuPressed,
    );
  }

  /// Builds a modern animated app bar for the Statistics page
  static Widget statistics({
    required BuildContext context,
    required VoidCallback onMenuPressed,
  }) {
    return ModernAnimatedAppBar(
      title: 'Statistics',
      subtitle: 'Analytics & Insights',
      icon: Icons.bar_chart_rounded,
      onMenuPressed: onMenuPressed,
    );
  }

  /// Builds a modern animated app bar for the Settings page
  static Widget settings({
    required BuildContext context,
    required VoidCallback onMenuPressed,
  }) {
    return ModernAnimatedAppBar(
      title: 'Settings',
      subtitle: 'Configuration',
      icon: Icons.settings_rounded,
      onMenuPressed: onMenuPressed,
    );
  }
}

/// A modern, animated app bar widget with beautiful design and smooth animations.
/// Features:
/// - Beautiful gradient background with rounded bottom corners
/// - Smooth fade-in animation on page load
/// - Menu button for navigation drawer
/// - Page title and subtitle
/// - Icon representing the page
/// - Theme-aware and responsive
/// - Enhanced visual design with proper spacing
class ModernAnimatedAppBar extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onMenuPressed;

  const ModernAnimatedAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onMenuPressed,
  });

  @override
  State<ModernAnimatedAppBar> createState() => _ModernAnimatedAppBarState();
}

class _ModernAnimatedAppBarState extends State<ModernAnimatedAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start animation when widget loads
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 105,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade500,
              Colors.green.shade700,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              // Hamburger Menu Button - Clean Design
              IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: widget.onMenuPressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: 'Open menu',
                splashRadius: 24,
              ),

              const SizedBox(width: 8),

              // Icon with beautiful styling
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  widget.icon,
                  color: Colors.white.withOpacity(0.95),
                  size: 28,
                ),
              ),

              /// Title and Subtitle Column
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
