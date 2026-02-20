import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../financialstatements/financial_statements_api.dart';

class TrendAnalysisChart extends StatefulWidget {
  final List<RatioResultData> ratioData;
  final List<FinancialPeriodData> periods;
  final List<String> selectedRatios;
  final Function(List<String>) onSelectedRatiosChange;

  const TrendAnalysisChart({
    super.key,
    required this.ratioData,
    required this.periods,
    required this.selectedRatios,
    required this.onSelectedRatiosChange,
  });

  @override
  State<TrendAnalysisChart> createState() => _TrendAnalysisChartState();
}

class _TrendAnalysisChartState extends State<TrendAnalysisChart> {
  String _selectedCategory = 'Trading Ratios';
  // Chart types: 'line', 'bar' (others like radar/scatter omitted for MVP)
  String _chartType = 'line'; 

  static const Map<String, List<String>> _categories = {
    'Trading Ratios': [
      'stock_turnover',
      'gross_profit_ratio',
      'net_profit_ratio',
    ],
    'Fund Structure': [
      'own_fund_to_wf',
      'deposits_to_wf',
      'borrowings_to_wf',
      'loans_to_wf',
      'investments_to_wf',
    ],
    'Yield & Cost': [
      'cost_of_deposits',
      'yield_on_loans',
      'credit_deposit_ratio',
      'avg_cost_of_wf',
    ],
    'Margins': [
      'gross_fin_margin',
      'net_fin_margin',
      'net_margin',
    ],
  };

  @override
  Widget build(BuildContext context) {
    if (widget.ratioData.isEmpty || widget.periods.isEmpty) {
      return const Center(child: Text("Insufficient data to display trends"));
    }

    return Column(
      children: [
        _buildControls(),
        const SizedBox(height: 24),
        Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _chartType == 'line' ? _buildLineChart() : _buildBarChart(),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories.keys
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                          widget.onSelectedRatiosChange(_categories[val] ?? []);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _chartType,
                    decoration: const InputDecoration(labelText: 'Chart Type'),
                    items: const [
                      DropdownMenuItem(value: 'line', child: Text('Line Chart')),
                      DropdownMenuItem(value: 'bar', child: Text('Bar Chart')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _chartType = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: (_categories[_selectedCategory] ?? []).map((ratio) {
                final isSelected = widget.selectedRatios.contains(ratio);
                return FilterChip(
                  label: Text(_formatRatioName(ratio)),
                  selected: isSelected,
                  onSelected: (selected) {
                    final newSelection = List<String>.from(widget.selectedRatios);
                    if (selected) {
                      newSelection.add(ratio);
                    } else {
                      newSelection.remove(ratio);
                    }
                    widget.onSelectedRatiosChange(newSelection);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    // Prepare spots
    // Map periods to X axis indices (0, 1, 2...)
    // Map ratio values to Y axis
    
    final sortedData = _getSortedData();
    final xLabels = sortedData.map((d) {
       final p = widget.periods.firstWhere((p) => p.id == d.period);
       return p.label;
    }).toList();

    List<LineChartBarData> lineBars = [];
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple];

    for (int i = 0; i < widget.selectedRatios.length; i++) {
      final ratioKey = widget.selectedRatios[i];
      final spots = <FlSpot>[];
      
      for (int j = 0; j < sortedData.length; j++) {
        final val = _getRatioValue(sortedData[j], ratioKey);
        if (val != null) {
          spots.add(FlSpot(j.toDouble(), val));
        }
      }

      lineBars.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        color: colors[i % colors.length],
        barWidth: 3,
        dotData: const FlDotData(show: true),
      ));
    }

    return LineChart(
      LineChartData(
        lineBarsData: lineBars,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                int index = val.toInt();
                if (index >= 0 && index < xLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(xLabels[index], style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
              interval: 1,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
      ),
    );
  }

  Widget _buildBarChart() {
    final sortedData = _getSortedData();
    final xLabels = sortedData.map((d) {
       final p = widget.periods.firstWhere((p) => p.id == d.period);
       return p.label;
    }).toList();

    List<BarChartGroupData> barGroups = [];
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple];

    for (int j = 0; j < sortedData.length; j++) {
      final rods = <BarChartRodData>[];
      for (int i = 0; i < widget.selectedRatios.length; i++) {
        final ratioKey = widget.selectedRatios[i];
        final val = _getRatioValue(sortedData[j], ratioKey);
        if (val != null) {
          rods.add(BarChartRodData(
            toY: val,
            color: colors[i % colors.length],
            width: 12,
          ));
        }
      }
      barGroups.add(BarChartGroupData(x: j, barRods: rods));
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
         titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                int index = val.toInt();
                if (index >= 0 && index < xLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(xLabels[index], style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
              interval: 1,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
      ),
    );
  }

  List<RatioResultData> _getSortedData() {
    final periodMap = {for (var p in widget.periods) p.id: p};
    final sorted = List<RatioResultData>.from(widget.ratioData);
    sorted.sort((a, b) {
      final dateA = DateTime.tryParse(periodMap[a.period]?.startDate ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(periodMap[b.period]?.startDate ?? '') ?? DateTime(1970);
      return dateA.compareTo(dateB);
    });
    return sorted;
  }

  String _formatRatioName(String name) {
    return name
        .split('_')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  double? _getRatioValue(RatioResultData data, String key) {
    // Reusing the map logic
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
      case 'net_fin_margin': return data.netFinMargin;
      case 'net_margin': return data.netMargin;
      default: return null;
    }
  }
}
