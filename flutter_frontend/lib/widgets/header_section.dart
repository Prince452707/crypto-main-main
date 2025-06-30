import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and brand
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crypto Insight',
                    style: AppTheme.headingMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'AI Research Platform',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Navigation menu (for larger screens)
          if (MediaQuery.of(context).size.width > 768)
            Row(
              children: [
                _buildNavItem('Home', true),
                const SizedBox(width: 24),
                _buildNavItem('Markets', false),
                const SizedBox(width: 24),
                _buildNavItem('Analysis', false),
                const SizedBox(width: 24),
                _buildNavItem('About', false),
                const SizedBox(width: 32),
                
                // CTA Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Get Started',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          
          // Mobile menu button
          if (MediaQuery.of(context).size.width <= 768)
            IconButton(
              onPressed: () {
                // Handle mobile menu
              },
              icon: const Icon(
                Icons.menu,
                color: AppTheme.textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, bool isActive) {
    return Text(
      title,
      style: AppTheme.bodyMedium.copyWith(
        color: isActive ? AppTheme.accentCyan : AppTheme.textSecondary,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
