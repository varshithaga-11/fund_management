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
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Back Button
              _buildHeader(isDark),
              const SizedBox(height: 24),
    
              // Metrics Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: constraints.maxWidth > 800 ? 2.2 : 1.8,
                    children: [
                      _buildMetricCard(
                        'Per Employee Business',
                        '(Average Deposit + Average Loan) / Staff Count',
                        _perEmployeeBusiness,
                        AppColors.info,
                        isDark,
                      ),
                      _buildMetricCard(
                        'Per Employee Contribution',
                        '(Total Income - Interest Expenses) / Staff Count',
                        _perEmployeeContribution,
                        AppColors.success,
                        isDark,
                      ),
                      _buildMetricCard(
                        'Per Employee Operating Cost',
                        'Establishment & Contingencies / Staff Count',
                        _perEmployeeOperatingCost,
                        AppColors.warning,
                        isDark,
                      ),
                      _buildEfficiencyCard(isDark),
                    ],
                  );
                },
              ),
    
              const SizedBox(height: 32),
    
              // Staff Count Footer
              if (_period!.operationalMetrics != null)
                _buildStaffCountFooter(isDark),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back,
                color: isDark ? AppColors.white : AppColors.gray700),
            tooltip: 'Back to Dashboard',
            style: IconButton.styleFrom(
              hoverColor: isDark ? AppColors.gray700 : AppColors.gray100,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Productivity Analysis',
                  style: (isDark
                          ? AppTypography.h3.copyWith(color: AppColors.white)
                          : AppTypography.h3.copyWith(color: AppTypography.h3.color))
                      .copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _period!.label,
                  style: TextStyle(
                    color: isDark ? AppColors.gray400 : AppColors.gray600,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.gray400 : AppColors.gray600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard(bool isDark) {
    final baseColor = _isEfficient ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isEfficient
            ? (isDark ? baseColor.withOpacity(0.1) : Colors.green.shade50)
            : (isDark ? baseColor.withOpacity(0.1) : Colors.red.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Efficiency Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Contribution vs Operating Cost',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.gray400 : AppColors.gray600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _isEfficient ? 'Efficient' : 'Inefficient',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: baseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isEfficient
                ? 'Employee contribution exceeds operating costs'
                : 'Operating costs exceed employee contribution',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.gray300 : AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCountFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.gray200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total Staff Count: ',
            style: TextStyle(
              color: isDark ? AppColors.gray400 : AppColors.gray600,
              fontSize: 14,
            ),
          ),
          Text(
            '${_period!.operationalMetrics!.staffCount}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.gray900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

