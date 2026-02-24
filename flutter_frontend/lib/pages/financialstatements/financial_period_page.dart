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
        backgroundColor: Colors.transparent,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_period == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Financial Period not found', style: TextStyle(color: Colors.red))),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1400),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tab Navigation at the top
                _buildTabNavigation(isDark),
                const SizedBox(height: 24),

                // Info Box below tabs
                _buildInfoBox(isDark),
                const SizedBox(height: 24),

                // Tab Content Card
                _buildTabContent(isDark),
                const SizedBox(height: 24),

                // Completion Status Section Card
                _buildCompletionStatus(isDark),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.1) : const Color(0xFFEFF6FF),
        border: Border.all(color: isDark ? const Color(0xFF1E40AF).withOpacity(0.3) : const Color(0xFFDBEAFE)), // border-blue-200
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Info: Financial statements are read-only and cannot be updated.',
        style: TextStyle(
          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
          fontWeight: FontWeight.w600, // font-semibold
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTabNavigation(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
           bottom: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton('Trading Account', 0, isDark),
          const SizedBox(width: 32),
          _buildTabButton('Profit & Loss', 1, isDark),
          const SizedBox(width: 32),
          _buildTabButton('Balance Sheet', 2, isDark),
          const SizedBox(width: 32),
          _buildTabButton('Operational Metrics', 3, isDark),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index, bool isDark) {
    final isActive = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF2563EB) : Colors.transparent, // bg-blue-600
              width: 3,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isActive 
                ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)) 
                : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563)),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1.2, 
            color: isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;
              return GridView.count(
                crossAxisCount: isMobile ? (constraints.maxWidth < 500 ? 1 : 2) : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 4.8,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFF22C55E) : (isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1)),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



