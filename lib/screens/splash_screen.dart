import 'package:flutter/material.dart';
import 'dart:math' as math;

class LivelyAgricultureSplashScreen extends StatefulWidget {
  const LivelyAgricultureSplashScreen({Key? key}) : super(key: key);

  @override
  State<LivelyAgricultureSplashScreen> createState() =>
      _LivelyAgricultureSplashScreenState();
}

class _LivelyAgricultureSplashScreenState
    extends State<LivelyAgricultureSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Fresh, vibrant palette
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF388E3C);
  static const Color lightBg = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF1F8F4),
              Color(0xFFE8F5E9),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Soft wave pattern
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _WaveBackgroundPainter(
                    animationValue: _controller.value,
                  ),
                );
              },
            ),

            // Main content
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),

                          // Simple logo with bounce
                          _buildLogo(),

                          const SizedBox(height: 32),

                          // App name
                          const Text(
                            'AgriSense',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                              letterSpacing: 1,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Simple tagline
                          Text(
                            'Smart Farming Solutions',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              letterSpacing: 0.5,
                            ),
                          ),

                          const Spacer(flex: 1),

                          // Clean spinner
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Loading text
                          Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              letterSpacing: 1,
                            ),
                          ),

                          const Spacer(flex: 2),

                          // Bottom caption
                          Padding(
                            padding: const EdgeInsets.only(bottom: 50),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.eco,
                                  color: primaryGreen.withOpacity(0.7),
                                  size: 20,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Empowering Farmers with Technology',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 2000),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * math.pi,
                child: Container(
                  width: 115,
                  height: 115,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryGreen.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CustomPaint(
                    painter: _SimpleDotsPainter(
                      color: primaryGreen,
                    ),
                  ),
                ),
              );
            },
          ),

          // Logo
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'assets/app logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleDotsPainter extends CustomPainter {
  final Color color;

  _SimpleDotsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw 3 evenly spaced dots
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) - math.pi / 2;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      
      canvas.drawCircle(Offset(x, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaveBackgroundPainter extends CustomPainter {
  final double animationValue;

  _WaveBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Bottom wave
    paint.color = const Color(0xFF4CAF50).withOpacity(0.08);
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.65,
      size.width * 0.5,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.75,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Top decorative circles
    paint.color = const Color(0xFF66BB6A).withOpacity(0.05);
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.2),
      80,
      paint,
    );
    
    paint.color = const Color(0xFF81C784).withOpacity(0.05);
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      60,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}