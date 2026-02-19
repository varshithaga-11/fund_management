import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TrendAnalysisChart extends StatefulWidget {
  final List<Map<String, dynamic>> ratioData;
  final List<dynamic> periods; // Use PeriodWithRatiosData ideally, but dynamic for flexibility here

  const TrendAnalysisChart({
    super.key,
    required this.ratioData,
    required this.periods,
  });

  @override
  State<TrendAnalysisChart> createState() => _TrendAnalysisChartState();
}

class _TrendAnalysisChartState extends State<TrendAnalysisChart> {
  String selectedCategory = "Trading Ratios";
  List<String> selectedRatios = [];
  bool isLineChart = true; // basic toggle for Line vs Bar (simplified)
  
  final Map<String, List<String>> ratioCategories = {
    "Trading Ratios": [
      "stock_turnover",
      "gross_profit_ratio",
      "net_profit_ratio",
    ],
    "Capital Ratios": [
      "own_fund_to_wf",
    ],
    "Fund Structure": [
      "net_own_funds",
      "deposits_to_wf",
      "borrowings_to_wf",
      "loans_to_wf",
      "investments_to_wf",
      "earning_assets_to_wf",
      "interest_tagged_funds_to_wf",
    ],
    "Yield & Cost": [
      "cost_of_deposits",
      "yield_on_loans",
      "yield_on_investments",
      "credit_deposit_ratio",
      "avg_cost_of_wf",
      "avg_yield_on_wf",
      "misc_income_to_wf",
      "interest_exp_to_interest_income",
    ],
    "Margin Analysis": [
      "gross_fin_margin",
      "operating_cost_to_wf",
      "net_fin_margin",
      "risk_cost_to_wf",
      "net_margin",
    ],
    "Capital Efficiency": [
      "capital_turnover_ratio",
    ],
    "Productivity Analysis": [
      "per_employee_deposit",
      "per_employee_loan",
      "per_employee_contribution",
      "per_employee_operating_cost",
    ],
  };

  @override
  void initState() {
    super.initState();
    selectedRatios = List.from(ratioCategories[selectedCategory]!);
  }

  String formatRatioName(String name) {
    return name
        .split("_")
        .map((word) => "${word[0].toUpperCase()}${word.substring(1)}")
        .join(" ");
  }

  @override
  Widget build(BuildContext context) {
    // Process Data
    List<Map<String, dynamic>> sortedData = List.from(widget.ratioData);
    // Basic sort by ID assumption if dates aren't easily parsed strings
    // sortedData.sort((a, b) => a['period'] - b['period']); 
    
    // Check if we have data selected
    if (selectedRatios.isEmpty) {
      return const Center(child: Text('Select at least one ratio'));
    }

    // Chart Lines
    List<LineChartBarData> lineBarsData = [];
    final List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.pink];
    
    for (int i = 0; i < selectedRatios.length; i++) {
      String ratioKey = selectedRatios[i];
      List<FlSpot> spots = [];
      for (int j = 0; j < sortedData.length; j++) {
        var val = sortedData[j][ratioKey];
        double yVal = 0;
        if (val != null) {
          yVal = val is num ? val.toDouble() : double.tryParse(val.toString()) ?? 0;
        }
        spots.add(FlSpot(j.toDouble(), yVal));
      }

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: colors[i % colors.length],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return Column(
      children: [
        // Controls
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ratio Trend Analysis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                  items: ratioCategories.keys.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedCategory = val;
                        selectedRatios = List.from(ratioCategories[val]!);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Ratios Filter (Chips)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ratioCategories[selectedCategory]!.map((ratio) {
                    final isSelected = selectedRatios.contains(ratio);
                    return FilterChip(
                      label: Text(formatRatioName(ratio)),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedRatios.add(ratio);
                          } else {
                            selectedRatios.remove(ratio);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        // Chart
        Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ]
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < sortedData.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            sortedData[index]['period_label'] ?? '',
                            style: const TextStyle(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
              lineBarsData: lineBarsData,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      // Find which ratio this spot belongs to
                      // lineBarsData index matches selectedRatios index
                      final ratioName = formatRatioName(selectedRatios[spot.barIndex]);
                      return LineTooltipItem(
                        "$ratioName: ${spot.y.toStringAsFixed(2)}",
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
