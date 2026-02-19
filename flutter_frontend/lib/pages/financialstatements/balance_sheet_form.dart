import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'financial_statements_api.dart';

class BalanceSheetForm extends StatefulWidget {
  final int periodId;
  final VoidCallback? onSave;
  final bool canUpdate;

  const BalanceSheetForm({
    super.key,
    required this.periodId,
    this.onSave,
    this.canUpdate = true,
  });

  @override
  State<BalanceSheetForm> createState() => _BalanceSheetFormState();
}

class _BalanceSheetFormState extends State<BalanceSheetForm> {
  final _formKey = GlobalKey<FormState>();

  // Liabilities
  final _shareCapitalController = TextEditingController();
  final _depositsController = TextEditingController();
  final _borrowingsController = TextEditingController();
  final _reservesController = TextEditingController();
  final _undistributedProfitController = TextEditingController();
  final _provisionsController = TextEditingController();
  final _otherLiabilitiesController = TextEditingController();

  // Assets
  final _cashInHandController = TextEditingController();
  final _cashAtBankController = TextEditingController();
  final _investmentsController = TextEditingController();
  final _loansAdvancesController = TextEditingController();
  final _fixedAssetsController = TextEditingController();
  final _otherAssetsController = TextEditingController();
  final _stockInTradeController = TextEditingController();

  // Calculated
  double _workingFund = 0;
  double _ownFunds = 0;
  double _totalLiabilities = 0;
  double _totalAssets = 0;

  bool _loading = false;
  int? _existingId;
  
  bool get _isReadOnly => !widget.canUpdate && _existingId != null;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Add listeners
    final liabilities = [
      _shareCapitalController, _depositsController, _borrowingsController,
      _reservesController, _undistributedProfitController, _provisionsController,
      _otherLiabilitiesController
    ];
    for (var controller in liabilities) {
      controller.addListener(_calculateValues);
    }

    final assets = [
      _cashInHandController, _cashAtBankController, _investmentsController,
      _loansAdvancesController, _fixedAssetsController, _otherAssetsController,
      _stockInTradeController
    ];
    for (var controller in assets) {
      controller.addListener(_calculateValues);
    }
  }

  @override
  void dispose() {
    _shareCapitalController.dispose();
    _depositsController.dispose();
    _borrowingsController.dispose();
    _reservesController.dispose();
    _undistributedProfitController.dispose();
    _provisionsController.dispose();
    _otherLiabilitiesController.dispose();
    
    _cashInHandController.dispose();
    _cashAtBankController.dispose();
    _investmentsController.dispose();
    _loansAdvancesController.dispose();
    _fixedAssetsController.dispose();
    _otherAssetsController.dispose();
    _stockInTradeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await getBalanceSheet(widget.periodId);
      if (data != null) {
        setState(() {
          _existingId = data.id;
          
          _shareCapitalController.text = data.shareCapital.toString();
          _depositsController.text = data.deposits.toString();
          _borrowingsController.text = data.borrowings.toString();
          _reservesController.text = data.reservesStatutoryFree.toString();
          _undistributedProfitController.text = data.undistributedProfit.toString();
          _provisionsController.text = data.provisions.toString();
          _otherLiabilitiesController.text = data.otherLiabilities.toString();
          
          _cashInHandController.text = data.cashInHand.toString();
          _cashAtBankController.text = data.cashAtBank.toString();
          _investmentsController.text = data.investments.toString();
          _loansAdvancesController.text = data.loansAdvances.toString();
          _fixedAssetsController.text = data.fixedAssets.toString();
          _otherAssetsController.text = data.otherAssets.toString();
          _stockInTradeController.text = data.stockInTrade.toString();
        });
        _calculateValues();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading balance sheet: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _calculateValues() {
    final shareCapital = double.tryParse(_shareCapitalController.text) ?? 0;
    final deposits = double.tryParse(_depositsController.text) ?? 0;
    final borrowings = double.tryParse(_borrowingsController.text) ?? 0;
    final reserves = double.tryParse(_reservesController.text) ?? 0;
    final udp = double.tryParse(_undistributedProfitController.text) ?? 0;
    final provisions = double.tryParse(_provisionsController.text) ?? 0;
    final otherLiabilities = double.tryParse(_otherLiabilitiesController.text) ?? 0;

    final cashInHand = double.tryParse(_cashInHandController.text) ?? 0;
    final cashAtBank = double.tryParse(_cashAtBankController.text) ?? 0;
    final investments = double.tryParse(_investmentsController.text) ?? 0;
    final loans = double.tryParse(_loansAdvancesController.text) ?? 0;
    final fixedAssets = double.tryParse(_fixedAssetsController.text) ?? 0;
    final otherAssets = double.tryParse(_otherAssetsController.text) ?? 0;
    final stock = double.tryParse(_stockInTradeController.text) ?? 0;

    setState(() {
      _workingFund = shareCapital + deposits + borrowings + reserves + udp;
      _ownFunds = shareCapital + reserves + udp;
      _totalLiabilities = shareCapital + deposits + borrowings + reserves + udp + provisions + otherLiabilities;
      _totalAssets = cashInHand + cashAtBank + investments + loans + fixedAssets + otherAssets + stock;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if ((_totalLiabilities - _totalAssets).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Balance Sheet must balance! Liabilities: ₹${_totalLiabilities.toStringAsFixed(2)}, Assets: ₹${_totalAssets.toStringAsFixed(2)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    
    final data = {
      'share_capital': double.tryParse(_shareCapitalController.text) ?? 0,
      'deposits': double.tryParse(_depositsController.text) ?? 0,
      'borrowings': double.tryParse(_borrowingsController.text) ?? 0,
      'reserves_statutory_free': double.tryParse(_reservesController.text) ?? 0,
      'undistributed_profit': double.tryParse(_undistributedProfitController.text) ?? 0,
      'provisions': double.tryParse(_provisionsController.text) ?? 0,
      'other_liabilities': double.tryParse(_otherLiabilitiesController.text) ?? 0,
      'cash_in_hand': double.tryParse(_cashInHandController.text) ?? 0,
      'cash_at_bank': double.tryParse(_cashAtBankController.text) ?? 0,
      'investments': double.tryParse(_investmentsController.text) ?? 0,
      'loans_advances': double.tryParse(_loansAdvancesController.text) ?? 0,
      'fixed_assets': double.tryParse(_fixedAssetsController.text) ?? 0,
      'other_assets': double.tryParse(_otherAssetsController.text) ?? 0,
      'stock_in_trade': double.tryParse(_stockInTradeController.text) ?? 0,
    };

    try {
      if (_existingId != null) {
        await updateBalanceSheet(_existingId!, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Balance Sheet updated successfully!'), backgroundColor: Colors.green),
        );
      } else {
        await createBalanceSheet(widget.periodId, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Balance Sheet created successfully!'), backgroundColor: Colors.green),
        );
      }
      await _loadData();
      widget.onSave?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save balance sheet: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBalanced = (_totalLiabilities - _totalAssets).abs() < 0.01;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Balance Sheet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Liabilities Section
            Text('Liabilities (Sources of Funds)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildNumberInput('Share Capital *', _shareCapitalController),
            const SizedBox(height: 10),
            _buildNumberInput('Deposits *', _depositsController),
            const SizedBox(height: 10),
            _buildNumberInput('Borrowings *', _borrowingsController),
            const SizedBox(height: 10),
            _buildNumberInput('Statutory & Free Reserves *', _reservesController),
            const SizedBox(height: 10),
            _buildNumberInput('Undistributed Profit (UDP) *', _undistributedProfitController),
            const SizedBox(height: 10),
            _buildNumberInput('Provisions *', _provisionsController),
            const SizedBox(height: 10),
            _buildNumberInput('Other Liabilities *', _otherLiabilitiesController),
            
            const SizedBox(height: 20),
            
            // Assets Section
            Text('Assets (Application of Funds)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildNumberInput('Cash in Hand *', _cashInHandController),
            const SizedBox(height: 10),
            _buildNumberInput('Cash at Bank *', _cashAtBankController),
            const SizedBox(height: 10),
            _buildNumberInput('Investments *', _investmentsController),
            const SizedBox(height: 10),
            _buildNumberInput('Loans & Advances *', _loansAdvancesController),
            const SizedBox(height: 10),
            _buildNumberInput('Fixed Assets *', _fixedAssetsController),
            const SizedBox(height: 10),
            _buildNumberInput('Other Assets *', _otherAssetsController),
            const SizedBox(height: 10),
            _buildNumberInput('Stock in Trade *', _stockInTradeController),
            
            const SizedBox(height: 20),
            
            // Calculated Values
            Card(
              color: isBalanced ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTotalRow('Working Fund', _workingFund),
                    const SizedBox(height: 8),
                    _buildTotalRow('Own Funds', _ownFunds),
                    const Divider(),
                    _buildTotalRow('Total Liabilities', _totalLiabilities),
                    const SizedBox(height: 8),
                    _buildTotalRow('Total Assets', _totalAssets),
                    if (!isBalanced)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Balance Sheet is not balanced!',
                          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (!_isReadOnly)
              ElevatedButton(
                onPressed: (_loading || !isBalanced) ? null : _handleSubmit,
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
  
  Widget _buildTotalRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
