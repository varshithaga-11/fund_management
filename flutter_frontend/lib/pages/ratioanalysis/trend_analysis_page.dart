import 'package:flutter/material.dart';
import '../../financialstatements/financial_statements_api.dart';
import 'trend_analysis_chart.dart';
import 'trend_comparison_cards.dart';

class TrendAnalysisPage extends StatefulWidget {
  const TrendAnalysisPage({super.key});

  @override
  State<TrendAnalysisPage> createState() => _TrendAnalysisPageState();
}

class _TrendAnalysisPageState extends State<TrendAnalysisPage> {
  List<FinancialPeriodData> _periods = [];
  List<FinancialPeriodData> _selectedPeriodObjects = [];
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
      
      // Filter out nulls
      final ratiosData = ratiosResults.whereType<RatioResultData>().toList();

      if (mounted) {
        setState(() {
          _periods = periods;
          _selectedPeriodObjects = periods; // Select all by default
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

  void _onPeriodSelectionChanged(bool? selected, FinancialPeriodData period) {
    if (selected == true) {
      setState(() {
        _selectedPeriodObjects.add(period);
        // Resort based on original list
        _selectedPeriodObjects.sort((a, b) => 
            _periods.indexOf(a).compareTo(_periods.indexOf(b)));
      });
    } else {
      setState(() {
        _selectedPeriodObjects.removeWhere((p) => p.id == period.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trend Analysis'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Period Selection
                      Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Select Periods for Graph', 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _periods.map((period) {
                                  final isSelected = _selectedPeriodObjects.any((p) => p.id == period.id);
                                  return FilterChip(
                                    label: Text(period.label),
                                    selected: isSelected,
                                    onSelected: (val) => _onPeriodSelectionChanged(val, period),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Chart
                      if (_ratiosData.isNotEmpty && _selectedPeriodObjects.isNotEmpty)
                        TrendAnalysisChart(
                          ratioData: _ratiosData,
                          periods: _selectedPeriodObjects,
                          selectedRatios: _selectedRatios,
                          onSelectedRatiosChange: (ratios) => 
                              setState(() => _selectedRatios = ratios),
                        ),

                      const SizedBox(height: 32),
                      
                      // Comparisons
                      if (_ratiosData.isNotEmpty && _selectedPeriodObjects.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Yearly Comparison', 
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text('Analysis of ratio changes across financial years',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            TrendComparisonCards(
                              ratioData: _ratiosData,
                              periods: _selectedPeriodObjects,
                              selectedRatios: _selectedRatios,
                            ),
                          ],
                        ),

                      if (_ratiosData.isEmpty)
                         const Center(child: Text('No ratio data available for the selected periods')),
                    ],
                  ),
                ),
    );
  }
}
