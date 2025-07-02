import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../dashboard/providers/crypto_provider.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  String _sortBy = 'rank';
  bool _ascending = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CryptoProvider>().loadMarketData(perPage: 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(child: _buildMarketTable()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cryptocurrency Markets',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track prices, market caps, and trading volumes',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => context.read<CryptoProvider>().refresh(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search cryptocurrencies...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                if (value.isNotEmpty) {
                  context.read<CryptoProvider>().searchCryptocurrencies(value);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          // Sort by
          DropdownButton<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'rank', child: Text('Rank')),
              DropdownMenuItem(value: 'price', child: Text('Price')),
              DropdownMenuItem(value: 'change24h', child: Text('24h Change')),
              DropdownMenuItem(value: 'marketCap', child: Text('Market Cap')),
              DropdownMenuItem(value: 'volume24h', child: Text('24h Volume')),
            ],
            onChanged: (value) => setState(() => _sortBy = value!),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _ascending = !_ascending),
            icon: Icon(
              _ascending ? Icons.arrow_upward : Icons.arrow_downward,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTable() {
    return Consumer<CryptoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
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
                  'Failed to load market data',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadMarketData(perPage: 100),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        var cryptos = _searchQuery.isNotEmpty 
            ? provider.searchResults 
            : provider.marketData;

        // Apply sorting
        cryptos = List.from(cryptos);
        cryptos.sort((a, b) {
          dynamic valueA, valueB;
          switch (_sortBy) {
            case 'rank':
              valueA = a.rank ?? 999999;
              valueB = b.rank ?? 999999;
              break;
            case 'price':
              valueA = a.price ?? 0;
              valueB = b.price ?? 0;
              break;
            case 'change24h':
              valueA = a.percentChange24h ?? 0;
              valueB = b.percentChange24h ?? 0;
              break;
            case 'marketCap':
              valueA = a.marketCap ?? 0;
              valueB = b.marketCap ?? 0;
              break;
            case 'volume24h':
              valueA = a.volume24h ?? 0;
              valueB = b.volume24h ?? 0;
              break;
            default:
              valueA = a.rank ?? 999999;
              valueB = b.rank ?? 999999;
          }
          
          final comparison = _ascending 
              ? valueA.compareTo(valueB) 
              : valueB.compareTo(valueA);
          return comparison;
        });

        return SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 60, child: Text('#', style: _headerStyle(context))),
                      Expanded(flex: 3, child: Text('Name', style: _headerStyle(context))),
                      Expanded(flex: 2, child: Text('Price', style: _headerStyle(context))),
                      Expanded(flex: 2, child: Text('24h Change', style: _headerStyle(context))),
                      Expanded(flex: 2, child: Text('Market Cap', style: _headerStyle(context))),
                      Expanded(flex: 2, child: Text('Volume (24h)', style: _headerStyle(context))),
                    ],
                  ),
                ),
                // Table rows
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cryptos.length,
                  itemBuilder: (context, index) {
                    final crypto = cryptos[index];
                    return _buildTableRow(context, crypto, index);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableRow(BuildContext context, crypto, int index) {
    return InkWell(
      onTap: () => context.go('/crypto/${crypto.symbol.toLowerCase()}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                '${crypto.rank ?? (index + 1)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      crypto.symbol.toUpperCase().substring(0, 1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crypto.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          crypto.symbol.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                crypto.formattedPrice,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (crypto.isPriceUp ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  crypto.formattedPercentChange24h,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: crypto.isPriceUp ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                crypto.formattedMarketCap,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                crypto.formattedVolume24h,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
    );
  }
}
