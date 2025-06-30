import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          // Main headline
          Text(
            'AI-Powered Crypto\nResearch Platform',
            textAlign: TextAlign.center,
            style: AppTheme.headingLarge.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          
          // Subtitle
          Text(
            'Get comprehensive analysis, real-time insights, and AI-driven predictions\nfor your cryptocurrency investments.',
            textAlign: TextAlign.center,
            style: AppTheme.headingSmall.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          
          // CTA Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Primary CTA
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.glowColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.rocket_launch,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Start Analyzing',
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              
              // Secondary CTA
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.accentCyan, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      color: AppTheme.accentCyan,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Watch Demo',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.accentCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
          
          // Stats section
          Container(
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.glassMorphism,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('10K+', 'Analyses'),
                _buildStatItem('50+', 'Cryptocurrencies'),
                _buildStatItem('95%', 'Accuracy'),
                _buildStatItem('24/7', 'Monitoring'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.accentCyan,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
