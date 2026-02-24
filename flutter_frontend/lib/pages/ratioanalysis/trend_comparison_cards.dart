import 'package:flutter/material.dart';
import '../financialstatements/financial_statements_api.dart';

class TrendComparisonCards extends StatelessWidget {
  final List<RatioResultData> ratioData;
  final List<FinancialPeriodData> periods;
  final List<String> selectedRatios;

  const TrendComparisonCards({
    super.key,
    required this.ratioData,
    required this.periods,
    required this.selectedRatios,
  });

  String _formatRatioName(String name) {
    return name
        .split('_')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (ratioData.isEmpty || periods.isEmpty || selectedRatios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No data available for comparison',
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
          ),
        ),
      );
    }

    final periodMap = {for (var p in periods) p.id: p};

    final comparisonData = selectedRatios.map((ratioKey) {
      // Filter and sort data
      final sortedData = ratioData
          .where((r) => _getRatioValue(r, ratioKey) != null)
          .toList()
        ..sort((a, b) {
          final dateA = DateTime.tryParse(periodMap[a.period]?.startDate ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(periodMap[b.period]?.startDate ?? '') ?? DateTime(1970);
          return dateA.compareTo(dateB);
        });

      final periodsData = <Map<String, dynamic>>[];
      for (int i = 0; i < sortedData.length; i++) {
        final current = sortedData[i];
        final currentPeriod = periodMap[current.period];
        final currentValue = _getRatioValue(current, ratioKey) ?? 0.0;

        double? changePercent;
        String changeDirection = 'stable';

        if (i > 0) {
          final previous = sortedData[i - 1];
          final previousValue = _getRatioValue(previous, ratioKey) ?? 0.0;
          if (previousValue != 0) {
            changePercent = ((currentValue - previousValue) / previousValue) * 100;
            if (changePercent > 0.05) changeDirection = 'up';
            else if (changePercent < -0.05) changeDirection = 'down';
          }
        }

        periodsData.add({
          'periodLabel': currentPeriod?.label ?? 'Unknown',
          'value': currentValue.toStringAsFixed(2),
          'changePercent': changePercent != null ? changePercent.abs().toStringAsFixed(1) : null,
          'changeDirection': changeDirection,
        });
      }

      return {
        'ratioLabel': _formatRatioName(ratioKey),
        'periodsData': periodsData,
      };
    }).toList();

    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 1000 
          ? 3 
          : (constraints.maxWidth > 700 ? 2 : 1);
      
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.6, // Increased height
          crossAxisSpacing: 24,  // gap-6
          mainAxisSpacing: 24,   // gap-6
        ),
        itemCount: comparisonData.length,
        itemBuilder: (context, index) {
          final item = comparisonData[index];
          final pData = item['periodsData'] as List;

          return _TrendCard(
            isDark: isDark,
            item: item,
            pData: pData,
          );
        },
      );
    });
  }

  double? _getRatioValue(RatioResultData data, String key) {
    switch (key) {
      case 'stock_turnover': return data.stockTurnover;
      case 'gross_profit_ratio': return data.grossProfitRatio;
      case 'net_profit_ratio': return data.netProfitRatio;
      case 'net_own_funds': return data.netOwnFunds;
      case 'own_fund_to_wf': return data.ownFundToWf;
      case 'deposits_to_wf': return data.depositsToWf;
      case 'borrowings_to_wf': return data.borrowingsToWf;
      case 'loans_to_wf': return data.loansToWf;
      case 'investments_to_wf': return data.investmentsToWf;
      case 'earning_assets_to_wf': return data.earningAssetsToWf;
      case 'interest_tagged_funds_to_wf': return data.interestTaggedFundsToWf;
      case 'cost_of_deposits': return data.costOfDeposits;
      case 'yield_on_loans': return data.yieldOnLoans;
      case 'yield_on_investments': return data.yieldOnInvestments;
      case 'credit_deposit_ratio': return data.creditDepositRatio;
      case 'avg_cost_of_wf': return data.avgCostOfWf;
      case 'avg_yield_on_wf': return data.avgYieldOnWf;
      case 'misc_income_to_wf': return data.miscIncomeToWf;
      case 'interest_exp_to_interest_income': return data.interestExpToInterestIncome;
      case 'gross_fin_margin': return data.grossFinMargin;
      case 'operating_cost_to_wf': return data.operatingCostToWf;
      case 'net_fin_margin': return data.netFinMargin;
      case 'risk_cost_to_wf': return data.riskCostToWf;
      case 'net_margin': return data.netMargin;
      case 'capital_turnover_ratio': return data.capitalTurnoverRatio;
      case 'per_employee_deposit': return data.perEmployeeDeposit;
      case 'per_employee_loan': return data.perEmployeeLoan;
      case 'per_employee_contribution': return data.perEmployeeContribution;
      case 'per_employee_operating_cost': return data.perEmployeeOperatingCost;
      default: return null;
    }
  }
}

class _TrendCard extends StatefulWidget {
  final bool isDark;
  final Map<String, dynamic> item;
  final List pData;

  const _TrendCard({
    required this.isDark,
    required this.item,
    required this.pData,
  });

  @override
  State<_TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<_TrendCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.all(20), // p-5 in React
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9), // border-gray-100
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // shadow-sm
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          Text(
            (widget.item['ratioLabel'] as String).toUpperCase(),
            style: TextStyle(
              fontSize: 11, // Smaller title
              fontWeight: FontWeight.w900,
              color: widget.isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 1, 
            color: widget.isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF9FAFB),
          ),
          const SizedBox(height: 16), // Tighter spacing
          
          // Data List
          Expanded(
            child: widget.pData.length > 5
                ? ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(scrollbars: false),
                    child: RawScrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      radius: const Radius.circular(10),
                      thickness: 4,
                      thumbColor: widget.isDark 
                          ? Colors.white.withOpacity(0.2) 
                          : Colors.black.withOpacity(0.12),
                      minThumbLength: 24,
                      child: SingleChildScrollView(
                        key: ValueKey('scroll_${widget.item['ratioLabel']}'),
                        controller: _scrollController,
                        primary: false,
                        physics: const ClampingScrollPhysics(),
                        clipBehavior: Clip.hardEdge,
                        padding: const EdgeInsets.only(right: 20),
                        child: _buildDataColumn(),
                      ),
                    ),
                  )
                : _buildDataColumn(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataColumn() {
    return Column(
      children: widget.pData.map((data) {
        final direction = data['changeDirection'];
        final isUp = direction == 'up';
        final isDown = direction == 'down';
        final displayDirection = isUp ? 'Up' : isDown ? 'Dip' : 'Stable';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12), // Tighter vertical spacing
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['periodLabel'],
                style: TextStyle(
                  fontSize: 10, // Smaller period label
                  color: widget.isDark 
                      ? const Color(0xFF9CA3AF) 
                      : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data['value'],
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12, // Smaller value
                      color: widget.isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  if (data['changePercent'] != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(${data['changePercent']}% $displayDirection)',
                      style: TextStyle(
                        fontSize: 9, // Smaller trend text
                        color: isUp 
                            ? (widget.isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                            : isDown 
                                ? (widget.isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
                                : (widget.isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF)),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
