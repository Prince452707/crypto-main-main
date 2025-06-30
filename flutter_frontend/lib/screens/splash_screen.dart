import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particleController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _particleAnimation;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeInOut,
      ),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.easeInOut,
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 800));
    _particleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 1000));
    _textController.forward();
    
    await Future.delayed(const Duration(milliseconds: 4000));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF1E3A8A),
                  Color(0xFF0A0E27),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),
          
          // Animated particles
          AnimatedBuilder(
            animation: _particleAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlesPainter(_particleAnimation.value),
                size: Size.infinite,
              );
            },
          ),
          
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Transform.rotate(
                        angle: _logoRotation.value * 2 * math.pi * 0.1,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue,
                                AppTheme.accentCyan,
                                AppTheme.successGreen,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentCyan.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            FontAwesomeIcons.bitcoin,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Animated text
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        Text(
                          'CryptoAI',
                          style: GoogleFonts.orbitron(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Research Platform',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: AppTheme.textSecondary,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          width: 200,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.accentCyan,
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'AI-Powered Cryptocurrency Analysis',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textTertiary,
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
        ],
      ),
    );
  }
}

class ParticlesPainter extends CustomPainter {
  final double animationValue;
  
  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw animated particles
    for (int i = 0; i < 50; i++) {
      final angle = (i / 50) * 2 * math.pi;
      final radius = 100 + (200 * animationValue);
      final x = size.width / 2 + radius * math.cos(angle + animationValue * 2 * math.pi);
      final y = size.height / 2 + radius * math.sin(angle + animationValue * 2 * math.pi);
      
      final particleSize = 2 + (3 * math.sin(animationValue * 4 + i)).abs();
      
      paint.color = Color.lerp(
        AppTheme.accentCyan.withOpacity(0.3),
        AppTheme.primaryBlue.withOpacity(0.6),
        (math.sin(animationValue * 3 + i) + 1) / 2,
      )!;
      
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );
    }

    // Draw connecting lines
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 20; i++) {
      final startAngle = (i / 20) * 2 * math.pi;
      final endAngle = ((i + 1) / 20) * 2 * math.pi;
      
      final startRadius = 120 + (150 * animationValue);
      final endRadius = 120 + (150 * animationValue);
      
      final startX = size.width / 2 + startRadius * math.cos(startAngle + animationValue * math.pi);
      final startY = size.height / 2 + startRadius * math.sin(startAngle + animationValue * math.pi);
      
      final endX = size.width / 2 + endRadius * math.cos(endAngle + animationValue * math.pi);
      final endY = size.height / 2 + endRadius * math.sin(endAngle + animationValue * math.pi);
      
      linePaint.color = AppTheme.glowColor.withOpacity(0.1 * animationValue);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
