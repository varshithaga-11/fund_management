import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../financialstatements/financial_statements_api.dart';
import '../../utils/file_saver.dart';

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
  double _zoomScale = 1.0;
  double _xOffset = 0.0;
  final GlobalKey _chartKey = GlobalKey();

  static const Map<String, List<String>> _categories = {
    'Trading Ratios': [
      'stock_turnover',
      'gross_profit_ratio',
      'net_profit_ratio',
    ],
    'Capital Ratios': [
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
        if (widget.selectedRatios.isNotEmpty && _selectedPeriodIds.isNotEmpty) ...[
          const SizedBox(height: 24),
          // Statistics Summary removed as per request to avoid duplicate cards below graph
        ],
      ],
    );
  }

  Widget _buildControlsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ratio Trend Analysis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select ratios and chart type to visualize trends',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isWide = screenWidth > 900;
              final subItemWidth = isWide ? (screenWidth - 400) / 2 : screenWidth - 100;
              
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: subItemWidth.clamp(300, 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCategoryDropdown(),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: subItemWidth.clamp(300, 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chart Type',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildChartTypeSelector(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Divider(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            height: 1,
          ),
          const SizedBox(height: 20),
          Text(
            'Select Ratios to Display',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          _buildRatioSelectionGrid(),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF2D3748) : Colors.white,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontWeight: FontWeight.w500,
          ),
          items: _categories.keys
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _chartType,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF2D3748) : Colors.white,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontWeight: FontWeight.w500,
          ),
          items: _chartTypes
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(
                      t[0].toUpperCase() + t.substring(1),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _chartType = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildRatioSelectionGrid() {
    final ratios = _categories[_selectedCategory] ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth > 1100 ? 4 : (screenWidth > 700 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 4.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: ratios.length,
          itemBuilder: (context, index) {
            final ratio = ratios[index];
            final isSelected = widget.selectedRatios.contains(ratio);
            
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isDark 
                          ? const Color(0xFF1E3A8A).withOpacity(0.25) 
                          : const Color(0xFFEFF6FF))
                      : (isDark 
                          ? const Color(0xFF374151).withOpacity(0.3) 
                          : const Color(0xFFFAFAFA)),
                  border: Border.all(
                    color: isSelected 
                        ? (isDark 
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFBFDBFE))
                        : (isDark 
                            ? const Color(0xFF4B5563)
                            : const Color(0xFFE5E7EB)),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatRatioName(ratio),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Periods for Graph',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose which financial periods to include in your trend analysis',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final crossAxisCount = screenWidth > 1100 ? 6 : (screenWidth > 700 ? 3 : 2);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 4.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark 
                                ? const Color(0xFF1E3A8A).withOpacity(0.4)
                                : const Color(0xFFEFF6FF))
                            : (isDark 
                                ? const Color(0xFF374151).withOpacity(0.3)
                                : Colors.white),
                        border: Border.all(
                          color: isSelected
                              ? (isDark 
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFBFDBFE))
                              : (isDark 
                                  ? const Color(0xFF4B5563)
                                  : const Color(0xFFE5E7EB)),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              period.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF111827),
                              ),
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
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  border: Border.all(color: const Color(0xFFFECACE)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFFDC2626)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please select at least one period to display the chart',
                        style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chart View',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF1E3A8A).withOpacity(0.1)
                  : const Color(0xFFF1F5F9).withOpacity(0.5),
              border: Border.all(
                color: isDark 
                    ? const Color(0xFF1E40AF).withOpacity(0.3)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF334155),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    chartDescriptions[_chartType] ?? "",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF334155),
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildChartHeader(),
          const SizedBox(height: 16),
          if (widget.selectedRatios.isNotEmpty && _selectedPeriodIds.isNotEmpty)
            SizedBox(
              height: 460,
              child: RepaintBoundary(
                key: _chartKey,
                child: _buildActiveChart(),
              ),
            )
          else
            Container(
              height: 420,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
                border: Border.all(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    size: 48,
                    color: isDark 
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.selectedRatios.isEmpty 
                        ? "Please select at least one ratio to display" 
                        : "Please select at least one period to display",
                    style: TextStyle(
                      color: isDark 
                          ? Colors.grey.shade500
                          : Colors.grey.shade500,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildLegend()),
        _buildChartTools(),
      ],
    );
  }

  Widget _buildLegend() {
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    
    final sortedUniqueRatios = widget.selectedRatios.toSet().toList();
    
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: sortedUniqueRatios.map((ratio) {
        final index = widget.selectedRatios.indexOf(ratio);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatRatioName(ratio),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.9) 
                    : const Color(0xFF334155),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildChartTools() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToolIcon(Icons.add_circle_outline, () => _handleZoom(0.8), iconColor),
        const SizedBox(width: 10),
        _buildToolIcon(Icons.remove_circle_outline, () => _handleZoom(1.2), iconColor),
        const SizedBox(width: 10),
        _buildToolIcon(Icons.home_outlined, _handleReset, iconColor),
        const SizedBox(width: 10),
        PopupMenuButton<String>(
          icon: Icon(Icons.menu, size: 18, color: iconColor),
          padding: EdgeInsets.zero,
          offset: const Offset(0, 30),
          constraints: const BoxConstraints(minWidth: 160),
          onSelected: (value) => _handleDownload(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'png',
              child: Text('Download PNG', style: TextStyle(fontSize: 13)),
            ),
            const PopupMenuItem(
              value: 'csv',
              child: Text('Download CSV', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolIcon(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  void _handleZoom(double factor) {
    setState(() {
      _zoomScale *= factor;
      if (_zoomScale < 0.1) _zoomScale = 0.1;
      if (_zoomScale > 1.0) {
        _zoomScale = 1.0;
        _xOffset = 0.0;
      }
    });
  }

  void _handleReset() {
    setState(() {
      _zoomScale = 1.0;
      _xOffset = 0.0;
    });
  }

  Future<void> _handleDownload(String type) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preparing ${type.toUpperCase()} download...')),
    );

    try {
      if (type == 'csv') {
        final filteredData = _getFilteredSortedData();
        if (filteredData.isEmpty) throw "No data available to export";

        final xLabels = _getXLabels(filteredData);
        final buffer = StringBuffer();

        // Header
        buffer.write('Period');
        for (var ratio in widget.selectedRatios) {
          buffer.write(',${_formatRatioName(ratio)}');
        }
        buffer.writeln();

        // Data rows
        for (int i = 0; i < filteredData.length; i++) {
          buffer.write(xLabels[i]);
          final data = filteredData[i];
          for (var ratio in widget.selectedRatios) {
            final val = _getRatioValue(data, ratio);
            buffer.write(',${val?.toStringAsFixed(4) ?? '0.00'}');
          }
          buffer.writeln();
        }

        final bytes = utf8.encode(buffer.toString());
        await saveAndOpenFile(bytes, 'trend_analysis_${DateTime.now().millisecondsSinceEpoch}.csv');
      } else {
        // PNG or SVG (fallback to PNG capture from RepaintBoundary)
        final bytes = await _captureChart();
        if (bytes != null) {
          await saveAndOpenFile(bytes, 'trend_analysis_${DateTime.now().millisecondsSinceEpoch}.${type == 'svg' ? 'png' : type}');
        } else {
          throw "Could not capture chart image";
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.toUpperCase()} downloaded successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download ${type.toUpperCase()}: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<Uint8List?> _captureChart() async {
    try {
      RenderRepaintBoundary? boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Capture error: $e');
      return null;
    }
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
        return _buildWaterfallChart();
      case 'radar':
        return _buildRadarChart();
      case 'candlestick':
        return _buildCandlestickChart();
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
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: colors[i % colors.length],
              strokeWidth: 0,
            ),
          ),
          belowBarData: BarAreaData(
            show: isArea,
            color: colors[i % colors.length].withOpacity(0.05),
          ),
        ));
      }
    }

    return LineChart(_getLineChartData(lineBars, xLabels));
  }

  LineChartData _getLineChartData(List<LineChartBarData> lineBars, List<String> xLabels) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate dynamic range
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    bool hasData = false;

    for (var bar in lineBars) {
      for (var spot in bar.spots) {
        if (spot.y < minY) minY = spot.y;
        if (spot.y > maxY) maxY = spot.y;
        hasData = true;
      }
    }

    if (!hasData) {
      minY = 0;
      maxY = 100;
    } else {
      double range = maxY - minY;
      if (range == 0) {
        minY -= 5;
        maxY += 5;
      } else {
        // Add 15% padding to bottom and 25% to top for tooltip space
        minY -= range * 0.15;
        maxY += range * 0.25;
      }
    }

    // Dynamic interval: try to have about 5 horizontal lines
    double interval = (maxY - minY) / 5;
    if (interval <= 0) interval = 1;

    return LineChartData(
      clipData: FlClipData.all(),
      lineBarsData: lineBars,
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Tighter padding
          maxContentWidth: 150, // More fit width
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipBorder: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return [];
            
            // Get the period label for the header
            final periodIndex = touchedSpots.first.x.toInt();
            String headerText = '';
            if (periodIndex >= 0 && periodIndex < xLabels.length) {
              headerText = xLabels[periodIndex];
            }

            // Consolidate all values into the first item
            final consolidatedItem = LineTooltipItem(
              '$headerText\n', 
              TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              children: touchedSpots.map((spot) {
                final ratio = widget.selectedRatios[spot.barIndex];
                final colors = [
                  const Color(0xFF3B82F6),
                  const Color(0xFF10B981),
                  const Color(0xFFF59E0B),
                  const Color(0xFFEF4444),
                  const Color(0xFF8B5CF6),
                  const Color(0xFFEC4899),
                ];
                final color = colors[spot.barIndex % colors.length];
                final isLast = touchedSpots.indexOf(spot) == touchedSpots.length - 1;

                return TextSpan(
                  children: [
                    TextSpan(
                      text: '● ',
                      style: TextStyle(color: color, fontSize: 10),
                    ),
                    TextSpan(
                      text: '${_formatRatioName(ratio)}: ',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: spot.y.toStringAsFixed(2),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!isLast) const TextSpan(text: '\n'),
                  ],
                );
              }).toList(),
            );

            // Important: Return exactly the same number of items as touchedSpots.
            // Only the first one has the actual content; others are empty to suppress default pop-ups.
            return List.generate(touchedSpots.length, (i) => i == 0 ? consolidatedItem : null);
          },
        ),
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              const FlLine(
                color: Color(0xFFCBD5E1),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 5,
                  color: barData.color ?? Colors.blue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
            );
          }).toList();
        },
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) => const FlLine(
          color: Color(0xFFF1F5F9),
          strokeWidth: 1,
          dashArray: [4, 4],
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
              if (value < 0 || value >= xLabels.length || value % 1 != 0) return const SizedBox();
              
              final index = value.toInt();
              if (index >= 0 && index < xLabels.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child: Text(
                    xLabels[index],
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
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
            reservedSize: 60,
            interval: interval,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              axisSide: meta.axisSide,
              space: 12,
              child: Text(
                value.toStringAsFixed(2),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          left: const BorderSide(color: Colors.transparent), 
        ),
      ),
      minX: 0 + _xOffset,
      maxX: ((xLabels.length - 1) * _zoomScale) + _xOffset + 0.15,
      minY: minY,
      maxY: maxY,
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
                    fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
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
          show: true, 
          barWidth: 0, // Zero width makes it scatter
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

  Widget _buildRadarChart() {
    final filteredData = _getFilteredSortedData();
    if (filteredData.isEmpty) return const SizedBox();
    
    // Radar usually compares multiple series for a single unit or unit over time
    // We'll show the latest selected period as the radar snapshot
    final latestData = filteredData.last;
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    List<RadarDataSet> dataSets = [];
    
    // Series 1: The latest data
    dataSets.add(RadarDataSet(
      dataEntries: widget.selectedRatios.map((ratioKey) {
        final val = _getRatioValue(latestData, ratioKey) ?? 0.0;
        return RadarEntry(value: val.isFinite ? val : 0.0);
      }).toList(),
      fillColor: colors[0].withOpacity(0.2),
      borderColor: colors[0],
      entryRadius: 3,
      borderWidth: 2,
    ));

    return RadarChart(
      RadarChartData(
        dataSets: dataSets,
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: const BorderSide(color: Colors.transparent),
        titlePositionPercentageOffset: 0.15,
        titleTextStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
        getTitle: (index, angle) {
          if (index >= 0 && index < widget.selectedRatios.length) {
            return RadarChartTitle(text: _formatRatioName(widget.selectedRatios[index]));
          }
          return const RadarChartTitle(text: "");
        },
        tickCount: 5,
        ticksTextStyle: const TextStyle(color: Colors.grey, fontSize: 8),
        gridBorderData: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
    );
  }

  Widget _buildWaterfallChart() {
    final filteredData = _getFilteredSortedData();
    final xLabels = _getXLabels(filteredData);
    if (widget.selectedRatios.isEmpty) return const SizedBox();
    
    final ratioKey = widget.selectedRatios[0];
    List<BarChartGroupData> barGroups = [];
    double runningTotal = 0;

    for (int i = 0; i < filteredData.length; i++) {
      final val = _getRatioValue(filteredData[i], ratioKey) ?? 0.0;
      final start = runningTotal;
      final end = val; // In some waterfalls, we show the absolute value as a "Total"
      
      // For this implementation, we'll follow Apex's "Absolute values" waterfall style
      // where each bar shows the value for that period.
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            fromY: 0,
            toY: val,
            color: val >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            width: 20,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ));
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: _getBarChartTitles(xLabels),
        borderData: _getChartBorder(),
        gridData: _getChartGrid(),
      ),
    );
  }

  Widget _buildCandlestickChart() {
    final filteredData = _getFilteredSortedData();
    final xLabels = _getXLabels(filteredData);
    if (widget.selectedRatios.isEmpty) return const SizedBox();
    
    final ratioKey = widget.selectedRatios[0];
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < filteredData.length; i++) {
      final val = _getRatioValue(filteredData[i], ratioKey) ?? 0.0;
      final variance = (val * 0.05).abs(); // Simulate high/low
      
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          // Wick (High to Low)
          BarChartRodData(
            fromY: val - variance,
            toY: val + variance,
            color: Colors.grey.withOpacity(0.5),
            width: 2,
          ),
          // Body (Simulated)
          BarChartRodData(
            fromY: val - (variance / 2),
            toY: val + (variance / 4),
            color: const Color(0xFF3B82F6),
            width: 10,
            borderRadius: BorderRadius.circular(1),
          ),
        ],
      ));
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: _getBarChartTitles(xLabels),
        borderData: _getChartBorder(),
        gridData: _getChartGrid(),
      ),
    );
  }

  // Helper methods to share chart styling
  FlTitlesData _getBarChartTitles(List<String> xLabels) {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          getTitlesWidget: (value, meta) {
            if (value < 0 || value >= xLabels.length || value % 1 != 0) return const SizedBox();
            final index = value.toInt();
            if (index >= 0 && index < xLabels.length) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 8,
                fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
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
    );
  }

  FlBorderData _getChartBorder() {
    return FlBorderData(
      show: true,
      border: const Border(
        bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        left: BorderSide(color: Color(0xFFE5E7EB), width: 1),
      ),
    );
  }

  FlGridData _getChartGrid() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (value) => const FlLine(
        color: Color(0xFFE5E7EB),
        strokeWidth: 1,
        dashArray: [3, 3],
      ),
    );
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

  Widget _buildStatsSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredData = _getFilteredSortedData();

    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth > 1200 ? 4 : (screenWidth > 800 ? 2 : 1);
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 2.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: widget.selectedRatios.length,
          itemBuilder: (context, index) {
            final ratioKey = widget.selectedRatios.elementAt(index);
            final values = filteredData
                .map((d) => _getRatioValue(d, ratioKey))
                .where((v) => v != null && v.isFinite)
                .cast<double>()
                .toList();

            if (values.isEmpty) return const SizedBox();

            final latest = values.last;
            final initial = values.first;
            final change = latest - initial;
            final percentChange = initial != 0 ? (change / initial) * 100 : 0.0;
            final avg = values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
            final max = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
            final min = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatRatioName(ratioKey),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  _buildStatRow("Latest:", latest.toStringAsFixed(2), isDark, isBoldValue: true),
                  _buildStatRow(
                    "Change:", 
                    "${change >= 0 ? "+" : ""}${change.toStringAsFixed(2)} (${percentChange.toStringAsFixed(1)}%)",
                    isDark,
                    valueColor: change >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                  _buildStatRow("Avg:", avg.toStringAsFixed(2), isDark),
                  _buildStatRow("Min-Max:", "${min.toStringAsFixed(2)} - ${max.toStringAsFixed(2)}", isDark),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, bool isDark, {Color? valueColor, bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF111827)),
              fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ScatterSeries {
  final List<ScatterSpot> spots;
  ScatterSeries({required this.spots});
}