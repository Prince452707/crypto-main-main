import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../../crypto_detail/widgets/crypto_list_item.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  String _sortBy = 'rank';

  @override
  void initState() {
    super.initState();
    // Load bookmarks when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarkProvider>().refreshBookmarkData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarked Cryptocurrencies'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'rank', child: Text('Sort by Rank')),
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'price', child: Text('Sort by Price')),
              const PopupMenuItem(value: 'change24h', child: Text('Sort by 24h Change')),
              const PopupMenuItem(value: 'marketCap', child: Text('Sort by Market Cap')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BookmarkProvider>().refreshBookmarkData();
            },
          ),
        ],
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading bookmarked cryptocurrencies...'),
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
                    'Error loading bookmarks',
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
                    onPressed: () => provider.refreshBookmarkData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.bookmarkedCryptos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bookmarks yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start bookmarking your favorite cryptocurrencies to see them here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/markets'),
                    icon: const Icon(Icons.explore),
                    label: const Text('Explore Markets'),
                  ),
                ],
              ),
            );
          }

          final sortedCryptos = provider.getBookmarksSorted(sortBy: _sortBy);

          return RefreshIndicator(
            onRefresh: provider.refreshBookmarkData,
            child: Column(
              children: [
                // Bookmark count header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bookmark,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${provider.bookmarkCount} Bookmarked Cryptocurrencies',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Cryptocurrencies list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedCryptos.length,
                    itemBuilder: (context, index) {
                      final crypto = sortedCryptos[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CryptoListItem(
                          crypto: crypto,
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/crypto/${crypto.symbol.toLowerCase()}',
                            );
                          },
                          trailing: IconButton(
                            icon: Icon(
                              Icons.bookmark_remove,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () {
                              _showRemoveBookmarkDialog(context, crypto, provider);
                            },
                            tooltip: 'Remove bookmark',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBookmarkActionsDialog(context),
        child: const Icon(Icons.bookmark_add),
        tooltip: 'Bookmark Actions',
      ),
    );
  }

  void _showRemoveBookmarkDialog(BuildContext context, dynamic crypto, BookmarkProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Bookmark'),
        content: Text(
          'Are you sure you want to remove ${crypto.name} (${crypto.symbol.toUpperCase()}) from your bookmarks?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.removeBookmark(crypto.symbol);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showBookmarkActionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bookmark Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear All Bookmarks'),
              onTap: () {
                Navigator.of(context).pop();
                _showClearBookmarksDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Bookmarks'),
              onTap: () {
                Navigator.of(context).pop();
                _exportBookmarks(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Import Bookmarks'),
              onTap: () {
                Navigator.of(context).pop();
                _showImportDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearBookmarksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Bookmarks'),
        content: const Text(
          'Are you sure you want to remove all bookmarks? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<BookmarkProvider>().clearBookmarks();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _exportBookmarks(BuildContext context) {
    final provider = context.read<BookmarkProvider>();
    final bookmarks = provider.exportBookmarks();
    
    // In a real app, you'd implement proper export functionality
    // For now, show the bookmarks in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Bookmarks'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your bookmarked cryptocurrencies:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bookmarks.join(', '),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Bookmarks'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter cryptocurrency symbols separated by commas:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'btc, eth, bnb, ada, sol',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final symbols = controller.text
                  .split(',')
                  .map((s) => s.trim().toLowerCase())
                  .where((s) => s.isNotEmpty)
                  .toList();
              
              if (symbols.isNotEmpty) {
                context.read<BookmarkProvider>().importBookmarks(symbols);
              }
              
              Navigator.of(context).pop();
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
