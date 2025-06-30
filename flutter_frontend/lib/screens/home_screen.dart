import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../widgets/header_section.dart';
import '../widgets/hero_section.dart';
import '../widgets/search_section.dart';
import '../widgets/market_overview_section.dart';
import '../widgets/features_section.dart';
import '../widgets/footer_section.dart';
import '../widgets/floating_action_buttons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scrollController.addListener(_onScroll);
    
    // Start animations
    _animationController.forward();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 100 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.darkBackground,
                  Color(0xFF0F1535),
                  AppTheme.darkBackground,
                ],
              ),
            ),
          ),
          
          // Animated particles background
          _buildAnimatedBackground(),
          
          // Main content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const HeaderSection(),
                ),
              ),
              
              // Hero Section
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const HeroSection(),
                ),
              ),
              
              // Search Section
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                  )),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: const SearchSection(),
                  ),
                ),
              ),
              
              // Market Overview
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                  )),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: const MarketOverviewSection(),
                  ),
                ),
              ),
              
              // Features Section
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                  )),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: const FeaturesSection(),
                  ),
                ),
              ),
              
              // Footer
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.6),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                  )),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: const FooterSection(),
                  ),
                ),
              ),
            ],
          ),
          
          // Floating Action Buttons
          const FloatingActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: ParticlesPainter(_animationController.value),
          );
        },
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
      ..color = AppTheme.accentCyan.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw animated particles
    for (int i = 0; i < 30; i++) {
      final x = (size.width / 30) * i + 
          (50 * math.sin(animationValue + i * 0.1));
      final y = (size.height / 20) * (i % 20) + 
          (30 * math.cos(animationValue * 0.8 + i * 0.15));
      
      final radius = 2 + (1 * math.sin(animationValue + i * 0.2)).abs();
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }

    // Draw connecting lines
    final linePaint = Paint()
      ..color = AppTheme.glowColor.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 15; i++) {
      final startX = (size.width / 15) * i;
      final startY = size.height * 0.3 + 
          (100 * math.sin(animationValue + i * 0.3));
      final endX = startX + 200;
      final endY = startY + 
          (50 * math.cos(animationValue * 0.7 + i * 0.2));

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
