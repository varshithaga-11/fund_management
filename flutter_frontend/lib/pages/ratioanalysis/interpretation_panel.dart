import 'package:flutter/material.dart';
import '../../financialstatements/financial_statements_api.dart';

class InterpretationPanelPage extends StatefulWidget {
  final int periodId;

  const InterpretationPanelPage({super.key, required this.periodId});

  @override
  State<InterpretationPanelPage> createState() =>
      _InterpretationPanelPageState();
}

class _InterpretationPanelPageState extends State<InterpretationPanelPage> {
  RatioResultData? _ratios;
  FinancialPeriodData? _period;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        getRatioResults(widget.periodId),
        getFinancialPeriod(widget.periodId),
      ]);
      
      if (mounted) {
        setState(() {
          _ratios = results[0] as RatioResultData?;
          _period = results[1] as FinancialPeriodData?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
        setState(() => _loading = false);
      }
    }
  }

  List<String> _getKeyInsights(RatioResultData ratios) {
    List<String> insights = [];

    // Credit Deposit Ratio
    if (ratios.creditDepositRatio > 70) {
      insights.add('✓ High efficiency in deploying resources');
    } else {
      insights.add('⚠ Under-utilization of mobilized deposits');
    }

    // Cost effectiveness
    if (ratios.costOfDeposits > 0 &&
        ratios.yieldOnLoans > 0 &&
        ratios.costOfDeposits < ratios.yieldOnLoans - 4) {
      insights.add('✓ Cost-effective deposit management');
    } else {
      insights.add('⚠ Deposit costs are relatively high compared to loan yields');
    }

    // Net Margin
    if (ratios.netMargin >= 1.0) {
      insights.add('✓ Healthy profitability');
    } else if (ratios.netMargin >= 0.5) {
      insights.add('⚠ Moderate profitability - room for improvement');
    } else {
      insights.add('✗ Low profitability - requires immediate attention');
    }

    // Risk Cost
    if (ratios.riskCostToWf > 0.25) {
      insights.add('✗ High risk exposure - review provisions');
    } else if (ratios.riskCostToWf > 0.15) {
      insights.add('⚠ Moderate risk exposure');
    } else {
      insights.add('✓ Low risk exposure');
    }

    // Stock Turnover
    if (ratios.stockTurnover >= 15) {
      insights.add('✓ Good inventory management');
    } else if (ratios.stockTurnover >= 10) {
      insights.add('⚠ Adequate inventory turnover');
    } else {
      insights.add('✗ Low inventory turnover - review stock management');
    }

    // Fund Structure
    if (ratios.loansToWf < 70) {
      insights.add('⚠ Loans deployment below optimal level');
    } else if (ratios.loansToWf > 75) {
      insights.add('⚠ High loan deployment - ensure adequate liquidity');
    }

    return insights;
  }

  List<String> _getRecommendations(RatioResultData ratios) {
    List<String> recommendations = [];

    if (ratios.netMargin < 1.0) {
      recommendations.add(
          'Focus on improving net margin by reducing operating costs or increasing income');
    }

    if (ratios.riskCostToWf > 0.25) {
      recommendations.add('Review and optimize provisions to reduce risk cost');
    }

    if (ratios.creditDepositRatio < 70) {
      recommendations.add('Increase loan deployment to improve credit deposit ratio');
    }

    if (ratios.stockTurnover < 15) {
      recommendations.add('Improve inventory management to increase stock turnover');
    }

    if (ratios.operatingCostToWf > 2.5) {
      recommendations.add(
          'Review operating expenses to reduce operating cost to working fund ratio');
    }

    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_ratios == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Interpretation Analysis')),
        body: const Center(
          child: Text(
            'No ratio data found. Please calculate ratios first.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final insights = _getKeyInsights(_ratios!);
    final recommendations = _getRecommendations(_ratios!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interpretation Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_period != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _period!.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),

            // AI Interpretation
            if (_ratios!.interpretation != null &&
                _ratios!.interpretation!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Summary Interpretation',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _ratios!.interpretation!,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),

            // Key Insights
            if (insights.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Key Insights',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...insights.map((insight) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(insight, style: const TextStyle(fontSize: 14)),
                          )),
                    ],
                  ),
                ),
              ),

            // Recommendations
            if (recommendations.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recommendations',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...recommendations.map((rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Expanded(
                                  child: Text(rec,
                                      style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

            // Risk Warnings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Risk Warnings',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_ratios!.riskCostToWf > 0.25)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '⚠ High risk cost (${_ratios!.riskCostToWf.toStringAsFixed(2)}%) exceeds ideal threshold (0.25%)',
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  if (_ratios!.netMargin < 0.5)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '⚠ Net margin (${_ratios!.netMargin.toStringAsFixed(2)}%) is critically low',
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  if (_ratios!.creditDepositRatio < 50)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '⚠ Very low credit deposit ratio (${_ratios!.creditDepositRatio.toStringAsFixed(2)}%) indicates poor resource utilization',
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  if (!(_ratios!.riskCostToWf > 0.25 ||
                      _ratios!.netMargin < 0.5 ||
                      _ratios!.creditDepositRatio < 50))
                    const Text('No critical risk warnings at this time',
                        style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
