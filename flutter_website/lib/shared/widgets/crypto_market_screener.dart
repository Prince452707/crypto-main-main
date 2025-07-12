import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/dashboard/providers/crypto_provider.dart';
import '../models/screener_models.dart';

class CryptoMarketScreener extends StatefulWidget {
  const CryptoMarketScreener({super.key});

  @override
  State<CryptoMarketScreener> createState() => _CryptoMarketScreenerState();
}

class _CryptoMarketScreenerState extends State<CryptoMarketScreener> {
  final List<ScreenerCriteria> _criteria = [];
  List<ScreenerResult> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addDefaultCriteria();
  }

  void _addDefaultCriteria() {
    _criteria.addAll([
      ScreenerCriteria(
        field: ScreenerField.availableFields.firstWhere((f) => f.key == 'marketCap'),
        operator: ScreenerOperator.greaterThan,
        value: 1000000000, // $1B market cap
      ),
      ScreenerCriteria(
        field: ScreenerField.availableFields.firstWhere((f) => f.key == 'volume24h'),
        operator: ScreenerOperator.greaterThan,
        value: 50000000, // $50M volume
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1421),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1421),
        title: const Text(
          'Market Screener',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _runScreener,
            icon: const Icon(Icons.search, color: Color(0xFF00D4AA)),
          ),
          IconButton(
            onPressed: _clearCriteria,
            icon: const Icon(Icons.clear, color: Color(0xFFFF6B6B)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCriteriaSection(),
          _buildResultsSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCriterion,
        backgroundColor: const Color(0xFF00D4AA),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildCriteriaSection() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Color(0xFF00D4AA)),
                const SizedBox(width: 8),
                const Text(
                  'Screening Criteria',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_criteria.length} criteria',
                  style: const TextStyle(color: Color(0xFF8A92B2)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: _criteria.isEmpty ? 50 : 200,
            child: _criteria.isEmpty
                ? const Center(
                    child: Text(
                      'No criteria added. Tap + to add screening criteria.',
                      style: TextStyle(color: Color(0xFF8A92B2)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _criteria.length,
                    itemBuilder: (context, index) {
                      return _buildCriteriaCard(_criteria[index], index);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _runScreener,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_isLoading ? 'Screening...' : 'Run Screener'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaCard(ScreenerCriteria criteria, int index) {
    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    criteria.displayName,
                    style: const TextStyle(
                      color: Color(0xFF00D4AA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    criteria.description,
                    style: const TextStyle(color: Color(0xFF8A92B2), fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeCriterion(index),
              icon: const Icon(Icons.close, color: Color(0xFFFF6B6B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Expanded(
      child: Container(
        color: const Color(0xFF0D1421),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.analytics, color: Color(0xFF00D4AA)),
                  const SizedBox(width: 8),
                  const Text(
                    'Screening Results',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_results.length} matches',
                    style: const TextStyle(color: Color(0xFF8A92B2)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Color(0xFF8A92B2),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No results found',
                            style: TextStyle(
                              color: Color(0xFF8A92B2),
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Run the screener to find matching cryptocurrencies',
                            style: TextStyle(
                              color: Color(0xFF8A92B2),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        return _buildResultCard(_results[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ScreenerResult result) {
    final price = result.data['price'] as double? ?? 0;
    final change24h = result.data['change24h'] as double? ?? 0;
    final marketCap = result.data['marketCap'] as double? ?? 0;
    final volume24h = result.data['volume24h'] as double? ?? 0;

    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF00D4AA),
                  radius: 20,
                  child: Text(
                    result.symbol.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        result.symbol,
                        style: const TextStyle(
                          color: Color(0xFF8A92B2),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${_formatNumber(price)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${change24h >= 0 ? '+' : ''}${change24h.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: change24h >= 0 ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem('Market Cap', '\$${_formatNumber(marketCap)}'),
                ),
                Expanded(
                  child: _buildMetricItem('24h Volume', '\$${_formatNumber(volume24h)}'),
                ),
                Expanded(
                  child: _buildMetricItem('Score', '${result.score.toStringAsFixed(1)}/10'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8A92B2),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _addCriterion() {
    showDialog(
      context: context,
      builder: (context) => _AddCriterionDialog(
        onAdd: (criterion) {
          setState(() {
            _criteria.add(criterion);
          });
        },
      ),
    );
  }

  void _removeCriterion(int index) {
    setState(() {
      _criteria.removeAt(index);
    });
  }

  void _clearCriteria() {
    setState(() {
      _criteria.clear();
      _results.clear();
    });
  }

  Future<void> _runScreener() async {
    setState(() {
      _isLoading = true;
      _results.clear();
    });

    try {
      final cryptoProvider = context.read<CryptoProvider>();
      await cryptoProvider.loadMarketData(perPage: 100);
      
      final matchingResults = <ScreenerResult>[];
      
      for (final crypto in cryptoProvider.marketData) {
        bool meetsAllCriteria = true;
        
        for (final criterion in _criteria) {
          if (!_evaluateCriterion(crypto, criterion)) {
            meetsAllCriteria = false;
            break;
          }
        }
        
        if (meetsAllCriteria) {
          matchingResults.add(ScreenerResult(
            symbol: crypto.symbol,
            name: crypto.name,
            price: crypto.price ?? 0,
            change24h: crypto.percentChange24h ?? 0,
            marketCap: crypto.marketCap ?? 0,
            volume24h: crypto.volume24h ?? 0,
            score: _calculateScore(crypto),
            data: {
              'price': crypto.price ?? 0,
              'change24h': crypto.percentChange24h ?? 0,
              'marketCap': crypto.marketCap ?? 0,
              'volume24h': crypto.volume24h ?? 0,
              'rank': crypto.rank ?? 999,
            },
          ));
        }
      }
      
      // Sort by score descending
      matchingResults.sort((a, b) => b.score.compareTo(a.score));
      
      setState(() {
        _results = matchingResults;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error running screener: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _evaluateCriterion(dynamic crypto, ScreenerCriteria criterion) {
    dynamic value;
    
    switch (criterion.field.key) {
      case 'price':
        value = crypto.price ?? 0;
        break;
      case 'marketCap':
        value = crypto.marketCap ?? 0;
        break;
      case 'volume24h':
        value = crypto.volume24h ?? 0;
        break;
      case 'percentChange24h':
        value = crypto.percentChange24h ?? 0;
        break;
      case 'percentChange7d':
        value = crypto.percentChange7d ?? 0;
        break;
      case 'rank':
        value = crypto.rank ?? 999;
        break;
      default:
        return true;
    }
    
    switch (criterion.operator) {
      case ScreenerOperator.greaterThan:
        return value > criterion.value;
      case ScreenerOperator.lessThan:
        return value < criterion.value;
      case ScreenerOperator.equals:
        return value == criterion.value;
      case ScreenerOperator.greaterThanOrEqual:
        return value >= criterion.value;
      case ScreenerOperator.lessThanOrEqual:
        return value <= criterion.value;
      case ScreenerOperator.notEquals:
        return value != criterion.value;
      case ScreenerOperator.between:
        return value >= criterion.value && value <= (criterion.secondValue ?? criterion.value);
    }
  }

  double _calculateScore(dynamic crypto) {
    double score = 5.0; // Base score
    
    // Add points for market cap
    final marketCap = crypto.marketCap ?? 0;
    if (marketCap > 10e9) score += 2;
    else if (marketCap > 1e9) score += 1;
    
    // Add points for volume
    final volume = crypto.volume24h ?? 0;
    if (volume > 100e6) score += 1;
    
    // Add points for rank
    final rank = crypto.rank ?? 999;
    if (rank <= 10) score += 2;
    else if (rank <= 50) score += 1;
    
    // Add/subtract points for performance
    final change24h = crypto.percentChange24h ?? 0;
    if (change24h > 5) score += 1;
    else if (change24h < -10) score -= 1;
    
    return score.clamp(0, 10);
  }

  String _formatNumber(double number) {
    if (number >= 1e12) {
      return '${(number / 1e12).toStringAsFixed(2)}T';
    } else if (number >= 1e9) {
      return '${(number / 1e9).toStringAsFixed(2)}B';
    } else if (number >= 1e6) {
      return '${(number / 1e6).toStringAsFixed(2)}M';
    } else if (number >= 1e3) {
      return '${(number / 1e3).toStringAsFixed(2)}K';
    } else {
      return number.toStringAsFixed(2);
    }
  }
}

class _AddCriterionDialog extends StatefulWidget {
  final Function(ScreenerCriteria) onAdd;

  const _AddCriterionDialog({required this.onAdd});

  @override
  State<_AddCriterionDialog> createState() => _AddCriterionDialogState();
}

class _AddCriterionDialogState extends State<_AddCriterionDialog> {
  ScreenerField? _selectedField;
  ScreenerOperator _selectedOperator = ScreenerOperator.greaterThan;
  final TextEditingController _valueController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text(
        'Add Screening Criterion',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ScreenerField>(
            value: _selectedField,
            decoration: const InputDecoration(
              labelText: 'Field',
              labelStyle: TextStyle(color: Color(0xFF8A92B2)),
              border: OutlineInputBorder(),
            ),
            dropdownColor: const Color(0xFF1A1A2E),
            style: const TextStyle(color: Colors.white),
            items: ScreenerField.availableFields.map((field) {
              return DropdownMenuItem(
                value: field,
                child: Text(field.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedField = value;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ScreenerOperator>(
            value: _selectedOperator,
            decoration: const InputDecoration(
              labelText: 'Operator',
              labelStyle: TextStyle(color: Color(0xFF8A92B2)),
              border: OutlineInputBorder(),
            ),
            dropdownColor: const Color(0xFF1A1A2E),
            style: const TextStyle(color: Colors.white),
            items: ScreenerOperator.values.map((operator) {
              return DropdownMenuItem(
                value: operator,
                child: Text(operator.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedOperator = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            decoration: const InputDecoration(
              labelText: 'Value',
              labelStyle: TextStyle(color: Color(0xFF8A92B2)),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF8A92B2))),
        ),
        ElevatedButton(
          onPressed: _selectedField != null && _valueController.text.isNotEmpty
              ? () {
                  final value = double.tryParse(_valueController.text);
                  if (value != null) {
                    widget.onAdd(ScreenerCriteria(
                      field: _selectedField!,
                      operator: _selectedOperator,
                      value: value,
                    ));
                    Navigator.of(context).pop();
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4AA),
            foregroundColor: Colors.black,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
