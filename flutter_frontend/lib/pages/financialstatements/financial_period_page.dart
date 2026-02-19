import 'package:flutter/material.dart';
import 'financial_statements_api.dart';
import 'trading_account_form.dart';
import 'profit_loss_form.dart';
import 'balance_sheet_form.dart';
import 'operational_metrics_form.dart';

class FinancialPeriodPage extends StatefulWidget {
  final int periodId;

  const FinancialPeriodPage({super.key, required this.periodId});

  @override
  State<FinancialPeriodPage> createState() => _FinancialPeriodPageState();
}

class _FinancialPeriodPageState extends State<FinancialPeriodPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FinancialPeriodData? _period;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPeriod();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPeriod() async {
    setState(() => _loading = true);
    try {
      final data = await getFinancialPeriod(widget.periodId);
      setState(() {
        _period = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load financial period: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_period == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Financial Period not found', style: TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_period!.label),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                   // Navigate to dashboard
                   // Navigator.pushNamed(context, '/ratio-analysis/${widget.periodId}');
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Dashboard navigation not implemented yet')),
                   );
                },
                child: const Text('View Dashboard'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _period!.label,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _period!.periodType.toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Message
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Info: Financial statements are read-only and cannot be updated.',
                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Trading Account'),
              Tab(text: 'Profit & Loss'),
              Tab(text: 'Balance Sheet'),
              Tab(text: 'Operational Metrics'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TradingAccountForm(
                  periodId: widget.periodId,
                  onSave: _loadPeriod,
                  canUpdate: false,
                ),
                ProfitLossForm(
                  periodId: widget.periodId,
                  onSave: _loadPeriod,
                  canUpdate: false,
                ),
                BalanceSheetForm(
                  periodId: widget.periodId,
                  onSave: _loadPeriod,
                  canUpdate: false,
                ),
                OperationalMetricsForm(
                  periodId: widget.periodId,
                  onSave: _loadPeriod,
                  canUpdate: false,
                ),
              ],
            ),
          ),
          
          // Completion Status
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completion Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100, // Fixed height for grid
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 4, // Adjust for landscape/portrait
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatusIndicator('Trading Account', _period!.tradingAccount != null),
                      _buildStatusIndicator('Profit & Loss', _period!.profitLoss != null),
                      _buildStatusIndicator('Balance Sheet', _period!.balanceSheet != null),
                      _buildStatusIndicator('Operational Metrics', _period!.operationalMetrics != null),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isCompleted) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
