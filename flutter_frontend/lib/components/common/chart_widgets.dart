import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_helper.dart';

// Revenue vs Profit Chart
class RevenueChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> periods; // Full period data
  final bool isDark;

  const RevenueChartWidget({
    Key? key,
    required this.periods,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get last 10 periods sorted by created_at
    final last10 = _getLast10Periods();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue & Profit Analysis',
          style: AppTypography.h5.copyWith(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              maxY: _getMaxY(last10),
              barGroups: _buildBarGroups(last10),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < last10.length) {
                        return Padding(
                          padding: EdgeInsets.only(top: AppSpacing.md),
                          child: Transform.rotate(
                            angle: -0.785, // -45 degrees
                            child: Text(
                              last10[index]['label'] ?? 'Period',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.gray400 : AppColors.gray600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Amount (₹)',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '₹${(value / 1000).toStringAsFixed(0)}K',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.gray400 : AppColors.gray600,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: _getMaxY(last10) / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: isDark ? AppColors.gray700 : AppColors.gray200,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  );
                },
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChartLegendItem('Net Profit', Color(0xFF3C50E0)),
            SizedBox(width: AppSpacing.xl),
            _buildChartLegendItem('Revenue', Color(0xFF80CAEE)),
          ],
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getLast10Periods() {
    if (periods.isEmpty) return [];
    
    // Sort by created_at and take last 10
    final sorted = [...periods]
        .where((p) => p['profit_loss'] != null && p['trading_account'] != null)
        .toList()
        ..sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at'] ?? '2000-01-01') ?? DateTime(2000);
          final dateB = DateTime.tryParse(b['created_at'] ?? '2000-01-01') ?? DateTime(2000);
          return dateA.compareTo(dateB);
        });
    
    return sorted.length > 10 ? sorted.sublist(sorted.length - 10) : sorted;
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 100000;
    
    double maxVal = 0;
    for (var period in data) {
      final profit = period['profit_loss']?['net_profit'] ?? 0;
      final revenue = period['trading_account']?['sales'] ?? 0;
      final profitNum = profit is String ? double.tryParse(profit) ?? 0 : (profit ?? 0).toDouble();
      final revenueNum = revenue is String ? double.tryParse(revenue) ?? 0 : (revenue ?? 0).toDouble();
      maxVal = [maxVal, profitNum, revenueNum].reduce((a, b) => a > b ? a : b);
    }
    
    return maxVal == 0 ? 100000 : (maxVal * 1.2);
  }

  List<BarChartGroupData> _buildBarGroups(List<Map<String, dynamic>> data) {
    final groups = <BarChartGroupData>[];
    
    for (int i = 0; i < data.length; i++) {
      final period = data[i];
      final profit = period['profit_loss']?['net_profit'] ?? 0;
      final revenue = period['trading_account']?['sales'] ?? 0;
      
      final profitNum = profit is String ? double.tryParse(profit) ?? 0 : (profit ?? 0).toDouble();
      final revenueNum = revenue is String ? double.tryParse(revenue) ?? 0 : (revenue ?? 0).toDouble();
      
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: profitNum,
              color: Color(0xFF3C50E0),
              width: 8,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
            ),
            BarChartRodData(
              toY: revenueNum,
              color: Color(0xFF80CAEE),
              width: 8,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
            ),
          ],
        ),
      );
    }
    return groups;
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.body3.copyWith(
            color: isDark ? AppColors.gray300 : AppColors.gray700,
          ),
        ),
      ],
    );
  }
}

// Period Distribution Pie Chart
class PeriodDistributionChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> periods;
  final bool isDark;

  const PeriodDistributionChartWidget({
    Key? key,
    required this.periods,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Count period types
    final periodTypeCounts = _getPeriodTypeCounts();
    final totalPeriods = periods.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Period Distribution',
          style: AppTypography.h5.copyWith(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        if (periodTypeCounts.isEmpty)
          SizedBox(
            height: 250,
            child: Center(
              child: Text(
                'No data available',
                style: AppTypography.body2.copyWith(
                  color: isDark ? AppColors.gray400 : AppColors.gray600,
                ),
              ),
            ),
          )
        else
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: _buildDonutSections(periodTypeCounts, totalPeriods),
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                  ),
                ),
              ),
              // Center text showing total periods
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalPeriods.toString(),
                    style: AppTypography.h2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Periods',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Map<String, int> _getPeriodTypeCounts() {
    final counts = <String, int>{};
    for (var period in periods) {
      final type = (period['period_type'] ?? 'UNKNOWN').toString().replaceAll('_', ' ');
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  List<PieChartSectionData> _buildDonutSections(Map<String, int> counts, int total) {
    final colors = [
      Color(0xFF3C50E0),
      Color(0xFF80CAEE),
      Color(0xFF0FADCF),
      Color(0xFF6577F3),
    ];

    final entries = counts.entries.toList();
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final mapEntry = entry.value;
      final percentage = (mapEntry.value / total) * 100;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: percentage,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        titleStyle: AppTypography.caption.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
        radius: 50,
      );
    }).toList();
  }
}

// Ratio Trend Chart
class RatioTrendChartWidget extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final bool isDark;
  final String title;

  const RatioTrendChartWidget({
    Key? key,
    required this.labels,
    required this.values,
    required this.isDark,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h4.copyWith(
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          if (values.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No data available',
                  style: AppTypography.body2.copyWith(
                    color: isDark ? AppColors.gray400 : AppColors.gray600,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  maxY: _getMaxY(),
                  minY: _getMinY(),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: (_getMaxY() - _getMinY()) / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark
                            ? AppColors.gray700
                            : AppColors.gray200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < labels.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: AppSpacing.md),
                              child: Text(
                                labels[index],
                                style: AppTypography.caption.copyWith(
                                  color: isDark
                                      ? AppColors.gray400
                                      : AppColors.gray600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.gray400
                                  : AppColors.gray600,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildSpots(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: isDark
                                ? AppColors.darkBg
                                : AppColors.white,
                          );
                        },
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

  double _getMaxY() {
    if (values.isEmpty) return 100;
    return values.reduce((a, b) => a > b ? a : b) * 1.1;
  }

  double _getMinY() {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a < b ? a : b) * 0.9;
  }

  List<FlSpot> _buildSpots() {
    return values
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
  }
}
