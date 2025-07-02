import 'package:flutter/material.dart';

class AnalysisSearch extends StatefulWidget {
  final Function(String) onSymbolSelected;

  const AnalysisSearch({
    super.key,
    required this.onSymbolSelected,
  });

  @override
  State<AnalysisSearch> createState() => _AnalysisSearchState();
}

class _AnalysisSearchState extends State<AnalysisSearch> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Common crypto symbols for suggestions
  final List<String> _cryptoSymbols = [
    'bitcoin',
    'ethereum',
    'binancecoin',
    'cardano',
    'solana',
    'polkadot',
    'dogecoin',
    'avalanche-2',
    'polygon',
    'chainlink',
    'uniswap',
    'litecoin',
    'algorand',
    'stellar',
    'vechain',
  ];

  List<String> _filteredSymbols = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _filteredSymbols = _cryptoSymbols;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterSymbols(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSymbols = _cryptoSymbols;
      } else {
        _filteredSymbols = _cryptoSymbols
            .where((symbol) => symbol.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _showSuggestions = query.isNotEmpty && _filteredSymbols.isNotEmpty;
    });
  }

  void _selectSymbol(String symbol) {
    _controller.text = symbol;
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
    widget.onSymbolSelected(symbol);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search cryptocurrency (e.g., bitcoin, ethereum)',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _showSuggestions = false;
                        _filteredSymbols = _cryptoSymbols;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
          onChanged: _filterSymbols,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _selectSymbol(value.toLowerCase());
            }
          },
          onTap: () {
            setState(() {
              _showSuggestions = _controller.text.isNotEmpty && _filteredSymbols.isNotEmpty;
            });
          },
        ),
        
        // Suggestions dropdown
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: Material(
              color: Colors.transparent,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredSymbols.length,
                itemBuilder: (context, index) {
                  final symbol = _filteredSymbols[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.currency_bitcoin, size: 20),
                    title: Text(
                      symbol,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    subtitle: Text(
                      _getSymbolDisplayName(symbol),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () => _selectSymbol(symbol),
                    hoverColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  String _getSymbolDisplayName(String symbol) {
    final displayNames = {
      'bitcoin': 'Bitcoin (BTC)',
      'ethereum': 'Ethereum (ETH)',
      'binancecoin': 'Binance Coin (BNB)',
      'cardano': 'Cardano (ADA)',
      'solana': 'Solana (SOL)',
      'polkadot': 'Polkadot (DOT)',
      'dogecoin': 'Dogecoin (DOGE)',
      'avalanche-2': 'Avalanche (AVAX)',
      'polygon': 'Polygon (MATIC)',
      'chainlink': 'Chainlink (LINK)',
      'uniswap': 'Uniswap (UNI)',
      'litecoin': 'Litecoin (LTC)',
      'algorand': 'Algorand (ALGO)',
      'stellar': 'Stellar (XLM)',
      'vechain': 'VeChain (VET)',
    };
    
    return displayNames[symbol] ?? symbol.toUpperCase();
  }
}
