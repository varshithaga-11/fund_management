import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'financial_statements_api.dart';

class TradingAccountForm extends StatefulWidget {
  final int periodId;
  final VoidCallback? onSave;
  final bool canUpdate;

  const TradingAccountForm({
    super.key,
    required this.periodId,
    this.onSave,
    this.canUpdate = true,
  });

  @override
  State<TradingAccountForm> createState() => _TradingAccountFormState();
}

class _TradingAccountFormState extends State<TradingAccountForm> {
  final _formKey = GlobalKey<FormState>();
  
  final _openingStockController = TextEditingController();
  final _purchasesController = TextEditingController();
  final _tradeChargesController = TextEditingController();
  final _salesController = TextEditingController();
  final _closingStockController = TextEditingController();
  
  double? _grossProfit;
  bool _loading = false;
  int? _existingId;

  bool get _isReadOnly => !widget.canUpdate && _existingId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    _openingStockController.addListener(_calculateGrossProfit);
    _purchasesController.addListener(_calculateGrossProfit);
    _tradeChargesController.addListener(_calculateGrossProfit);
    _salesController.addListener(_calculateGrossProfit);
    _closingStockController.addListener(_calculateGrossProfit);
  }

  @override
  void dispose() {
    _openingStockController.dispose();
    _purchasesController.dispose();
    _tradeChargesController.dispose();
    _salesController.dispose();
    _closingStockController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await getTradingAccount(widget.periodId);
      if (data != null) {
        setState(() {
          _existingId = data.id;
          _openingStockController.text = data.openingStock.toString();
          _purchasesController.text = data.purchases.toString();
          _tradeChargesController.text = data.tradeCharges.toString();
          _salesController.text = data.sales.toString();
          _closingStockController.text = data.closingStock.toString();
          _grossProfit = data.grossProfit;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trading account: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _calculateGrossProfit() {
    final opening = double.tryParse(_openingStockController.text) ?? 0;
    final purchases = double.tryParse(_purchasesController.text) ?? 0;
    final charges = double.tryParse(_tradeChargesController.text) ?? 0;
    final sales = double.tryParse(_salesController.text) ?? 0;
    final closing = double.tryParse(_closingStockController.text) ?? 0;

    setState(() {
      _grossProfit = sales + closing - (opening + purchases + charges);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    
    final data = {
      'opening_stock': double.tryParse(_openingStockController.text) ?? 0,
      'purchases': double.tryParse(_purchasesController.text) ?? 0,
      'trade_charges': double.tryParse(_tradeChargesController.text) ?? 0,
      'sales': double.tryParse(_salesController.text) ?? 0,
      'closing_stock': double.tryParse(_closingStockController.text) ?? 0,
    };

    try {
      if (_existingId != null) {
        await updateTradingAccount(_existingId!, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trading Account updated successfully!'), backgroundColor: Colors.green),
        );
      } else {
        await createTradingAccount(widget.periodId, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trading Account created successfully!'), backgroundColor: Colors.green),
        );
      }
      await _loadData();
      widget.onSave?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save trading account: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Trading Account',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildNumberInput('Opening Stock *', _openingStockController),
            const SizedBox(height: 16),
            _buildNumberInput('Purchases *', _purchasesController),
            const SizedBox(height: 16),
            _buildNumberInput('Trade Charges *', _tradeChargesController),
            const SizedBox(height: 16),
            _buildNumberInput('Sales *', _salesController),
            const SizedBox(height: 16),
            _buildNumberInput('Closing Stock *', _closingStockController),
            const SizedBox(height: 24),
            
            // Gross Profit Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gross Profit (Calculated)', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    _grossProfit != null ? '₹${_grossProfit!.toStringAsFixed(2)}' : '-',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (!_isReadOnly)
              ElevatedButton(
                onPressed: _loading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _loading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : Text(_existingId != null ? 'Update' : 'Save'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: '₹ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        return null;
      },
      enabled: !_loading && !_isReadOnly,
    );
  }
}
