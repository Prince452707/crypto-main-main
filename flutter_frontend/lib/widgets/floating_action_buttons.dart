import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FloatingActionButtons extends StatefulWidget {
  const FloatingActionButtons({super.key});

  @override
  State<FloatingActionButtons> createState() => _FloatingActionButtonsState();
}

class _FloatingActionButtonsState extends State<FloatingActionButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Help button
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton(
                heroTag: "help",
                onPressed: () {
                  _showHelpDialog(context);
                },
                backgroundColor: AppTheme.successGreen,
                child: const Icon(
                  Icons.help_outline,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Feedback button
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton(
                heroTag: "feedback",
                onPressed: () {
                  _showFeedbackDialog(context);
                },
                backgroundColor: AppTheme.warningOrange,
                child: const Icon(
                  Icons.feedback_outlined,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Scroll to top button
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton(
                heroTag: "scroll_top",
                onPressed: () {
                  _scrollToTop();
                },
                backgroundColor: AppTheme.accentCyan,
                child: const Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Main FAB
          FloatingActionButton(
            heroTag: "main",
            onPressed: _toggleExpanded,
            backgroundColor: AppTheme.primaryBlue,
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToTop() {
    // This would need to access the scroll controller from parent
    // For now, just close the expanded menu
    _toggleExpanded();
  }

  void _showHelpDialog(BuildContext context) {
    _toggleExpanded();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Help & Support',
          style: AppTheme.headingMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to use Crypto Insight:',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildHelpItem('1. Enter a cryptocurrency symbol (e.g., BTC, ETH)'),
            _buildHelpItem('2. Select the analysis timeframe'),
            _buildHelpItem('3. Click "Analyze Now" to get comprehensive insights'),
            _buildHelpItem('4. Explore different analysis tabs for detailed information'),
            const SizedBox(height: 16),
            Text(
              'Need more help?',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact our support team at support@cryptoinsight.com',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.accentCyan,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: TextStyle(color: AppTheme.accentCyan),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    _toggleExpanded();
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Send Feedback',
          style: AppTheme.headingMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We\'d love to hear your thoughts!',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell us what you think...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle feedback submission
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Thank you for your feedback!'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String text) {
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
