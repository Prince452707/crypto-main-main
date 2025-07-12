import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/similar_cryptos_provider.dart';

class SimilarCryptosScreen extends StatefulWidget {
  final String symbol;

  const SimilarCryptosScreen({
    super.key,
    required this.symbol,
  });

  @override
  State<SimilarCryptosScreen> createState() => _SimilarCryptosScreenState();
}

class _SimilarCryptosScreenState extends State<SimilarCryptosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SimilarCryptosProvider>().findSimilarCryptocurrencies(widget.symbol);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Similar to ${widget.symbol.toUpperCase()}'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SimilarCryptosProvider>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<SimilarCryptosProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Finding similar cryptocurrencies...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error finding similar cryptocurrencies',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.similarCryptos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No similar cryptocurrencies found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching for a different cryptocurrency',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with similarity criteria
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Similarity Analysis',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Found ${provider.similarCryptos.length} cryptocurrencies similar to ${widget.symbol.toUpperCase()}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (provider.similarityCriteria.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Similarity Criteria:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...provider.similarityCriteria.map((criteria) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    criteria,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),

                // Similar cryptocurrencies list
                Text(
                  'Similar Cryptocurrencies',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                ...provider.similarCryptos.map((similarCrypto) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSimilarCryptoCard(context, similarCrypto),
                )),

                // AI Analysis section
                if (provider.comparisonAnalysis != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.psychology,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI Comparison Analysis',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.comparisonAnalysis!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Disclaimer
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Disclaimer: Similarity analysis is for informational purposes only and should not be considered as investment advice. Always do your own research.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSimilarCryptoCard(BuildContext context, SimilarCryptocurrency similarCrypto) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Cryptocurrency info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        similarCrypto.symbol.toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (similarCrypto.name != null)
                        Text(
                          similarCrypto.name!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),

                // Similarity score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: similarCrypto.similarityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: similarCrypto.similarityColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        similarCrypto.formattedSimilarityScore,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: similarCrypto.similarityColor,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        similarCrypto.similarityLevel,
                        style: TextStyle(
                          fontSize: 10,
                          color: similarCrypto.similarityColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Match reasons
            if (similarCrypto.matchReasons.isNotEmpty) ...[
              Text(
                'Why it\'s similar:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: similarCrypto.matchReasons.map((reason) => Chip(
                  label: Text(
                    reason,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/crypto/${similarCrypto.symbol.toLowerCase()}');
                    },
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Add to comparison or favorites
                      _showActionDialog(context, similarCrypto);
                    },
                    child: const Text('Compare'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showActionDialog(BuildContext context, SimilarCryptocurrency similarCrypto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${similarCrypto.symbol.toUpperCase()} Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_add),
              title: const Text('Add to Bookmarks'),
              onTap: () {
                Navigator.of(context).pop();
                // In a real app, add to bookmarks
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${similarCrypto.symbol.toUpperCase()} added to bookmarks')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: Text('Compare with ${widget.symbol.toUpperCase()}'),
              onTap: () {
                Navigator.of(context).pop();
                // In a real app, open comparison view
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comparison feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Analysis'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/crypto/${similarCrypto.symbol.toLowerCase()}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
