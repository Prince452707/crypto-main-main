import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/tabs/overview_tab.dart';
import '../widgets/tabs/chart_tab.dart';
import '../widgets/tabs/ai_insights_tab.dart';
import '../widgets/tabs/ai_qa_tab.dart';
import '../widgets/tabs/details_tab.dart';
import '../widgets/tabs/similar_tab.dart';
import '../providers/crypto_detail_provider.dart';
import '../../bookmarks/providers/bookmark_provider.dart';

class UnifiedCryptoDetailScreen extends StatefulWidget {
  final String symbol;

  const UnifiedCryptoDetailScreen({
    super.key,
    required this.symbol,
  });

  @override
  State<UnifiedCryptoDetailScreen> createState() => _UnifiedCryptoDetailScreenState();
}

class _UnifiedCryptoDetailScreenState extends State<UnifiedCryptoDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CryptoDetailProvider _detailProvider;

  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
    Tab(icon: Icon(Icons.show_chart), text: 'Chart'),
    Tab(icon: Icon(Icons.psychology), text: 'AI Insights'),
    Tab(icon: Icon(Icons.chat), text: 'AI Q&A'),
    Tab(icon: Icon(Icons.info_outline), text: 'Details'),
    Tab(icon: Icon(Icons.compare_arrows), text: 'Similar'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _detailProvider = CryptoDetailProvider();
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detailProvider.loadCryptocurrencyData(widget.symbol);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _detailProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _detailProvider),
      ],
      child: Scaffold(
        body: Consumer<CryptoDetailProvider>(
          builder: (context, provider, child) {
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildSliverAppBar(context, provider),
                  _buildSliverTabBar(context),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  OverviewTab(symbol: widget.symbol, cryptoId: widget.symbol),
                  ChartTab(symbol: widget.symbol, cryptoId: widget.symbol),
                  AIInsightsTab(symbol: widget.symbol, cryptoId: widget.symbol),
                  Consumer<CryptoDetailProvider>(
                    builder: (context, provider, child) {
                      if (provider.cryptocurrency != null) {
                        return AIQATab(crypto: provider.cryptocurrency!);
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                  Consumer<CryptoDetailProvider>(
                    builder: (context, provider, child) {
                      if (provider.cryptocurrency != null) {
                        return DetailsTab(crypto: provider.cryptocurrency!);
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                  SimilarTab(symbol: widget.symbol),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, CryptoDetailProvider provider) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          provider.cryptocurrency?.symbol.toUpperCase() ?? widget.symbol.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: provider.cryptocurrency != null 
              ? _buildHeaderContent(context, provider.cryptocurrency!)
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
      actions: [
        // Bookmark button
        Consumer<BookmarkProvider>(
          builder: (context, bookmarkProvider, child) {
            final isBookmarked = bookmarkProvider.isBookmarked(widget.symbol);
            return IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? Colors.amber : Colors.white,
              ),
              onPressed: () {
                bookmarkProvider.toggleBookmark(
                  widget.symbol,
                  name: provider.cryptocurrency?.name,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isBookmarked 
                          ? 'Removed from bookmarks' 
                          : 'Added to bookmarks',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
            );
          },
        ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            _detailProvider.refreshData();
          },
          tooltip: 'Refresh data',
        ),
        // More actions
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'share':
                _shareSymbol(context);
                break;
              case 'alert':
                _showPriceAlert(context);
                break;
              case 'portfolio':
                _addToPortfolio(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'alert',
              child: ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Price Alert'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'portfolio',
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet),
                title: Text('Add to Portfolio'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderContent(BuildContext context, dynamic cryptocurrency) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (cryptocurrency.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                    cryptocurrency.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          cryptocurrency.symbol.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cryptocurrency.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      cryptocurrency.symbol.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (cryptocurrency.price != null) ...[
            Text(
              '\$${cryptocurrency.price!.toStringAsFixed(cryptocurrency.price! < 1 ? 6 : 2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (cryptocurrency.percentChange24h != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cryptocurrency.percentChange24h! >= 0 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cryptocurrency.percentChange24h! >= 0 
                        ? Colors.green 
                        : Colors.red,
                  ),
                ),
                child: Text(
                  '${cryptocurrency.percentChange24h! >= 0 ? '+' : ''}${cryptocurrency.percentChange24h!.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: cryptocurrency.percentChange24h! >= 0 
                        ? Colors.green 
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  SliverPersistentHeader _buildSliverTabBar(BuildContext context) {
    return SliverPersistentHeader(
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: _tabs,
          isScrollable: true,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      pinned: true,
    );
  }

  void _shareSymbol(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${widget.symbol.toUpperCase()} details...'),
      ),
    );
  }

  void _showPriceAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Price Alert for ${widget.symbol.toUpperCase()}'),
        content: const Text('Price alert feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addToPortfolio(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${widget.symbol.toUpperCase()} to Portfolio'),
        content: const Text('Portfolio feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
