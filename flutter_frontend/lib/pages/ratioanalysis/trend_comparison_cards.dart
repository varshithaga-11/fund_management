import 'package:flutter/material.dart';
import '../../financialstatements/financial_statements_api.dart';

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
    if (ratioData.isEmpty || periods.isEmpty || selectedRatios.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No data available for comparison'),
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
          final dateA =
              DateTime.parse(periodMap[a.period]?.startDate ?? '1970-01-01');
          final dateB =
              DateTime.parse(periodMap[b.period]?.startDate ?? '1970-01-01');
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
            if (changePercent > 0) changeDirection = 'up';
            if (changePercent < 0) changeDirection = 'down';
          }
        }

        periodsData.add({
          'periodLabel': currentPeriod?.label ?? 'Unknown',
          'value': currentValue.toStringAsFixed(2),
          'changePercent': changePercent?.abs().toStringAsFixed(1),
          'changeDirection': changeDirection,
        });
      }

      return {
        'ratioLabel': _formatRatioName(ratioKey),
        'periodsData': periodsData,
      };
    }).toList();

    return LayoutBuilder(builder: (context, constraints) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: constraints.maxWidth > 900
              ? 3
              : (constraints.maxWidth > 600 ? 2 : 1),
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: comparisonData.length,
        itemBuilder: (context, index) {
          final item = comparisonData[index];
          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['ratioLabel'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: (item['periodsData'] as List).length,
                      itemBuilder: (context, pIndex) {
                        final data = (item['periodsData'] as List)[pIndex];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(data['periodLabel'],
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                              Row(
                                children: [
                                  Text(data['value'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  if (data['changePercent'] != null) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${data['changePercent']}% ${data['changeDirection'] == 'up' ? 'Up' : data['changeDirection'] == 'down' ? 'Dip' : ''})',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: data['changeDirection'] == 'up'
                                            ? Colors.green
                                            : (data['changeDirection'] == 'down'
                                                ? Colors.red
                                                : Colors.grey),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  double? _getRatioValue(RatioResultData data, String key) {
    // Map string key to property
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
      case 'cost_of_deposits': return data.costOfDeposits;
      case 'yield_on_loans': return data.yieldOnLoans;
      case 'credit_deposit_ratio': return data.creditDepositRatio;
      case 'avg_cost_of_wf': return data.avgCostOfWf;
      case 'gross_fin_margin': return data.grossFinMargin;
      case 'net_margin': return data.netMargin;
      // Add more mappings as needed
      default: return null;
    }
  }
}
