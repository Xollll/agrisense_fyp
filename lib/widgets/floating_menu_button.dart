import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as dart_math;
import '../theme/app_theme.dart';

/// 🌱 Agriculture-Themed Floating Action Menu
/// Modern design with nature-inspired elements
/// Features:
/// - Organic leaf/seed animations
/// - Nature-inspired color scheme
/// - Smooth particle effects
/// - Contextual agriculture icons
/// - Enhanced glassmorphism
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
  late AnimationController _rotateController;
  late AnimationController _particleController;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _menuController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
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
        // Enhanced Backdrop with gradient
        if (_isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(parent: _menuController, curve: Curves.easeOut),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomRight,
                      radius: 1.5,
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Floating particles effect when menu opens
        if (_isMenuOpen)
          Positioned(
            bottom: 50,
            right: 50,
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return Stack(
                  children: List.generate(8, (index) {
                    final angle = (index * 45.0) * (3.14159 / 180);
                    final distance = 40 + (_particleController.value * 30);
                    return Transform.translate(
                      offset: Offset(
                        distance * dart_math.cos(angle),
                        distance * dart_math.sin(angle),
                      ),
                      child: Opacity(
                        opacity: 1 - _particleController.value,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.6),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

        // Menu Panel
        Positioned(
          bottom: 100,
          right: 30,
          child: IgnorePointer(
            ignoring: !_isMenuOpen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quick Actions - Enhanced with agriculture theme
                if (widget.quickActions.isNotEmpty)
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.5, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _menuController,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(
                      opacity: _menuController,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildGlassmorphicContainer(
                          isDark: isDark,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Enhanced header with leaf icon
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.amber.shade400,
                                            Colors.orange.shade400,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.bolt_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Quick Actions',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: isDark
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade800,
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
                                      e.key,
                                    ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Page Navigation - Enhanced stagger animation
                ...widget.items.asMap().entries.map((e) {
                  final isSelected = widget.currentIndex == e.key;
                  final delay = e.key * 0.05;
                  
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.5, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _menuController,
                      curve: Interval(
                        delay,
                        0.5 + delay,
                        curve: Curves.easeOutCubic,
                      ),
                    )),
                    child: FadeTransition(
                      opacity: _menuController,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            widget.onItemSelected(e.key);
                            _closeMenu();
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Page Name with enhanced style
                              _buildGlassmorphicContainer(
                                isDark: isDark,
                                compact: true,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    e.value.title,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      fontSize: 13,
                                      letterSpacing: 0.3,
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark
                                              ? Colors.grey.shade300
                                              : Colors.grey.shade800),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Enhanced Page Icon with gradient
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isSelected
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primary.withOpacity(0.8),
                                          ],
                                        )
                                      : null,
                                  color: isSelected ? null : Colors.grey.shade300,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isSelected
                                              ? AppColors.primary
                                              : Colors.grey.shade400)
                                          .withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isSelected
                                      ? e.value.selectedIcon
                                      : e.value.icon,
                                  color: isSelected 
                                    ? Colors.white 
                                    : Colors.grey.shade700,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

        // Main FAB - Enhanced with leaf rotation
        Positioned(
          bottom: 30,
          right: 30,
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _rotateController]),
              builder: (context, child) {
                // Subtle pulse effect
                final pulseScale = 1.0 + (_pulseController.value * 0.03);
                
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring (only when closed) - scales with pulse
                    if (!_isMenuOpen)
                      Transform.scale(
                        scale: pulseScale,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    
                    // Main button - fixed position, icon scales internally
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        shape: const CircleBorder(),
                        elevation: 0,
                        child: Ink(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.85),
                              ],
                            ),
                          ),
                          child: InkWell(
                            onTap: _toggleMenu,
                            customBorder: const CircleBorder(),
                            splashColor: Colors.white.withOpacity(0.3),
                            child: Container(
                              width: 70,
                              height: 70,
                              alignment: Alignment.center,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return RotationTransition(
                                    turns: animation,
                                    child: ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Icon(
                                  _isMenuOpen
                                      ? Icons.close_rounded
                                      : Icons.eco_rounded,
                                  key: ValueKey(_isMenuOpen),
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassmorphicContainer({
    required Widget child,
    required bool isDark,
    bool compact = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 16 : 24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: compact 
            ? const EdgeInsets.all(0) 
            : const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.grey.shade900.withOpacity(0.75),
                      Colors.grey.shade900.withOpacity(0.65),
                    ]
                  : [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(compact ? 16 : 24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    QuickActionConfig action,
    bool isDark,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: InkWell(
            onTap: () {
              action.onTap();
              _closeMenu();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    action.color.withOpacity(0.2),
                    action.color.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: action.color.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: action.color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action.icon, color: action.color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    action.label,
                    style: TextStyle(
                      color: action.color.withOpacity(0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

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