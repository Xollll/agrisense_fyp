import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class ModernAgricultureSplashScreen extends StatefulWidget {
  const ModernAgricultureSplashScreen({Key? key}) : super(key: key);

  @override
  State<ModernAgricultureSplashScreen> createState() =>
      _ModernAgricultureSplashScreenState();
}

class _ModernAgricultureSplashScreenState
    extends State<ModernAgricultureSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _logoRotation;
  late Animation<double> _pulseAnimation;

  final List<_Particle> _particles = [];

  // Agriculture-themed color palette
  static const Color deepGreen = Color(0xFF1B5E20);
  static const Color forestGreen = Color(0xFF2E7D32);
  static const Color leafGreen = Color(0xFF66BB6A);
  static const Color sunGold = Color(0xFFFFB300);

  @override
  void initState() {
    super.initState();

    // Initialize particles
    _initializeParticles();

    // Main animation sequence
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Continuous particle movement
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 20000),
      vsync: this,
    )..repeat();

    // Shimmer effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    // Pulse effect for logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Subtle rotation
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    // Staggered animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _logoRotation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _mainController.forward();
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 8 + 3,
        speed: random.nextDouble() * 0.3 + 0.1,
        opacity: random.nextDouble() * 0.4 + 0.2,
        type: random.nextInt(3), // 0: leaf, 1: seed, 2: sparkle
        wobbleOffset: random.nextDouble() * math.pi * 2,
        wobbleSpeed: random.nextDouble() * 2 + 1,
      ));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              deepGreen,
              forestGreen,
              leafGreen.withOpacity(0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated grain texture overlay
            _buildTextureOverlay(),

            // Floating particles with realistic motion
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: _ParticlePainter(
                    particles: _particles,
                    animationValue: _particleController.value,
                  ),
                );
              },
            ),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated logo with glow effect
                        _buildAnimatedLogo(),

                        SizedBox(height: 50 - _slideAnimation.value),

                        // App name with shimmer
                        _buildShimmeringText(),

                        const SizedBox(height: 16),

                        // Tagline
                        Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Text(
                            'Smart Farming Solutions',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 2,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),

                        const SizedBox(height: 70),

                        // Custom loading indicator
                        _buildModernLoader(),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom branding
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.eco,
                          color: Colors.white.withOpacity(0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Growing with Technology',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.eco,
                          color: Colors.white.withOpacity(0.7),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextureOverlay() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.03,
        child: CustomPaint(
          painter: _NoisePainter(),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _pulseController,
        _rotateController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: Transform.rotate(
            angle: _logoRotation.value,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: sunGold.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(80),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Image.asset(
                            'assets/app logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmeringText() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              final shimmerValue = _shimmerController.value;
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.7),
                  Colors.white,
                  sunGold.withOpacity(0.9),
                  Colors.white,
                  Colors.white.withOpacity(0.7),
                ],
                stops: [
                  0.0,
                  math.max(0.0, shimmerValue - 0.3),
                  shimmerValue,
                  math.min(1.0, shimmerValue + 0.3),
                  1.0,
                ],
              ).createShader(bounds);
            },
            child: const Text(
              'AgriSense',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernLoader() {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          // Animated dots loader
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final animation =
                      math.sin((_particleController.value + delay) * math.pi * 2);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Transform.translate(
                      offset: Offset(0, animation * 8),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: sunGold.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
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
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: null,
                  minHeight: 4,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    sunGold.withOpacity(0.8),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your farm insights...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Particle data class
class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final int type;
  final double wobbleOffset;
  final double wobbleSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.type,
    required this.wobbleOffset,
    required this.wobbleSpeed,
  });
}

// Custom painter for particles
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final progress = (animationValue * particle.speed) % 1.0;
      final wobble = math.sin(
            (animationValue * particle.wobbleSpeed + particle.wobbleOffset) *
                math.pi *
                2,
          ) *
          20;

      final x = particle.x * size.width + wobble;
      final y = (particle.y + progress) * size.height % size.height;

      final paint = Paint()
        ..color = Colors.white.withOpacity(
          particle.opacity * (1 - progress * 0.3),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      if (particle.type == 0) {
        // Leaf shape
        _drawLeaf(canvas, Offset(x, y), particle.size, paint);
      } else if (particle.type == 1) {
        // Seed/dot
        canvas.drawCircle(Offset(x, y), particle.size, paint);
      } else {
        // Sparkle
        _drawSparkle(canvas, Offset(x, y), particle.size, paint);
      }
    }
  }

  void _drawLeaf(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(
      center.dx + size * 0.7,
      center.dy,
      center.dx,
      center.dy + size,
    );
    path.quadraticBezierTo(
      center.dx - size * 0.7,
      center.dy,
      center.dx,
      center.dy - size,
    );
    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) + (animationValue * math.pi * 2);
      final x1 = center.dx + math.cos(angle) * size;
      final y1 = center.dy + math.sin(angle) * size;
      final x2 = center.dx + math.cos(angle) * size * 0.3;
      final y2 = center.dy + math.sin(angle) * size * 0.3;

      path.moveTo(center.dx, center.dy);
      path.lineTo(x1, y1);
      path.lineTo(x2, y2);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

// Noise texture painter for subtle grain effect
class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(42); // Fixed seed for consistent pattern

    for (int i = 0; i < 1000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}