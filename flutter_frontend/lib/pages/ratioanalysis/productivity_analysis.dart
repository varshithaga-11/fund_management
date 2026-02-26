import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/responsive_helper.dart';
import '../../theme/app_theme.dart';
import '../financialstatements/financial_statements_api.dart';

class ProductivityAnalysisPage extends StatefulWidget {
  final int periodId;

  const ProductivityAnalysisPage({super.key, required this.periodId});

  @override
  State<ProductivityAnalysisPage> createState() =>
      _ProductivityAnalysisPageState();
}

class _ProductivityAnalysisPageState extends State<ProductivityAnalysisPage> {
  FinancialPeriodData? _period;
  bool _loading = true;
  double _perEmployeeBusiness = 0;
  double _perEmployeeContribution = 0;
  double _perEmployeeOperatingCost = 0;
  bool _isEfficient = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    locale: 'en_IN',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final period = await getFinancialPeriod(widget.periodId);
      _calculateMetrics(period);
      if (mounted) {
        setState(() {
          _period = period;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load period data: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  void _calculateMetrics(FinancialPeriodData periodData) {
    final bs = periodData.balanceSheet;
    final pl = periodData.profitLoss;
    final ops = periodData.operationalMetrics;

    if (bs == null || pl == null || ops == null) return;

    final staffCount = ops.staffCount > 0 ? ops.staffCount : 0;

    if (staffCount > 0) {
      final deposits = bs.deposits;
      final loansAdvances = bs.loansAdvances;
      _perEmployeeBusiness = (deposits + loansAdvances) / staffCount;

      final interestOnLoans = pl.interestOnLoans;
      final interestOnBankAc = pl.interestOnBankAc;
      final returnOnInvestment = pl.returnOnInvestment;
      final miscIncome = pl.miscellaneousIncome;
      final interestOnDeposits = pl.interestOnDeposits;
      final interestOnBorrowings = pl.interestOnBorrowings;

      final totalIncome = interestOnLoans +
          interestOnBankAc +
          returnOnInvestment +
          miscIncome;
      final totalInterestExpense = interestOnDeposits + interestOnBorrowings;
      _perEmployeeContribution =
          (totalIncome - totalInterestExpense) / staffCount;

      final establishmentContingencies = pl.establishmentContingencies;
      _perEmployeeOperatingCost = establishmentContingencies / staffCount;

      _isEfficient = _perEmployeeContribution > _perEmployeeOperatingCost;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_period == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Period not found')),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Back Button
                    _buildHeader(isDark),
                    const SizedBox(height: 32),
        
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final crossAxisCount = screenWidth > 900 ? 2 : 1;
                        final spacing = 24.0;
                        final itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                        
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _buildMetricCard(
                                'Per Employee Business',
                                '(Average Deposit + Average Loan) / Staff Count',
                                _perEmployeeBusiness,
                                isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                isDark,
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _buildMetricCard(
                                'Per Employee Contribution',
                                '(Total Income - Interest Expenses) / Staff Count',
                                _perEmployeeContribution,
                                isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                                isDark,
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _buildMetricCard(
                                'Per Employee Operating Cost',
                                'Establishment & Contingencies / Staff Count',
                                _perEmployeeOperatingCost,
                                isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
                                isDark,
                              ),
                            ),
                            SizedBox(
                                width: itemWidth,
                                child: _buildEfficiencyCard(isDark),
                            ),
                          ],
                        );
                      },
                    ),
        
                    const SizedBox(height: 32),
        
                    // Staff Count Footer
                    if (_period!.operationalMetrics != null)
                      _buildStaffCountFooter(isDark),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_back,
                    size: 20,
                    color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Productivity Analysis',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _period!.label,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B5563),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String subtitle, double value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900, // Extra bold
              color: color,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard(bool isDark) {
    final successColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    final dangerColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    final baseColor = _isEfficient ? successColor : dangerColor;
    
    final borderColor = _isEfficient ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: _isEfficient
            ? (isDark ? const Color(0xFF16A34A).withOpacity(0.15) : const Color(0xFFF0FDF4))
            : (isDark ? const Color(0xFFDC2626).withOpacity(0.15) : const Color(0xFFFEF2F2)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Efficiency Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Contribution vs Operating Cost',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isEfficient ? 'Efficient' : 'Inefficient',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: baseColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isEfficient
                ? 'Employee contribution exceeds operating costs'
                : 'Operating costs exceed employee contribution',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCountFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total Staff Count: ',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B5563),
              fontSize: 14,
            ),
          ),
          Text(
            '${_period!.operationalMetrics!.staffCount}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

