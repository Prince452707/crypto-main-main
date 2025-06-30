import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          // Section title
          Text(
            'Powerful Features',
            style: AppTheme.headingLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Everything you need for comprehensive cryptocurrency analysis',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          
          // Features grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 
                           MediaQuery.of(context).size.width > 768 ? 2 : 1,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: MediaQuery.of(context).size.width > 768 ? 1.1 : 1.2,
            children: [
              _buildFeatureCard(
                Icons.auto_awesome,
                'AI-Powered Analysis',
                'Get comprehensive insights powered by advanced machine learning algorithms',
                AppTheme.accentCyan,
              ),
              _buildFeatureCard(
                Icons.trending_up,
                'Technical Analysis',
                'Advanced charting tools with support for multiple technical indicators',
                AppTheme.successGreen,
              ),
              _buildFeatureCard(
                Icons.newspaper,
                'News Sentiment',
                'Real-time news analysis and sentiment scoring for market insights',
                AppTheme.warningOrange,
              ),
              _buildFeatureCard(
                Icons.psychology,
                'Behavioral Analysis',
                'Understanding market psychology and crowd behavior patterns',
                AppTheme.errorRed,
              ),
              _buildFeatureCard(
                Icons.security,
                'Risk Assessment',
                'Comprehensive risk analysis with portfolio optimization suggestions',
                AppTheme.primaryBlue,
              ),
              _buildFeatureCard(
                Icons.speed,
                'Real-time Data',
                '24/7 monitoring with instant alerts and live market updates',
                AppTheme.glowColor,
              ),
            ],
          ),
          const SizedBox(height: 60),
          
          // Additional benefits section
          Container(
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.glassMorphism,
            child: Column(
              children: [
                Text(
                  'Why Choose Crypto Insight?',
                  style: AppTheme.headingMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBenefitItem(
                      Icons.verified,
                      'Accurate',
                      '95% prediction accuracy',
                    ),
                    _buildBenefitItem(
                      Icons.flash_on,
                      'Fast',
                      'Real-time analysis',
                    ),
                    _buildBenefitItem(
                      Icons.lock,
                      'Secure',
                      'Enterprise-grade security',
                    ),
                    _buildBenefitItem(
                      Icons.support_agent,
                      'Support',
                      '24/7 customer support',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassMorphism,
      child: Column(
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            title,
            style: AppTheme.headingSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Description
          Text(
            description,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
