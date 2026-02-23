import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../financialstatements/financial_statements_api.dart';

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
  String _chartType = 'line';
  List<int> _selectedPeriodIds = [];

  static const Map<String, List<String>> _categories = {
    'Trading Ratios': [
      'stock_turnover',
      'gross_profit_ratio',
      'net_profit_ratio',
    ],
    'Equity Analysis': [
      'net_own_funds',
    ],
    'Fund Structure': [
      'own_fund_to_wf',
      'deposits_to_wf',
      'borrowings_to_wf',
      'loans_to_wf',
      'investments_to_wf',
      'earning_assets_to_wf',
      'interest_tagged_funds_to_wf',
    ],
    'Yield & Cost': [
      'cost_of_deposits',
      'yield_on_loans',
      'yield_on_investments',
      'credit_deposit_ratio',
      'avg_cost_of_wf',
      'avg_yield_on_wf',
      'misc_income_to_wf',
      'interest_exp_to_interest_income',
    ],
    'Margin Analysis': [
      'gross_fin_margin',
      'operating_cost_to_wf',
      'net_fin_margin',
      'risk_cost_to_wf',
      'net_margin',
    ],
    'Capital Efficiency': [
      'capital_turnover_ratio',
    ],
    'Productivity Analysis': [
      'per_employee_deposit',
      'per_employee_loan',
      'per_employee_contribution',
      'per_employee_operating_cost',
    ],
  };

  final List<String> _chartTypes = [
    'line', 'area', 'bar', 'radar', 'scatter', 'candlestick', 'waterfall'
  ];

  @override
  void initState() {
    super.initState();
    _selectedPeriodIds = widget.periods.map((p) => p.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ratioData.isEmpty || widget.periods.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text("Insufficient data to display trends. Please ensure multiple periods are available."),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildControlsCard(),
        const SizedBox(height: 24),
        _buildPeriodSelectionCard(),
        const SizedBox(height: 24),
        _buildChartCard(),
      ],
    );
  }

  Widget _buildControlsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ratio Trend Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        _buildCategoryDropdown(),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chart Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        _buildChartTypeSelector(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Select Ratios to Display', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          _buildRatioSelectionGrid(),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.white,
        border: Border.all(color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF374151) : Colors.white,
          items: _categories.keys
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(fontSize: 14)),
                  ))
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
    );
  }

  Widget _buildChartTypeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<String>(
      onSelected: (val) => setState(() => _chartType = val),
      offset: const Offset(0, 45),
      position: PopupMenuPosition.under,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : Colors.white,
          border: Border.all(color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _chartType[0].toUpperCase() + _chartType.substring(1),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) => _chartTypes.map((type) {
        final isSelected = _chartType == type;
        return PopupMenuItem<String>(
          value: type,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(type[0].toUpperCase() + type.substring(1)),
              if (isSelected) Icon(Icons.check, size: 16, color: isDark ? Colors.blueAccent : Colors.blue),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatioSelectionGrid() {
    final ratios = _categories[_selectedCategory] ?? [];
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 5.5, // Much flatter
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: ratios.length,
          itemBuilder: (context, index) {
            final ratio = ratios[index];
            final isSelected = widget.selectedRatios.contains(ratio);
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return InkWell(
              onTap: () {
                final newSelection = List<String>.from(widget.selectedRatios);
                if (isSelected) {
                  newSelection.remove(ratio);
                } else {
                  newSelection.add(ratio);
                }
                widget.onSelectedRatiosChange(newSelection);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8), // Reduced padding
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isDark ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFFEFF6FF))
                      : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB)),
                  border: Border.all(
                    color: isSelected 
                        ? (isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE))
                        : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                  ),
                  borderRadius: BorderRadius.circular(6), // Slightly tighter radius
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (val) {
                          final newSelection = List<String>.from(widget.selectedRatios);
                          if (val == true) {
                            newSelection.add(ratio);
                          } else {
                            newSelection.remove(ratio);
                          }
                          widget.onSelectedRatiosChange(newSelection);
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        activeColor: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatRatioName(ratio),
                        style: const TextStyle(fontSize: 11), // Smaller text
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPeriodSelectionCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Periods for Graph',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), // Smaller title
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1000 ? 6 : (constraints.maxWidth > 600 ? 3 : 2);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 4.5, // Flatter for periods
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.periods.length,
                itemBuilder: (context, index) {
                  final period = widget.periods[index];
                  final isSelected = _selectedPeriodIds.contains(period.id);
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedPeriodIds.remove(period.id);
                        } else {
                          _selectedPeriodIds.add(period.id);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : Colors.white,
                        border: Border.all(color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 16, // Smaller checkbox area
                            width: 16,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedPeriodIds.add(period.id);
                                  } else {
                                    _selectedPeriodIds.remove(period.id);
                                  }
                                });
                              },
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                              activeColor: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              period.label,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_selectedPeriodIds.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Please select at least one period to display the chart',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartDescriptions = {
      'line': "Line Chart: Best for visualizing trends over time with smooth curves between data points.",
      'area': "Area Chart: Similar to line charts but with filled areas, great for showing cumulative trends.",
      'bar': "Bar Chart: Ideal for comparing values across periods, makes differences more visible.",
      'radar': "Radar Chart: Excellent for comparing multiple ratios within a single period, shows all dimensions at once.",
      'scatter': "Scatter Chart: Shows individual data points without line connections, useful for identifying patterns and outliers.",
      'candlestick': "Candlestick Chart: Displays volatility range around each ratio value - high, low, and close prices for each period.",
      'waterfall': "Waterfall Chart: Shows how values progressively change from one period to the next, visualizing incremental contributions.",
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.2) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE)),
            ),
            child: Text(
              chartDescriptions[_chartType] ?? "",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E40AF),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (widget.selectedRatios.isNotEmpty && _selectedPeriodIds.isNotEmpty)
            SizedBox(
              height: 400,
              child: _buildActiveChart(),
            )
          else
            Container(
              height: 400,
              alignment: Alignment.center,
              child: Text(
                widget.selectedRatios.isEmpty 
                    ? "Please select at least one ratio to display" 
                    : "Please select at least one period to display",
                style: const TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveChart() {
    switch (_chartType) {
      case 'line':
        return _buildLineChart(false);
      case 'area':
        return _buildLineChart(true);
      case 'bar':
        return _buildBarChart();
      case 'scatter':
        return _buildScatterChart();
      case 'waterfall':
        // Simplified as BarChart in React too
        return _buildBarChart();
      case 'radar':
      case 'candlestick':
        // Not natively supported by fl_chart, showing a message
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_graph, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "$_chartType Chart rendering error\nTry selecting different options or another chart type.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      default:
        return _buildLineChart(false);
    }
  }

  Widget _buildLineChart(bool isArea) {
    final filteredData = _getFilteredSortedData();
    final xLabels = _getXLabels(filteredData);
    
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    List<LineChartBarData> lineBars = [];
    for (int i = 0; i < widget.selectedRatios.length; i++) {
      final ratioKey = widget.selectedRatios[i];
      final spots = <FlSpot>[];
      for (int j = 0; j < filteredData.length; j++) {
        final val = _getRatioValue(filteredData[j], ratioKey);
        if (val != null && val.isFinite) {
          spots.add(FlSpot(j.toDouble(), val));
        }
      }
      if (spots.isNotEmpty) {
        lineBars.add(LineChartBarData(
          spots: spots,
          isCurved: true,
          color: colors[i % colors.length],
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: isArea,
            color: colors[i % colors.length].withOpacity(0.1),
          ),
        ));
      }
    }

    return LineChart(_getLineChartData(lineBars, xLabels));
  }

  LineChartData _getLineChartData(List<LineChartBarData> lineBars, List<String> xLabels) {
    return LineChartData(
      lineBarsData: lineBars,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) => const FlLine(
          color: Color(0xFFE5E7EB),
          strokeWidth: 1,
          dashArray: [3, 3],
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < xLabels.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    xLabels[index],
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              axisSide: meta.axisSide,
              space: 8,
              child: Text(
                value.toStringAsFixed(1),
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          left: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      minX: 0,
      maxX: (xLabels.length - 1).toDouble(),
    );
  }

  Widget _buildBarChart() {
    final filteredData = _getFilteredSortedData();
    final xLabels = _getXLabels(filteredData);
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    List<BarChartGroupData> barGroups = [];
    for (int j = 0; j < filteredData.length; j++) {
      List<BarChartRodData> rods = [];
      for (int i = 0; i < widget.selectedRatios.length; i++) {
        final val = _getRatioValue(filteredData[j], widget.selectedRatios[i]);
        if (val != null && val.isFinite) {
          rods.add(BarChartRodData(
            toY: val,
            color: colors[i % colors.length],
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ));
        }
      }
      barGroups.add(BarChartGroupData(x: j, barRods: rods));
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < xLabels.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      xLabels[index],
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                axisSide: meta.axisSide,
                space: 8,
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            left: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0xFFE5E7EB),
            strokeWidth: 1,
            dashArray: [3, 3],
          ),
        ),
      ),
    );
  }

  Widget _buildScatterChart() {
    final filteredData = _getFilteredSortedData();
    final xLabels = _getXLabels(filteredData);
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    List<LineChartBarData> lineBars = [];
    for (int i = 0; i < widget.selectedRatios.length; i++) {
      final ratioKey = widget.selectedRatios[i];
      final spots = <FlSpot>[];
      for (int j = 0; j < filteredData.length; j++) {
        final val = _getRatioValue(filteredData[j], ratioKey);
        if (val != null && val.isFinite) {
          spots.add(FlSpot(j.toDouble(), val));
        }
      }
      if (spots.isNotEmpty) {
        lineBars.add(LineChartBarData(
          spots: spots,
          isCurved: false,
          show: false, // Hide the lines
          color: colors[i % colors.length],
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 6,
              color: colors[i % colors.length],
              strokeWidth: 0,
            ),
          ),
        ));
      }
    }

    return LineChart(_getLineChartData(lineBars, xLabels));
  }

  List<RatioResultData> _getFilteredSortedData() {
    final periodMap = {for (var p in widget.periods) p.id: p};
    return widget.ratioData
        .where((d) => _selectedPeriodIds.contains(d.period))
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(periodMap[a.period]?.startDate ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(periodMap[b.period]?.startDate ?? '') ?? DateTime(1970);
        return dateA.compareTo(dateB);
      });
  }

  List<String> _getXLabels(List<RatioResultData> data) {
    final periodMap = {for (var p in widget.periods) p.id: p};
    return data.map((d) => periodMap[d.period]?.label ?? "P${d.period}").toList();
  }

  String _formatRatioName(String name) {
    return name
        .split('_')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
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

class ScatterSeries {
  final List<ScatterSpot> spots;
  ScatterSeries({required this.spots});
}