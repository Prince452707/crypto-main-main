import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkBackground,
            Color(0xFF050A1E),
          ],
        ),
      ),
      child: Column(
        children: [
          // Footer content
          Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                // Main footer content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand section
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 16),
                          Text(
                            'Empowering crypto investors with AI-driven insights and comprehensive market analysis.',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Social media links
                          Row(
                            children: [
                              _buildSocialIcon(Icons.facebook),
                              const SizedBox(width: 12),
                              _buildSocialIcon(Icons.alternate_email), // Twitter
                              const SizedBox(width: 12),
                              _buildSocialIcon(Icons.link), // LinkedIn
                              const SizedBox(width: 12),
                              _buildSocialIcon(Icons.code), // GitHub
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    if (MediaQuery.of(context).size.width > 768) ...[
                      const SizedBox(width: 40),
                      
                      // Quick links
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Links',
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFooterLink('Home'),
                            _buildFooterLink('Markets'),
                            _buildFooterLink('Analysis'),
                            _buildFooterLink('About'),
                            _buildFooterLink('Contact'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 40),
                      
                      // Features
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Features',
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFooterLink('AI Analysis'),
                            _buildFooterLink('Technical Charts'),
                            _buildFooterLink('News Sentiment'),
                            _buildFooterLink('Risk Assessment'),
                            _buildFooterLink('Real-time Data'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 40),
                      
                      // Support
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Support',
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFooterLink('Help Center'),
                            _buildFooterLink('API Documentation'),
                            _buildFooterLink('Privacy Policy'),
                            _buildFooterLink('Terms of Service'),
                            _buildFooterLink('Contact Us'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Newsletter signup
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassMorphism,
                  child: Column(
                    children: [
                      Text(
                        'Stay Updated',
                        style: AppTheme.headingSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get the latest crypto insights and market updates',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Newsletter form
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Enter your email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              // Handle newsletter signup
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentCyan,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            child: const Text('Subscribe'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Copyright
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.textTertiary.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '© 2025 Crypto Insight. All rights reserved.',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                      if (MediaQuery.of(context).size.width > 768)
                        Row(
                          children: [
                            Text(
                              'Made with ❤️ for crypto enthusiasts',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: AppTheme.textSecondary,
        size: 20,
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
