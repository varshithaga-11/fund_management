import 'package:flutter/material.dart';
import 'productivity_analysis.dart';
import 'interpretation_panel.dart';
import '../financialstatements/financial_statements_api.dart';
import 'ratio_card.dart';
import 'ratio_analysis_table.dart';

// Adjust import path as per your project structure.
// If your project name is not 'fund_management', change it accordingly.
// Based on previous files, I'll use relative imports where possible or assume package name.
// The user provided path d:\varshitha2\fundmanagement\flutter_frontend\lib\pages\ratioanalysis
// So package:flutter_frontend/pages/ratioanalysis/...

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

  @override
  void initState() {
    super.initState();
    _loadData();
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
    // TODO: Implement Excel export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export to Excel not implemented yet')),
    );
  }

  void _exportToPDF() {
    // TODO: Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export to PDF not implemented yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_ratios == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ratio Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              const Text('Ratios Not Calculated Yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                  'Financial ratio analysis hasn\'t been calculated for this period.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to Financial Statements to calculate
                  // Navigator.pushNamed(context, '/financial-statements/${widget.periodId}');
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please calculate ratios in Financial Statements module')));
                },
                child: const Text('Go to Period Data'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ratio Analysis Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'excel') _exportToExcel();
              if (value == 'pdf') _exportToPDF();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_view, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Export to Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Export to PDF'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.download),
            tooltip: 'Export',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_period != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _period!.label,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'Calculated on ${DateTime.parse(_ratios!.calculatedAt).toLocal().toString().split(' ')[0]}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

            // Toggle & Actions
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
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
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductivityAnalysisPage(
                              periodId: widget.periodId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('Productivity'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InterpretationPanelPage(
                              periodId: widget.periodId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Insight'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_viewMode == 'table')
              RatioAnalysisTable(ratios: _ratios!, periodLabel: _period?.label)
            else
              _buildCardsView(),
          ],
        ),
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
        _buildSectionTitle('Trading Ratios'),
        _buildGrid([
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
        ]),
        
        _buildSectionTitle('Fund Structure'),
        _buildGrid([
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
        ]),

        _buildSectionTitle('Yield & Cost'),
        _buildGrid([
          RatioCard(
            name: 'Cost of Deposits',
            value: _ratios!.costOfDeposits,
            status: _ratios!.trafficLightStatus['cost_of_deposits'],
          ),
          RatioCard(
            name: 'Yield on Loans',
            value: _ratios!.yieldOnLoans,
            status: _ratios!.trafficLightStatus['yield_on_loans'],
          ),
          RatioCard(
            name: 'Credit Deposit Ratio',
            value: _ratios!.creditDepositRatio,
            idealValue: 70.0,
            status: _ratios!.trafficLightStatus['credit_deposit_ratio'],
          ),
          RatioCard(
            name: 'Avg Cost of WF',
            value: _ratios!.avgCostOfWf,
            idealValue: 3.5,
            status: _ratios!.trafficLightStatus['avg_cost_of_wf'],
          ),
        ]),
        
        _buildSectionTitle('Margins'),
        _buildGrid([
          RatioCard(
            name: 'Gross Fin Margin',
            value: _ratios!.grossFinMargin,
            idealValue: 3.5,
            status: _ratios!.trafficLightStatus['gross_fin_margin'],
          ),
          RatioCard(
            name: 'Op Cost to WF',
            value: _ratios!.operatingCostToWf,
            idealValue: 2.5,
            status: _ratios!.trafficLightStatus['operating_cost_to_wf'],
          ),
          RatioCard(
            name: 'Net Fin Margin',
            value: _ratios!.netFinMargin,
            idealValue: 1.5,
            status: _ratios!.trafficLightStatus['net_fin_margin'],
          ),
          RatioCard(
            name: 'Net Margin',
            value: _ratios!.netMargin,
            idealValue: 1.5,
            status: _ratios!.trafficLightStatus['net_margin'],
          ),
        ]),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            color: Colors.blue,
            margin: const EdgeInsets.only(right: 8),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Widget> children) {
    // Determine cross axis count based on width is hard inside scrollview without LayoutBuilder
    // But we can use Wrap or GridView with shrinkWrap
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final count = width > 900 ? 3 : (width > 600 ? 2 : 1);
      
      return GridView.count(
        crossAxisCount: count,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5, // Adjust based on RatioCard content
        children: children,
      );
    });
  }
}
