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
      final crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
      
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 2.2, // Made card shorter
          crossAxisSpacing: 16,  // Reduced spacing
          mainAxisSpacing: 16,
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered 
                ? const Color(0xFF3B82F6) 
                : (widget.isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered 
                  ? Colors.black.withOpacity(0.12) 
                  : Colors.black.withOpacity(0.05),
              blurRadius: _isHovered ? 16 : 4,
              offset: _isHovered ? const Offset(0, 8) : const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (widget.item['ratioLabel'] as String).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: widget.isDark ? const Color(0xFFDBEAFE) : const Color(0xFF1E3A8A),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1, 
                    color: widget.isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: widget.pData.map((data) {
                    final direction = data['changeDirection'];
                    final isUp = direction == 'up';
                    final isDown = direction == 'down';
                    final displayDirection = isUp ? 'Up' : isDown ? 'Dip' : 'Stable';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['periodLabel'],
                            style: TextStyle(
                              fontSize: 11, 
                              color: widget.isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                data['value'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: widget.isDark ? Colors.white : const Color(0xFF111827),
                                ),
                              ),
                              if (data['changePercent'] != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isUp 
                                        ? Colors.green.withOpacity(0.1)
                                        : isDown 
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${data['changePercent']}% $displayDirection',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isUp 
                                          ? (widget.isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                                          : isDown 
                                              ? (widget.isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
                                              : Colors.grey,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
