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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBalanced = (_totalLiabilities - _totalAssets).abs() < 0.01;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Sheet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 32),
          
          // Liabilities Section
          _buildSectionHeader('Liabilities (Sources of Funds)', isDark),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 650;
              return Column(
                children: [
                  _buildFormRow([
                    _buildNumberInput('Share Capital *', _shareCapitalController, isDark),
                    _buildNumberInput('Deposits *', _depositsController, isDark),
                  ], isDesktop, isDark),
                  const SizedBox(height: 20),
                  _buildFormRow([
                    _buildNumberInput('Borrowings *', _borrowingsController, isDark),
                    _buildNumberInput('Statutory & Free Reserves *', _reservesController, isDark),
                  ], isDesktop, isDark),
                  const SizedBox(height: 20),
                  _buildFormRow([
                    _buildNumberInput('Undistributed Profit (UDP) *', _undistributedProfitController, isDark),
                    _buildNumberInput('Provisions *', _provisionsController, isDark),
                  ], isDesktop, isDark),
                  const SizedBox(height: 20),
                  _buildNumberInput('Other Liabilities *', _otherLiabilitiesController, isDark),
                ],
              );
            },
          ),
          
          const SizedBox(height: 40),
          
          // Assets Section
          _buildSectionHeader('Assets (Application of Funds)', isDark),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 650;
              return Column(
                children: [
                  _buildFormRow([
                    _buildNumberInput('Cash in Hand *', _cashInHandController, isDark),
                    _buildNumberInput('Cash at Bank *', _cashAtBankController, isDark),
                  ], isDesktop, isDark),
                  const SizedBox(height: 20),
                  _buildFormRow([
                    _buildNumberInput('Investments *', _investmentsController, isDark),
                    _buildNumberInput('Loans & Advances *', _loansAdvancesController, isDark),
                  ], isDesktop, isDark),
                  const SizedBox(height: 20),
                  _buildFormRow([
                    _buildNumberInput('Fixed Assets *', _fixedAssetsController, isDark),
                    _buildNumberInput('Other Assets *', _otherAssetsController, isDark),
                  ], isDesktop, isDark),
                  const SizedBox(height: 20),
                  _buildNumberInput('Stock in Trade *', _stockInTradeController, isDark),
                ],
              );
            },
          ),
          
          const SizedBox(height: 40),
          
          // Calculated Values
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isBalanced 
                  ? (isDark ? Colors.green.withOpacity(0.05) : const Color(0xFFF0FDF4).withOpacity(0.5)) 
                  : (isDark ? Colors.red.withOpacity(0.05) : const Color(0xFFFEF2F2).withOpacity(0.5)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isBalanced 
                    ? (isDark ? Colors.green.withOpacity(0.2) : const Color(0xFFBBF7D0)) 
                    : (isDark ? Colors.red.withOpacity(0.2) : const Color(0xFFFECACA)),
              ),
            ),
            child: Column(
              children: [
                _buildTotalRow('Working Fund', _workingFund, isDark),
                const SizedBox(height: 16),
                _buildTotalRow('Own Funds', _ownFunds, isDark),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Container(height: 1.5, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                _buildTotalRow('Total Liabilities', _totalLiabilities, isDark, isMajor: true),
                const SizedBox(height: 16),
                _buildTotalRow('Total Assets', _totalAssets, isDark, isMajor: true),
                if (!isBalanced)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.red.withOpacity(0.2) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Balance Sheet is not balanced!',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (!_isReadOnly) ...[
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_loading || !isBalanced) ? null : _handleSubmit,
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
                      'Save Balance Sheet',
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
  
  Widget _buildTotalRow(String label, double value, bool isDark, {bool isMajor = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: TextStyle(
            fontWeight: isMajor ? FontWeight.w900 : FontWeight.w700,
            fontSize: isMajor ? 16 : 14,
            color: isMajor 
                ? (isDark ? Colors.white : const Color(0xFF1F2937))
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
          )
        ),
        Text(
          '₹ ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: isMajor ? 20 : 15,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}



