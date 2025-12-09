import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

/// 🚀 Ultra-Modern Floating Action Menu Button
/// Premium design with glassmorphism, gradient, neon effects
/// Features:
/// - Animated menu with smooth transitions
/// - Gradient background with glassmorphism
/// - Glowing neon effects
/// - Ripple & bounce animations
/// - Modern card design for menu items
/// - Theme-aware with dark mode support
/// - Custom animated AI/tech icon with particle effects
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

        // Menu Panel
        Positioned(
          bottom: 30,
          right: 30,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.3, 0.3), end: Offset.zero)
                .animate(CurvedAnimation(parent: _menuController, curve: Curves.easeOut)),
            child: FadeTransition(
              opacity: _menuController,
              child: GestureDetector(
                onTap: () {},
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Quick Actions
                    if (widget.quickActions.isNotEmpty) ...[
                      _buildGlassmorphicContainer(
                        isDark: isDark,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
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
                      const SizedBox(height: 12),
                    ],

                    // Navigation Items
                    _buildGlassmorphicContainer(
                      isDark: isDark,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.items
                            .asMap()
                            .entries
                            .map((e) => _buildMenuItemCard(
                              context,
                              e.value,
                              e.key,
                              isDark,
                            ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Main FAB Button
        Positioned(
          bottom: 30,
          right: 30,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1, end: 0.85).animate(
              CurvedAnimation(parent: _menuController, curve: Curves.easeOut),
            ),
            child: RotationTransition(
              turns: Tween<double>(begin: 0, end: 0.375).animate(
                CurvedAnimation(parent: _menuController, curve: Curves.easeInOut),
              ),
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseController, _bounceController]),
                builder: (context, child) {
                  final bounceOffset = _isMenuOpen 
                    ? 0.0
                    : ((_bounceController.value - 0.5).abs() * 8);
                  
                  return Transform.translate(
                    offset: Offset(0, -bounceOffset),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          // Primary cyan glow
                          BoxShadow(
                            color: Colors.cyan.withOpacity(0.6),
                            blurRadius: 35,
                            spreadRadius: 5,
                          ),
                          // Secondary purple glow
                          BoxShadow(
                            color: Colors.purple.shade400.withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 8,
                          ),
                          // Tertiary blue glow
                          BoxShadow(
                            color: Colors.blue.shade400.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                          // Deep shadow
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
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
                                Colors.cyan.shade300,
                                Colors.blue.shade500,
                                Colors.indigo.shade600,
                                Colors.purple.shade600,
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
                              child: CustomPaint(
                                painter: AnimatedAIIconPainter(
                                  progress: _menuController.value,
                                  pulseProgress: _pulseController.value,
                                  isOpen: _isMenuOpen,
                                ),
                                size: const Size(70, 70),
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

  /// Menu Item Card
  Widget _buildMenuItemCard(
    BuildContext context,
    MenuItemConfig item,
    int index,
    bool isDark,
  ) {
    final isSelected = widget.currentIndex == index;
    final accentColor = Colors.blue.shade500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () {
          widget.onItemSelected(index);
          _closeMenu();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor.withOpacity(0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected ? accentColor : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                      color: isSelected
                          ? accentColor
                          : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                    ),
                  ),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ],
          ),
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

/// 🎨 Animated AI Icon Painter
/// Creates a dynamic circuit/neural network icon with morphing and particle effects
class AnimatedAIIconPainter extends CustomPainter {
  final double progress;
  final double pulseProgress;
  final bool isOpen;

  AnimatedAIIconPainter({
    required this.progress,
    required this.pulseProgress,
    required this.isOpen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final baseRadius = 12.0;
    final glow = 4 + (pulseProgress * 2);

    // Draw multiple glowing layers for depth
    _drawGlowLayer(canvas, centerX, centerY, baseRadius + glow, 0.15);
    _drawGlowLayer(canvas, centerX, centerY, baseRadius + glow / 1.5, 0.2);

    // Core neural network nodes
    _drawNeuralNetwork(canvas, centerX, centerY, baseRadius, progress, pulseProgress);

    // Animated connecting lines
    _drawConnectingLines(canvas, centerX, centerY, baseRadius, progress, pulseProgress);

    // Particle burst effect (enhanced when opening)
    _drawParticles(canvas, centerX, centerY, progress, pulseProgress);
  }

  void _drawGlowLayer(Canvas canvas, double cx, double cy, double radius, double opacity) {
    final glowPaint = Paint()
      ..color = Colors.cyan.withOpacity(opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);

    canvas.drawCircle(Offset(cx, cy), radius, glowPaint);
  }

  void _drawNeuralNetwork(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    double progress,
    double pulseProgress,
  ) {
    final nodes = 5; // Number of nodes in the network
    final nodeRadius = 2.5 + (pulseProgress * 0.8);

    for (int i = 0; i < nodes; i++) {
      final angle = (i / nodes) * 2 * 3.14159265359 + progress * 2 * 3.14159265359;
      final x = cx + math.cos(angle) * radius;
      final y = cy + math.sin(angle) * radius;

      // Pulsing node
      final nodePaint = Paint()
        ..color = Color.lerp(Colors.cyan, Colors.purple, (i / nodes))!
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), nodeRadius, nodePaint);

      // Glow around node
      final glowPaint = Paint()
        ..color = Color.lerp(Colors.cyan, Colors.purple, (i / nodes))!
            .withOpacity(0.4 - (pulseProgress * 0.2))
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 2);

      canvas.drawCircle(Offset(x, y), nodeRadius + 2, glowPaint);
    }

    // Central node
    final centerNodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final centerNodeGlow = 3.5 + (pulseProgress * 1.5);
    canvas.drawCircle(Offset(cx, cy), 2.5, centerNodePaint);

    final centerGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.6 - (pulseProgress * 0.3))
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);
    
    canvas.drawCircle(Offset(cx, cy), centerNodeGlow, centerGlowPaint);
  }

  void _drawConnectingLines(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    double progress,
    double pulseProgress,
  ) {
    final nodes = 5;
    final linePaint = Paint()
      ..strokeWidth = 1.2 + (pulseProgress * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < nodes; i++) {
      final angle1 = (i / nodes) * 2 * 3.14159265359 + progress * 2 * 3.14159265359;
      final angle2 = ((i + 1) / nodes) * 2 * 3.14159265359 + progress * 2 * 3.14159265359;

      final x1 = cx + math.cos(angle1) * radius;
      final y1 = cy + math.sin(angle1) * radius;
      final x2 = cx + math.cos(angle2) * radius;
      final y2 = cy + math.sin(angle2) * radius;

      // Gradient color for the line
      final colorProgress = i / nodes;
      final lineColor = Color.lerp(Colors.cyan, Colors.purple, colorProgress)!
          .withOpacity(0.6 + (pulseProgress * 0.2));

      linePaint.color = lineColor;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);

      // Animated dot along the line
      final dotProgress = (progress * 2 + (i / nodes)) % 1.0;
      final dotX = x1 + (x2 - x1) * dotProgress;
      final dotY = y1 + (y2 - y1) * dotProgress;

      final dotPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dotX, dotY), 1.2, dotPaint);
    }

    // Connect all nodes to center
    for (int i = 0; i < nodes; i++) {
      final angle = (i / nodes) * 2 * 3.14159265359 + progress * 2 * 3.14159265359;
      final x = cx + math.cos(angle) * radius;
      final y = cy + math.sin(angle) * radius;

      final colorProgress = i / nodes;
      final lineColor = Color.lerp(Colors.cyan, Colors.purple, colorProgress)!
          .withOpacity(0.4 + (pulseProgress * 0.15));

      linePaint.color = lineColor;
      linePaint.strokeWidth = 0.8 + (pulseProgress * 0.2);
      canvas.drawLine(Offset(cx, cy), Offset(x, y), linePaint);
    }
  }

  void _drawParticles(
    Canvas canvas,
    double cx,
    double cy,
    double progress,
    double pulseProgress,
  ) {
    final particleCount = 8;
    final particleExpansion = progress * 15;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * 3.14159265359;
      final distance = 8 + particleExpansion;
      final x = cx + math.cos(angle) * distance;
      final y = cy + math.sin(angle) * distance;

      // Fade out as it expands
      final opacity = (1 - progress) * (0.6 + pulseProgress * 0.2);

      final particlePaint = Paint()
        ..color = Colors.cyan.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 1.2 - (progress * 0.8), particlePaint);
    }

    // Inner rotating ring
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.5 + (pulseProgress * 0.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final ringRadius = 8 + (pulseProgress * 1);
    canvas.drawCircle(Offset(cx, cy), ringRadius, ringPaint);
  }

  @override
  bool shouldRepaint(AnimatedAIIconPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.isOpen != isOpen;
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

