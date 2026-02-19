import 'package:flutter/material.dart';

import 'api.dart';
import 'financial_statements_api.dart' show RatioResultData; // Accessing shared models
import 'trend_analysis_chart.dart';
import 'period_data_edit_form.dart';

class CompanyRatioAnalysisPage extends StatefulWidget {
  const CompanyRatioAnalysisPage({super.key});

  @override
  State<CompanyRatioAnalysisPage> createState() => _CompanyRatioAnalysisPageState();
}

class _CompanyRatioAnalysisPageState extends State<CompanyRatioAnalysisPage> {
  List<PeriodWithRatiosData> periods = [];
  PeriodWithRatiosData? selectedPeriod;
  RatioResultData? ratios;
  List<Map<String, dynamic>> ratioTrends = [];
  bool showTrendAnalysis = false;
  bool loading = true;
  bool loadingTrends = false;

  @override
  void initState() {
    super.initState();
    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    setState(() => loading = true);
    try {
      final data = await getPeriodsList();
      setState(() {
        periods = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load periods')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _handleViewTrendAnalysis() async {
    final periodsWithRatios = periods.where((p) => p.ratios != null).toList();
    if (periodsWithRatios.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least 2 periods with ratios required')));
      return;
    }

    setState(() => loadingTrends = true);
    try {
      final trends = await getRatioTrends();
      setState(() {
        ratioTrends = trends;
        showTrendAnalysis = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load trends')));
    } finally {
      if (mounted) setState(() => loadingTrends = false);
    }
  }

  void _handleSelectPeriod(PeriodWithRatiosData period) async {
    setState(() {
      selectedPeriod = period;
      ratios = period.ratios; // Ratios are included in listing usually
    });
    // In original code, it falls back to API if null, we can add that logic if needed
    if (ratios == null) {
       // Ideally fetch specific ratio result here if not present
    }
  }

  void _handleBack() {
    setState(() {
      selectedPeriod = null;
      showTrendAnalysis = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ratio Analysis'),
        leading: (selectedPeriod != null || showTrendAnalysis)
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _handleBack)
          : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (showTrendAnalysis) {
      return SingleChildScrollView(
        child: Column(
          children: [
            TrendAnalysisChart(ratioData: ratioTrends, periods: periods),
          ],
        ),
      );
    }

    if (selectedPeriod != null) {
      // Detail View
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(selectedPeriod!.label, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            
            if (ratios == null)
              const Card(color: Colors.redAccent, child: Padding(padding: EdgeInsets.all(16), child: Text("No ratios generated yet.", style: TextStyle(color: Colors.white))))
            else
              _buildRatioGrid(ratios!),
            
            const Divider(height: 32),
            const Text("Edit Data & Recalculate", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            PeriodDataEditForm(
              periodId: selectedPeriod!.id,
              onSuccess: () async {
                // Refresh logic - simplified re-fetch all
                await _loadPeriods();
                // Re-select current if found
                final updated = periods.firstWhere((p) => p.id == selectedPeriod!.id, orElse: () => selectedPeriod!);
                _handleSelectPeriod(updated);
              },
            ),
          ],
        ),
      );
    }

    // List View
    return Column(
      children: [
        if (periods.any((p) => p.ratios != null))
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: loadingTrends ? null : _handleViewTrendAnalysis,
              icon: const Icon(Icons.show_chart),
              label: const Text("View Trends"),
            ),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: periods.isEmpty 
          ? const Center(child: Text("No periods found"))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16
              ),
              itemCount: periods.length,
              itemBuilder: (context, index) {
                final p = periods[index];
                return Card(
                  child: InkWell(
                    onTap: () => _handleSelectPeriod(p),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          Text(p.periodType),
                          Text(p.startDate),
                          // Chip for status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: p.isFinalized ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(
                              p.isFinalized ? "Finalized" : "Draft",
                              style: TextStyle(fontSize: 10, color: p.isFinalized ? Colors.green : Colors.black54),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ),
      ],
    );
  }

  Widget _buildRatioGrid(RatioResultData r) {
    // Helper to display a single ratio card
    Widget ratioCard(String title, double? value, {String unit = ""}) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                "${value?.toStringAsFixed(2) ?? '-'} $unit",
                style: const TextStyle(fontSize: 16, color: Colors.blue),
              )
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Working Fund
        Card(
          color: Colors.blue.shade50,
          child: ListTile(
            title: const Text("Working Fund"),
            trailing: Text("₹${r.workingFund?.toStringAsFixed(2) ?? '0.00'}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        ),
        
        // Sections
        const SizedBox(height: 16),
        const Text("Trading Ratios", style: TextStyle(fontWeight: FontWeight.bold)),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          children: [
            ratioCard("Stock Turnover", r.stockTurnover, unit: "times"),
            ratioCard("Gross Profit", r.grossProfitRatio, unit: "%"),
            ratioCard("Net Profit", r.netProfitRatio, unit: "%"),
          ],
        ),

        const SizedBox(height: 16),
        const Text("Capital Ratios", style: TextStyle(fontWeight: FontWeight.bold)),
         GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          children: [
             ratioCard("Capital Ratio", r.ownFundToWf, unit: "%"),
          ],
        ),

        // ... Add other sections similarly as needed
      ],
    );
  }
}
