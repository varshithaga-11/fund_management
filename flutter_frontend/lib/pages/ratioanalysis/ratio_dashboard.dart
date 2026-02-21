import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'productivity_analysis.dart';
import 'interpretation_panel.dart';
import '../financialstatements/financial_statements_api.dart';
import 'ratio_card.dart';
import 'ratio_analysis_table.dart';
import '../companyratioanalysis/period_data_edit_form.dart';

class RatioDashboardPage extends StatefulWidget {
  final int periodId;

  const RatioDashboardPage({super.key, required this.periodId});

  @override
  State<RatioDashboardPage> createState() => _RatioDashboardPageState();
}

class _RatioDashboardPageState extends State<RatioDashboardPage> {
  RatioResultData? _ratios;
  FinancialPeriodData? _period;
  bool _loading = true;
  String _viewMode = 'cards'; // 'cards' or 'table'
  String _userRole = '';
  bool _showExportMenu = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadData();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userRole = prefs.getString('userRole') ?? '';
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        getRatioResults(widget.periodId),
        getFinancialPeriod(widget.periodId),
      ]);
      
      if (mounted) {
        setState(() {
          _ratios = results[0] as RatioResultData?;
          _period = results[1] as FinancialPeriodData?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
        setState(() => _loading = false);
      }
    }
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export to Excel not implemented yet')),
    );
    setState(() => _showExportMenu = false);
  }

  void _exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export to PDF not implemented yet')),
    );
    setState(() => _showExportMenu = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ratios == null || _period == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('Ratios Not Calculated Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Financial ratio analysis hasn\'t been calculated for this period.',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    final calculatedDate = DateTime.parse(_ratios!.calculatedAt).toLocal().toString().split(' ')[0];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(calculatedDate),
                const SizedBox(height: 24),

                // View Toggle & Quick Action Buttons
                _buildViewToggleAndActions(),
                const SizedBox(height: 20),

                // Working Fund Summary
                _buildWorkingFundSummary(),
                const SizedBox(height: 24),

                // Interpretation Section (if available)
                if (_ratios!.interpretation != null && _ratios!.interpretation!.isNotEmpty && _ratios!.interpretation != 'null')
                  _buildInterpretationSection(),
                
                const SizedBox(height: 24),

                // Main Content based on View Mode
                if (_viewMode == 'table')
                  RatioAnalysisTable(ratios: _ratios!, periodLabel: _period?.label ?? '')
                else
                  _buildCardsView(),

                const SizedBox(height: 24),

                // Status Legend
                if (_viewMode == 'cards')
                  _buildStatusLegend(),

              const SizedBox(height: 32),

              // Edit Period Data Form (Master Role Only)
              if (_userRole == 'master')
                _buildEditPeriodDataSection(),

              const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String calculatedDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ratio Analysis Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_period != null)
          Text(
            '${_period!.label} - Calculated on $calculatedDate',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildViewToggleAndActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // View Toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton('Cards', Icons.grid_view, 'cards'),
                _buildToggleButton('Table', Icons.table_chart, 'table'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Quick Action Buttons
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductivityAnalysisPage(periodId: widget.periodId),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart),
            label: const Text('Productivity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InterpretationPanelPage(periodId: widget.periodId),
                ),
              );
            },
            icon: const Icon(Icons.message),
            label: const Text('Insight'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingFundSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Working Fund',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_ratios!.workingFund.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterpretationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interpretation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _ratios!.interpretation ?? 'No interpretation available',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, IconData icon, String mode) {
    bool isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsView() {
    return Column(
      children: [
        _buildRatioSection('Trading Ratios', _buildTradingRatios()),
        _buildRatioSection('Capital Efficiency', _buildCapitalEfficiencyRatios()),
        _buildRatioSection('Fund Structure Ratios', _buildFundStructureRatios()),
        _buildRatioSection('Yield & Cost Ratios', _buildYieldCostRatios()),
        _buildRatioSection('Margin Ratios', _buildMarginRatios()),
        _buildRatioSection('Productivity Ratios', _buildProductivityRatios()),
      ],
    );
  }

  Widget _buildRatioSection(String title, List<RatioCard> ratios) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        _buildGrid(ratios),
        const SizedBox(height: 16),
      ],
    );
  }

  List<RatioCard> _buildTradingRatios() {
    return [
      RatioCard(
        name: 'Stock Turnover',
        value: _ratios!.stockTurnover,
        unit: 'times',
        idealValue: 15.0,
        status: _ratios!.trafficLightStatus['stock_turnover'],
      ),
      RatioCard(
        name: 'Gross Profit Ratio',
        value: _ratios!.grossProfitRatio,
        unit: '%',
        idealValue: 10.0,
        status: _ratios!.trafficLightStatus['gross_profit_ratio'],
      ),
      RatioCard(
        name: 'Net Profit Ratio',
        value: _ratios!.netProfitRatio,
        unit: '%',
        status: _ratios!.trafficLightStatus['net_profit_ratio'],
      ),
    ];
  }

  List<RatioCard> _buildCapitalEfficiencyRatios() {
    return [
      RatioCard(
        name: 'Capital Turnover Ratio',
        value: _ratios!.capitalTurnoverRatio ?? 0,
        unit: '',
        status: _ratios!.trafficLightStatus['capital_turnover_ratio'],
      ),
    ];
  }

  List<RatioCard> _buildFundStructureRatios() {
    return [
      RatioCard(
        name: 'Net Own Funds',
        value: _ratios!.netOwnFunds ?? 0,
        unit: '',
        status: (_ratios!.netOwnFunds != null && _ratios!.netOwnFunds! > 0) ? 'green' : 'red',
      ),
      RatioCard(
        name: 'Own Fund to WF',
        value: _ratios!.ownFundToWf,
        idealValue: 8.0,
        status: _ratios!.trafficLightStatus['own_fund_to_wf'],
      ),
      RatioCard(
        name: 'Deposits to WF',
        value: _ratios!.depositsToWf,
        status: _ratios!.trafficLightStatus['deposits_to_wf'],
      ),
      RatioCard(
        name: 'Borrowings to WF',
        value: _ratios!.borrowingsToWf,
        status: _ratios!.trafficLightStatus['borrowings_to_wf'],
      ),
      RatioCard(
        name: 'Loans to WF',
        value: _ratios!.loansToWf,
        idealValue: 70.0,
        status: _ratios!.trafficLightStatus['loans_to_wf'],
      ),
      RatioCard(
        name: 'Investments to WF',
        value: _ratios!.investmentsToWf,
        idealValue: 25.0,
        status: _ratios!.trafficLightStatus['investments_to_wf'],
      ),
      RatioCard(
        name: 'Earning Assets to WF',
        value: _ratios!.earningAssetsToWf ?? 0,
        idealValue: 80.0,
        status: _ratios!.trafficLightStatus['earning_assets_to_wf'],
      ),
      RatioCard(
        name: 'Interest Tagged Funds to WF',
        value: _ratios!.interestTaggedFundsToWf ?? 0,
        status: _ratios!.trafficLightStatus['interest_tagged_funds_to_wf'],
      ),
    ];
  }

  List<RatioCard> _buildYieldCostRatios() {
    return [
      RatioCard(
        name: 'Cost of Deposits',
        value: _ratios!.costOfDeposits,
        unit: '%',
        status: _ratios!.trafficLightStatus['cost_of_deposits'],
      ),
      RatioCard(
        name: 'Yield on Loans',
        value: _ratios!.yieldOnLoans,
        unit: '%',
        status: _ratios!.trafficLightStatus['yield_on_loans'],
      ),
      RatioCard(
        name: 'Yield on Investments',
        value: _ratios!.yieldOnInvestments ?? 0,
        unit: '%',
        status: _ratios!.trafficLightStatus['yield_on_investments'],
      ),
      RatioCard(
        name: 'Credit Deposit Ratio',
        value: _ratios!.creditDepositRatio,
        unit: '%',
        idealValue: 70.0,
        status: _ratios!.trafficLightStatus['credit_deposit_ratio'],
      ),
      RatioCard(
        name: 'Avg Cost of WF',
        value: _ratios!.avgCostOfWf,
        unit: '%',
        idealValue: 3.5,
        status: _ratios!.trafficLightStatus['avg_cost_of_wf'],
      ),
      RatioCard(
        name: 'Avg Yield on WF',
        value: _ratios!.avgYieldOnWf ?? 0,
        unit: '%',
        idealValue: 3.5,
        status: _ratios!.trafficLightStatus['avg_yield_on_wf'],
      ),
      RatioCard(
        name: 'Misc Income to WF',
        value: _ratios!.miscIncomeToWf ?? 0,
        unit: '%',
        idealValue: 0.50,
        status: _ratios!.trafficLightStatus['misc_income_to_wf'],
      ),
      RatioCard(
        name: 'Interest Exp to Int Income',
        value: _ratios!.interestExpToInterestIncome ?? 0,
        unit: '%',
        idealValue: 62.0,
        status: _ratios!.trafficLightStatus['interest_exp_to_interest_income'],
      ),
    ];
  }

  List<RatioCard> _buildMarginRatios() {
    return [
      RatioCard(
        name: 'Gross Financial Margin',
        value: _ratios!.grossFinMargin,
        unit: '%',
        idealValue: 3.5,
        status: _ratios!.trafficLightStatus['gross_fin_margin'],
      ),
      RatioCard(
        name: 'Operating Cost to WF',
        value: _ratios!.operatingCostToWf,
        unit: '%',
        idealValue: 2.5,
        status: _ratios!.trafficLightStatus['operating_cost_to_wf'],
      ),
      RatioCard(
        name: 'Net Financial Margin',
        value: _ratios!.netFinMargin,
        unit: '%',
        idealValue: 1.5,
        status: _ratios!.trafficLightStatus['net_fin_margin'],
      ),
      RatioCard(
        name: 'Risk Cost to WF',
        value: _ratios!.riskCostToWf ?? 0,
        unit: '%',
        status: _ratios!.trafficLightStatus['risk_cost_to_wf'],
      ),
      RatioCard(
        name: 'Net Margin',
        value: _ratios!.netMargin,
        unit: '%',
        idealValue: 1.5,
        status: _ratios!.trafficLightStatus['net_margin'],
      ),
    ];
  }

  List<RatioCard> _buildProductivityRatios() {
    return [
      RatioCard(
        name: 'Per Employee Deposit',
        value: _ratios!.perEmployeeDeposit ?? 0,
        unit: '',
        status: _ratios!.trafficLightStatus['per_employee_deposit'],
      ),
      RatioCard(
        name: 'Per Employee Loan',
        value: _ratios!.perEmployeeLoan ?? 0,
        unit: '',
        status: _ratios!.trafficLightStatus['per_employee_loan'],
      ),
      RatioCard(
        name: 'Per Employee Contribution',
        value: _ratios!.perEmployeeContribution ?? 0,
        unit: '',
        status: _ratios!.trafficLightStatus['per_employee_contribution'],
      ),
      RatioCard(
        name: 'Per Employee Operating Cost',
        value: _ratios!.perEmployeeOperatingCost ?? 0,
        unit: '',
        status: _ratios!.trafficLightStatus['per_employee_operating_cost'],
      ),
    ];
  }

  Widget _buildStatusLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Legend',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Meets or exceeds ideal', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Sub-optimal but acceptable', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Critical - needs attention', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditPeriodDataSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit period data & recalculate ratios',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Update Trading Account, Profit & Loss, Balance Sheet, and Operational Metrics. Then click "Update data & recalculate ratios" to save and store updated ratio results.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          PeriodDataEditForm(
            periodId: widget.periodId,
            onSuccess: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final count = width > 900 ? 3 : (width > 600 ? 2 : 1);
      
      return GridView.count(
        crossAxisCount: count,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: children,
      );
    });
  }
}
