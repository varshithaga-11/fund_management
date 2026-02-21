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
    _tabController.addListener(() {
      setState(() {});
    });
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
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Financial Period not found', style: TextStyle(color: Colors.red))),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Period'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Header Section
              _buildHeader(isDark),
              const SizedBox(height: 24),

              // Info Box
              _buildInfoBox(),
              const SizedBox(height: 24),

              // Tab Navigation
              _buildTabNavigation(),
              const SizedBox(height: 16),

              // Tab Content
              _buildTabContent(),
              const SizedBox(height: 32),

              // Completion Status Section
              _buildCompletionStatus(isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _period!.label,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _period!.periodType.replaceAll('_', ' ').toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/ratio-analysis/dashboard/${widget.periodId}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 2,
            ),
            child: const Text(
              'View Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Info: Financial statements are read-only and cannot be updated.',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabButton('Trading Account', 0),
            _buildTabButton('Profit & Loss', 1),
            _buildTabButton('Balance Sheet', 2),
            _buildTabButton('Operational Metrics', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isActive = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.blue.shade600 : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isActive ? Colors.blue.shade600 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _getTabContent(),
    );
  }

  Widget _getTabContent() {
    switch (_tabController.index) {
      case 0:
        return TradingAccountForm(
          periodId: widget.periodId,
          onSave: _loadPeriod,
          canUpdate: false,
        );
      case 1:
        return ProfitLossForm(
          periodId: widget.periodId,
          onSave: _loadPeriod,
          canUpdate: false,
        );
      case 2:
        return BalanceSheetForm(
          periodId: widget.periodId,
          onSave: _loadPeriod,
          canUpdate: false,
        );
      case 3:
        return OperationalMetricsForm(
          periodId: widget.periodId,
          onSave: _loadPeriod,
          canUpdate: false,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCompletionStatus(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Divider(height: 16),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return GridView.count(
                crossAxisCount: isMobile ? 2 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _buildStatusIndicator('Trading Account', _period!.tradingAccount != null, isDark),
                  _buildStatusIndicator('Profit & Loss', _period!.profitLoss != null, isDark),
                  _buildStatusIndicator('Balance Sheet', _period!.balanceSheet != null, isDark),
                  _buildStatusIndicator('Operational Metrics', _period!.operationalMetrics != null, isDark),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isCompleted, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.shade600 : Colors.grey.shade400,
              shape: BoxShape.circle,
              boxShadow: [
                if (isCompleted)
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 4,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
