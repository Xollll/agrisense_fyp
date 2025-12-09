import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

/// 🎯 Minimalist Floating Action Menu Button
/// Clean, elegant design with smooth animations
/// Features:
/// - Smooth slide-up animation for menu
/// - Minimalist circular button design
/// - Glassmorphic menu panel
/// - Elegant icon transitions
/// - Theme-aware with dark mode support
class FloatingMenuButton extends StatefulWidget {
  final int currentIndex;
  final List<MenuItemConfig> items;
  final List<QuickActionConfig> quickActions;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onMenuClosed;

  const FloatingMenuButton({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.quickActions,
    required this.onItemSelected,
    this.onMenuClosed,
  });

  @override
  State<FloatingMenuButton> createState() => _FloatingMenuButtonState();
}

class _FloatingMenuButtonState extends State<FloatingMenuButton>
    with TickerProviderStateMixin {
  late AnimationController _menuController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _menuController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _menuController.reverse();
    } else {
      _menuController.forward();
    }
    setState(() => _isMenuOpen = !_isMenuOpen);
  }

  void _closeMenu() {
    if (_isMenuOpen) {
      _menuController.reverse();
      setState(() => _isMenuOpen = false);
      widget.onMenuClosed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Backdrop
        if (_isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(parent: _menuController, curve: Curves.easeOut),
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
          ),

        // Menu Panel - Vertical icons above FAB with page names
        Positioned(
          bottom: 100,
          right: 30,
          child: GestureDetector(
            onTap: () {}, // Prevent dismissing menu when tapping on menu items
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quick Actions Section (FIRST - Above Page Icons)
                if (widget.quickActions.isNotEmpty)
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                        .animate(CurvedAnimation(
                          parent: _menuController,
                          curve: Curves.easeOut,
                        )),
                    child: FadeTransition(
                      opacity: _menuController,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildGlassmorphicContainer(
                          isDark: isDark,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.flash_on_rounded,
                                      size: 16,
                                      color: Colors.amber.shade400,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Quick Actions',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: isDark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.quickActions
                                    .asMap()
                                    .entries
                                    .map((e) => _buildQuickActionButton(
                                      context,
                                      e.value,
                                      isDark,
                                    ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Page Navigation Icons (Vertical Stack - BELOW Quick Actions)
                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                      .animate(CurvedAnimation(parent: _menuController, curve: Curves.easeOut)),
                  child: FadeTransition(
                    opacity: _menuController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: widget.items
                          .asMap()
                          .entries
                          .map((e) {
                        final isSelected = widget.currentIndex == e.key;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              widget.onItemSelected(e.key);
                              _closeMenu();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Page Name
                                _buildGlassmorphicContainer(
                                  isDark: isDark,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      e.value.title,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        fontSize: 13,
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isDark
                                                ? Colors.grey.shade300
                                                : Colors.grey.shade800),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Page Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isSelected
                                                ? AppColors.primary
                                                : Colors.grey.shade300)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isSelected
                                        ? e.value.selectedIcon
                                        : e.value.icon,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Main FAB Button - Minimalist design
        Positioned(
          bottom: 30,
          right: 30,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1, end: 0.9).animate(
              CurvedAnimation(parent: _menuController, curve: Curves.easeOut),
            ),
            child: AnimatedBuilder(
                animation: Listenable.merge([_pulseController, _bounceController]),
                builder: (context, child) {
                  final bounceOffset = _isMenuOpen 
                    ? 0.0
                    : ((_bounceController.value - 0.5).abs() * 6);
                  
                  return Transform.translate(
                    offset: Offset(0, -bounceOffset),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          // Primary shadow
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                          // Secondary shadow for depth
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        shape: const CircleBorder(),
                        elevation: 0,
                        child: Ink(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: InkWell(
                            onTap: _toggleMenu,
                            customBorder: const CircleBorder(),
                            splashColor: Colors.white.withOpacity(0.2),
                            child: Container(
                              width: 70,
                              height: 70,
                              alignment: Alignment.center,
                              // Icon with subtle shadow effect
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Icon shadow layer (behind)
                                  Opacity(
                                    opacity: 0.15,
                                    child: Transform.translate(
                                      offset: const Offset(0, 1),
                                      child: Icon(
                                        _isMenuOpen 
                                          ? Icons.close_rounded 
                                          : Icons.eco_rounded,
                                        color: Colors.black,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  // Icon foreground
                                  Icon(
                                    _isMenuOpen 
                                      ? Icons.close_rounded 
                                      : Icons.eco_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ),
        ),
      ],
    );
  }

  /// Glassmorphism Container
  Widget _buildGlassmorphicContainer({
    required Widget child,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey.shade900.withOpacity(0.7)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  /// Quick Action Button
  Widget _buildQuickActionButton(
    BuildContext context,
    QuickActionConfig action,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        action.onTap();
        _closeMenu();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: action.color.withOpacity(0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, color: action.color, size: 16),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: TextStyle(
                color: action.color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menu Item Configuration
class MenuItemConfig {
  final String title;
  final String? subtitle;
  final IconData icon;
  final IconData selectedIcon;

  MenuItemConfig({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.selectedIcon,
  });
}

/// Quick Action Configuration
class QuickActionConfig {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  QuickActionConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

