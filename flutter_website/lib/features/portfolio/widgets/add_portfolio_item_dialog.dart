import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/portfolio_provider.dart';

class AddPortfolioItemDialog extends StatefulWidget {
  final Function(PortfolioItem) onAdd;

  const AddPortfolioItemDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddPortfolioItemDialog> createState() => _AddPortfolioItemDialogState();
}

class _AddPortfolioItemDialogState extends State<AddPortfolioItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _buyPriceController = TextEditingController();
  DateTime _purchaseDate = DateTime.now();

  final List<Map<String, String>> _cryptoOptions = [
    {'symbol': 'bitcoin', 'name': 'Bitcoin'},
    {'symbol': 'ethereum', 'name': 'Ethereum'},
    {'symbol': 'binancecoin', 'name': 'Binance Coin'},
    {'symbol': 'cardano', 'name': 'Cardano'},
    {'symbol': 'solana', 'name': 'Solana'},
    {'symbol': 'polkadot', 'name': 'Polkadot'},
    {'symbol': 'dogecoin', 'name': 'Dogecoin'},
    {'symbol': 'avalanche-2', 'name': 'Avalanche'},
    {'symbol': 'polygon', 'name': 'Polygon'},
    {'symbol': 'chainlink', 'name': 'Chainlink'},
  ];

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _buyPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Asset to Portfolio',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Asset dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Cryptocurrency',
                  border: OutlineInputBorder(),
                ),
                items: _cryptoOptions.map((crypto) {
                  return DropdownMenuItem(
                    value: crypto['symbol'],
                    child: Text('${crypto['name']} (${crypto['symbol']})'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _symbolController.text = value;
                    final crypto = _cryptoOptions.firstWhere(
                      (c) => c['symbol'] == value,
                    );
                    _nameController.text = crypto['name']!;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a cryptocurrency';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 1.5',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Buy price
              TextFormField(
                controller: _buyPriceController,
                decoration: const InputDecoration(
                  labelText: 'Buy Price (USD)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 45000',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a buy price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Purchase date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _purchaseDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _purchaseDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Purchase Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_purchaseDate.day}/${_purchaseDate.month}/${_purchaseDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _addItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Asset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addItem() {
    if (_formKey.currentState!.validate()) {
      final item = PortfolioItem(
        symbol: _symbolController.text,
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        buyPrice: double.parse(_buyPriceController.text),
        purchaseDate: _purchaseDate,
      );

      widget.onAdd(item);
      Navigator.of(context).pop();
    }
  }
}
