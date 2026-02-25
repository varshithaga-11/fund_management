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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trading Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 32),
          
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isDesktop = screenWidth > 750;
              return Column(
                children: [
                  _buildDesktopRow([
                    _buildNumberInput('Opening Stock *', _openingStockController, isDark),
                    _buildNumberInput('Purchases *', _purchasesController, isDark),
                  ], isDesktop, isDark),
                  const SizedBox(height: 20),
                  
                  _buildDesktopRow([
                    _buildNumberInput('Trade Charges *', _tradeChargesController, isDark),
                    _buildNumberInput('Sales *', _salesController, isDark),
                  ], isDesktop, isDark),
                  const SizedBox(height: 20),
                  
                  _buildDesktopRow([
                    _buildNumberInput('Closing Stock *', _closingStockController, isDark),
                    _buildGrossProfitDisplay(isDark),
                  ], isDesktop, isDark),
                ],
              );
            },
          ),
          
          if (!_isReadOnly) ...[
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _loading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : Text(
                      _existingId != null ? 'Update Trading Account' : 'Save Trading Account',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopRow(List<Widget> children, bool isDesktop, bool isDark) {
    if (!isDesktop) {
      return Column(
        children: [
          children[0],
          const SizedBox(height: 20),
          children[1],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 32),
        Expanded(child: children[1]),
      ],
    );
  }

  Widget _buildNumberInput(String label, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            hintText: '0.00',
            filled: true,
            fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            return null;
          },
          enabled: !_loading && !_isReadOnly,
        ),
      ],
    );
  }

  Widget _buildGrossProfitDisplay(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gross Profit (Calculated)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827).withOpacity(0.5) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
          ),
          child: Text(
            _grossProfit != null ? '₹ ${_grossProfit!.toStringAsFixed(2)}' : '-',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}


