import 'package:flutter/material.dart';
import '../../theme/responsive_helper.dart';
import '../financialstatements/financial_statements_api.dart';
import 'trend_analysis_chart.dart';
import 'trend_comparison_cards.dart';

class TrendAnalysisPage extends StatefulWidget {
  const TrendAnalysisPage({super.key});

  @override
  State<TrendAnalysisPage> createState() => _TrendAnalysisPageState();
}

class _TrendAnalysisPageState extends State<TrendAnalysisPage> {
  List<FinancialPeriodData> _periods = [];
  List<RatioResultData> _ratiosData = [];
  List<String> _selectedRatios = [
    'gross_profit_ratio',
    'net_profit_ratio',
    'stock_turnover'
  ];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final periods = await getFinancialPeriods();
      // Sort periods by start date
      periods.sort((a, b) {
        final dateA = DateTime.parse(a.startDate);
        final dateB = DateTime.parse(b.startDate);
        return dateA.compareTo(dateB);
      });

      if (periods.isEmpty) {
        setState(() {
          _loading = false;
          _periods = [];
        });
        return;
      }

      // Fetch ratios for all periods
      final ratiosFutures = periods.map((p) => getRatioResults(p.id));
      final ratiosResults = await Future.wait(ratiosFutures);
      
      final ratiosData = ratiosResults.whereType<RatioResultData>().toList();

      if (mounted) {
        setState(() {
          _periods = periods;
          _ratiosData = ratiosData;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.isDesktop(context) ? 32 : 16,
                    vertical: 32,
                  ),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                child: const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_back, color: Color(0xFF2563EB), size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Back',
                                        style: TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.trending_up, size: 32, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Trend Analysis',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Error Message
                          if (_error != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: isDark ? Colors.redAccent : Colors.red.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                          if (_error == null) ...[
                            if (_ratiosData.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.1) : const Color(0xFFEFF6FF),
                                  border: Border.all(color: isDark ? const Color(0xFF1E40AF).withOpacity(0.3) : const Color(0xFFBFDBFE)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'No Periods Available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Upload financial data to see trend analysis.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              TrendAnalysisChart(
                                ratioData: _ratiosData,
                                periods: _periods,
                                selectedRatios: _selectedRatios,
                                onSelectedRatiosChange: (ratios) => setState(() => _selectedRatios = ratios),
                              ),
                              const SizedBox(height: 48),

                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6), width: 1),
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
                                      'Yearly Comparison',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Analysis of ratio changes across financial years',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    TrendComparisonCards(
                                      ratioData: _ratiosData,
                                      periods: _periods,
                                      selectedRatios: _selectedRatios,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
