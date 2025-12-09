import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

/// A modern, minimalist app bar builder that provides consistent,
/// clean app bars across all pages in the AgriSense app.
/// Features smooth animations and beautiful design with glassmorphism.
class AppBarBuilder {
  /// Builds a modern animated app bar for the Dashboard page (with notification icon)
  static Widget dashboard({
    required BuildContext context,
    required VoidCallback onMenuPressed,
    int notificationCount = 3,
  }) {
    return ModernAnimatedAppBar(
      title: 'AgriSense',
      subtitle: 'PRECISION AGRICULTURE',
      icon: Icons.eco_rounded,
      onMenuPressed: onMenuPressed,
      showNotification: true,
      notificationCount: notificationCount,
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
      showNotification: false,
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
      showNotification: false,
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
      showNotification: false,
    );
  }
}

/// A modern, animated app bar widget with beautiful design and smooth animations.
/// Enhanced Features:
/// - Time-based gradient colors (sunrise/day/sunset)
/// - Floating seed particles animation
/// - Decorative leaf patterns
/// - Weather icon integration
/// - Wave pattern accent bar
/// - Enhanced shadows and depth
/// - Micro-interactions on notification
class ModernAnimatedAppBar extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onMenuPressed;
  final bool showNotification;
  final int notificationCount;

  const ModernAnimatedAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onMenuPressed,
    this.showNotification = false,
    this.notificationCount = 0,
  });

  @override
  State<ModernAnimatedAppBar> createState() => _ModernAnimatedAppBarState();
}

class _ModernAnimatedAppBarState extends State<ModernAnimatedAppBar>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _particleAnimationController;
  late AnimationController _notificationShakeController;
  late Animation<double> _fadeAnimation;
  
  // Particle positions
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    
    // Fade animation for initial load
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );

    // Pulse animation for gradient
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    // Particle animation
    _particleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 20000),
      vsync: this,
    )..repeat();

    // Notification shake animation
    _notificationShakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimationController.forward();
    
    // Initialize particles
    _initializeParticles();
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          speed: 0.1 + random.nextDouble() * 0.2,
          size: 2 + random.nextDouble() * 3,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _pulseAnimationController.dispose();
    _particleAnimationController.dispose();
    _notificationShakeController.dispose();
    super.dispose();
  }

  /// Get gradient colors based on time of day
  List<Color> _getTimeBasedGradient() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 8) {
      // Sunrise - Orange to Green
      return [
        const Color(0xFFEA580C),
        const Color(0xFFF59E0B),
        const Color(0xFF10B981),
      ];
    } else if (hour >= 17 && hour < 20) {
      // Sunset - Purple to Green
      return [
        const Color(0xFF7C3AED),
        const Color(0xFFA855F7),
        const Color(0xFF10B981),
      ];
    } else if (hour >= 20 || hour < 5) {
      // Night - Deep Blue to Dark Green
      return [
        const Color(0xFF1E3A8A),
        const Color(0xFF065F46),
        const Color(0xFF047857),
      ];
    } else {
      // Day - Classic Green
      return [
        const Color(0xFF059669),
        const Color(0xFF10B981),
        const Color(0xFF34D399),
      ];
    }
  }

  /// Get weather icon based on time (simplified)
  IconData _getWeatherIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 18) {
      return Icons.wb_sunny_rounded;
    } else {
      return Icons.nightlight_round;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Main App Bar Container
          Container(
            height: 130,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Animated Background Gradient with Time-based Colors
                AnimatedBuilder(
                  animation: _pulseAnimationController,
                  builder: (context, child) {
                    final opacity = 0.7 + (_pulseAnimationController.value * 0.15);
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getTimeBasedGradient(),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Floating Seed Particles
                AnimatedBuilder(
                  animation: _particleAnimationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ParticlePainter(
                        particles: _particles,
                        animation: _particleAnimationController.value,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),

                // Decorative Leaf Pattern - Top Right
                Positioned(
                  top: 15,
                  right: 70,
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Icon(
                      Icons.eco_outlined,
                      size: 50,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),

                // Decorative Leaf Pattern - Middle Left
                Positioned(
                  top: 50,
                  left: 30,
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Icon(
                      Icons.grass_rounded,
                      size: 35,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),

                // Organic Shape Overlays - Top Right
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.shade400.withOpacity(0.15),
                    ),
                  ),
                ),

                // Organic Shape Overlays - Bottom Left
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.shade400.withOpacity(0.15),
                    ),
                  ),
                ),

                // Glassmorphism Content Container
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Branding with Enhanced Icon
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade300,
                                    Colors.amber.shade600,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.shade400.withOpacity(0.5),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.amber.shade200.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Title and Subtitle with Weather Icon
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        _getWeatherIcon(),
                                        size: 11,
                                        color: Colors.yellow.shade200,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.subtitle,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade100,
                                            letterSpacing: 0.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Notification Button - Only on Dashboard
                            if (widget.showNotification)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _buildNotificationButton(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Wave Pattern Accent Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: WavePainter(
                    animation: _pulseAnimationController.value,
                  ),
                  size: const Size(double.infinity, 6),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build notification button with enhanced animations
  Widget _buildNotificationButton() {
    return GestureDetector(
      onTap: () {
        _notificationShakeController.forward(from: 0);
      },
      child: AnimatedBuilder(
        animation: _notificationShakeController,
        builder: (context, child) {
          final shake = math.sin(_notificationShakeController.value * math.pi * 4) * 3;
          return Transform.translate(
            offset: Offset(shake, 0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                // Notification Badge - Outside and Top Right
                if (widget.notificationCount > 0)
                  Positioned(
                    top: -10,
                    right: -10,
                    child: AnimatedBuilder(
                      animation: _pulseAnimationController,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseAnimationController.value * 0.1);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade500,
                                  Colors.pink.shade500,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                widget.notificationCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Particle class for seed animation
class Particle {
  double x;
  double y;
  final double speed;
  final double size;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
  });
}

/// Custom painter for floating seed particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;

  ParticlePainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      // Update particle position
      particle.y = (particle.y + particle.speed * 0.01) % 1.0;
      
      final dx = particle.x * size.width;
      final dy = particle.y * size.height;
      
      canvas.drawCircle(
        Offset(dx, dy),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

/// Custom painter for wave pattern
class WavePainter extends CustomPainter {
  final double animation;

  WavePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.amber.shade300,
          Colors.lime.shade400,
          Colors.green.shade400,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.5 +
            math.sin((i / size.width * 4 * math.pi) + (animation * 2 * math.pi)) * 2,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Add shimmer effect
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.4 + animation * 0.2),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}