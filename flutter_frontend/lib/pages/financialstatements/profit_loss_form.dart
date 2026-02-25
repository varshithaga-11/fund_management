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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profit & Loss Statement',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 32),
          
          // Income Section
          _buildSectionHeader('Income', isDark),
          const SizedBox(height: 20),
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isDesktop = screenWidth > 750;
              return Column(
                children: [
                  _buildFormRow([
                    _buildNumberInput('Interest on Loans *', _interestOnLoansController, isDark),
                    _buildNumberInput('Interest on Bank A/c *', _interestOnBankAcController, isDark),
                  ], isDesktop, isDark),
                  const SizedBox(height: 20),
                  _buildFormRow([
                    _buildNumberInput('Return on Investment *', _returnOnInvestmentController, isDark),
                    _buildNumberInput('Miscellaneous Income *', _miscellaneousIncomeController, isDark),
                  ], isDesktop, isDark),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _buildTotalDisplay('Total Income (Calculated)', _totalIncome, isDark),
          
          const SizedBox(height: 40),
          
          // Expenses Section
          _buildSectionHeader('Expenses', isDark),
          const SizedBox(height: 20),
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isDesktop = screenWidth > 750;
              return Column(
                children: [
                  _buildFormRow([
                    _buildNumberInput('Interest on Deposits *', _interestOnDepositsController, isDark),
                    _buildNumberInput('Interest on Borrowings *', _interestOnBorrowingsController, isDark),
                  ], isDesktop, isDark),
                  const SizedBox(height: 20),
                  _buildFormRow([
                    _buildNumberInput('Establishment & Contingencies *', _establishmentContingenciesController, isDark),
                    _buildNumberInput('Provisions *', _provisionsController, isDark),
                  ], isDesktop, isDark),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _buildTotalDisplay('Total Expenses (Calculated)', _totalExpenses, isDark),

          const SizedBox(height: 40),
          
          // Net Profit
          _buildSectionHeader('Net Profit', isDark),
          const SizedBox(height: 20),
          _buildNumberInput('Net Profit *', _netProfitController, isDark),
          
          if (!_isReadOnly) ...[
            const SizedBox(height: 48),
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
                  : const Text(
                      'Save Profit & Loss Statement',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 1.5,
          color: isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
        ),
      ],
    );
  }

  Widget _buildFormRow(List<Widget> children, bool isDesktop, bool isDark) {
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
  
  Widget _buildTotalDisplay(String label, double value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.1) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF1E40AF).withOpacity(0.3) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF64748B),
            )
          ),
          Text(
            '₹ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}


