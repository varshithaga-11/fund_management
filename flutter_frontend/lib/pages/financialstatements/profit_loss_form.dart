import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'financial_statements_api.dart';

class ProfitLossForm extends StatefulWidget {
  final int periodId;
  final VoidCallback? onSave;
  final bool canUpdate;

  const ProfitLossForm({
    super.key,
    required this.periodId,
    this.onSave,
    this.canUpdate = true,
  });

  @override
  State<ProfitLossForm> createState() => _ProfitLossFormState();
}

class _ProfitLossFormState extends State<ProfitLossForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Income
  final _interestOnLoansController = TextEditingController();
  final _interestOnBankAcController = TextEditingController();
  final _returnOnInvestmentController = TextEditingController();
  final _miscellaneousIncomeController = TextEditingController();
  
  // Expenses
  final _interestOnDepositsController = TextEditingController();
  final _interestOnBorrowingsController = TextEditingController();
  final _establishmentContingenciesController = TextEditingController();
  final _provisionsController = TextEditingController();
  
  // Net Profit
  final _netProfitController = TextEditingController();
  
  double _totalIncome = 0;
  double _totalExpenses = 0;
  
  bool _loading = false;
  int? _existingId;
  
  bool get _isReadOnly => !widget.canUpdate && _existingId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Listeners for totals
    _interestOnLoansController.addListener(_calculateTotals);
    _interestOnBankAcController.addListener(_calculateTotals);
    _returnOnInvestmentController.addListener(_calculateTotals);
    _miscellaneousIncomeController.addListener(_calculateTotals);
    
    _interestOnDepositsController.addListener(_calculateTotals);
    _interestOnBorrowingsController.addListener(_calculateTotals);
    _establishmentContingenciesController.addListener(_calculateTotals);
    _provisionsController.addListener(_calculateTotals);
  }

  @override
  void dispose() {
    _interestOnLoansController.dispose();
    _interestOnBankAcController.dispose();
    _returnOnInvestmentController.dispose();
    _miscellaneousIncomeController.dispose();
    _interestOnDepositsController.dispose();
    _interestOnBorrowingsController.dispose();
    _establishmentContingenciesController.dispose();
    _provisionsController.dispose();
    _netProfitController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await getProfitLoss(widget.periodId);
      if (data != null) {
        setState(() {
          _existingId = data.id;
          _interestOnLoansController.text = data.interestOnLoans.toString();
          _interestOnBankAcController.text = data.interestOnBankAc.toString();
          _returnOnInvestmentController.text = data.returnOnInvestment.toString();
          _miscellaneousIncomeController.text = data.miscellaneousIncome.toString();
          _interestOnDepositsController.text = data.interestOnDeposits.toString();
          _interestOnBorrowingsController.text = data.interestOnBorrowings.toString();
          _establishmentContingenciesController.text = data.establishmentContingencies.toString();
          _provisionsController.text = data.provisions.toString();
          _netProfitController.text = data.netProfit.toString();
        });
        _calculateTotals();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profit & loss: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _calculateTotals() {
    final i1 = double.tryParse(_interestOnLoansController.text) ?? 0;
    final i2 = double.tryParse(_interestOnBankAcController.text) ?? 0;
    final i3 = double.tryParse(_returnOnInvestmentController.text) ?? 0;
    final i4 = double.tryParse(_miscellaneousIncomeController.text) ?? 0;
    
    final e1 = double.tryParse(_interestOnDepositsController.text) ?? 0;
    final e2 = double.tryParse(_interestOnBorrowingsController.text) ?? 0;
    final e3 = double.tryParse(_establishmentContingenciesController.text) ?? 0;
    final e4 = double.tryParse(_provisionsController.text) ?? 0;

    setState(() {
      _totalIncome = i1 + i2 + i3 + i4;
      _totalExpenses = e1 + e2 + e3 + e4;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    
    final data = {
      'interest_on_loans': double.tryParse(_interestOnLoansController.text) ?? 0,
      'interest_on_bank_ac': double.tryParse(_interestOnBankAcController.text) ?? 0,
      'return_on_investment': double.tryParse(_returnOnInvestmentController.text) ?? 0,
      'miscellaneous_income': double.tryParse(_miscellaneousIncomeController.text) ?? 0,
      'interest_on_deposits': double.tryParse(_interestOnDepositsController.text) ?? 0,
      'interest_on_borrowings': double.tryParse(_interestOnBorrowingsController.text) ?? 0,
      'establishment_contingencies': double.tryParse(_establishmentContingenciesController.text) ?? 0,
      'provisions': double.tryParse(_provisionsController.text) ?? 0,
      'net_profit': double.tryParse(_netProfitController.text) ?? 0,
    };

    try {
      if (_existingId != null) {
        await updateProfitLoss(_existingId!, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profit & Loss updated successfully!'), backgroundColor: Colors.green),
        );
      } else {
        await createProfitLoss(widget.periodId, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profit & Loss created successfully!'), backgroundColor: Colors.green),
        );
      }
      await _loadData();
      widget.onSave?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profit & loss: $e'), backgroundColor: Colors.red),
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
              'Profit & Loss Statement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Income Section
            Text('Income', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildNumberInput('Interest on Loans *', _interestOnLoansController),
            const SizedBox(height: 10),
            _buildNumberInput('Interest on Bank A/c *', _interestOnBankAcController),
            const SizedBox(height: 10),
            _buildNumberInput('Return on Investment *', _returnOnInvestmentController),
            const SizedBox(height: 10),
            _buildNumberInput('Miscellaneous Income *', _miscellaneousIncomeController),
            const SizedBox(height: 10),
            _buildTotalDisplay('Total Income (Calculated)', _totalIncome),
            
            const SizedBox(height: 20),
            
            // Expenses Section
            Text('Expenses', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildNumberInput('Interest on Deposits *', _interestOnDepositsController),
            const SizedBox(height: 10),
            _buildNumberInput('Interest on Borrowings *', _interestOnBorrowingsController),
            const SizedBox(height: 10),
            _buildNumberInput('Establishment & Contingencies *', _establishmentContingenciesController),
            const SizedBox(height: 10),
            _buildNumberInput('Provisions *', _provisionsController),
            const SizedBox(height: 10),
            _buildTotalDisplay('Total Expenses (Calculated)', _totalExpenses),

            const SizedBox(height: 20),
            
            // Net Profit
            _buildNumberInput('Net Profit *', _netProfitController),
            
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
  
  Widget _buildTotalDisplay(String label, double value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
