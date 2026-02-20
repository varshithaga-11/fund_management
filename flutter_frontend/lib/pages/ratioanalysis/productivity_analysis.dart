import 'package:flutter/material.dart';
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
      setState(() {
        _period = period;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load period data: $e')),
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_period == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Productivity Analysis')),
        body: const Center(child: Text('Period not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _period!.label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            _buildMetricCard(
              'Per Employee Business',
              '(Average Deposit + Average Loan) / Staff Count',
              _perEmployeeBusiness,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
              'Per Employee Contribution',
              '(Total Income - Interest Expenses) / Staff Count',
              _perEmployeeContribution,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
              'Per Employee Operating Cost',
              'Establishment & Contingencies / Staff Count',
              _perEmployeeOperatingCost,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildEfficiencyCard(),
            const SizedBox(height: 24),
            if (_period!.operationalMetrics != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('Total Staff Count: ',
                        style: TextStyle(color: Colors.grey)),
                    Text(
                      '${_period!.operationalMetrics!.staffCount}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String subtitle, double value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Text(
              '₹${value.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isEfficient ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: _isEfficient ? Colors.green.shade500 : Colors.red.shade500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Efficiency Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Contribution vs Operating Cost',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _isEfficient ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isEfficient ? 'Efficient' : 'Inefficient',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isEfficient ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isEfficient
                ? 'Employee contribution exceeds operating costs'
                : 'Operating costs exceed employee contribution',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
