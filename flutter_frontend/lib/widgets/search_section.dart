import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/analysis_screen.dart';

class SearchSection extends StatefulWidget {
  const SearchSection({super.key});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedDays = 30;
  
  final List<String> _popularCryptos = [
    'BTC', 'ETH', 'ADA', 'DOT', 'SOL', 'AVAX', 'MATIC', 'LINK'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          // Section title
          Text(
            'Start Your Analysis',
            style: AppTheme.headingLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enter a cryptocurrency symbol to get comprehensive AI-powered analysis',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // Search container
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassMorphism,
            child: Column(
              children: [
                // Search input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: AppTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Enter crypto symbol (e.g., BTC, ETH)',
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppTheme.accentCyan,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.textTertiary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.accentCyan,
                              width: 2,
                            ),
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (value) => _performSearch(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Days selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.textTertiary.withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedDays,
                          style: AppTheme.bodyMedium,
                          dropdownColor: AppTheme.cardBackground,
                          items: [7, 30, 90, 180, 365].map((days) {
                            return DropdownMenuItem<int>(
                              value: days,
                              child: Text('${days}d'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedDays = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Search button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.analytics, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Analyze Now',
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Popular cryptos
                Text(
                  'Popular Cryptocurrencies',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _popularCryptos.map((crypto) {
                    return GestureDetector(
                      onTap: () {
                        _searchController.text = crypto;
                        _performSearch();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.accentCyan.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          crypto,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.accentCyan,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    final symbol = _searchController.text.trim().toUpperCase();
    if (symbol.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisScreen(
            symbol: symbol,
            days: _selectedDays,
          ),
        ),
      );
    }
  }
}
