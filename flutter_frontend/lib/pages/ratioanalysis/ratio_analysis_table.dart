import 'package:flutter/material.dart';
import '../../financialstatements/financial_statements_api.dart';

class RatioAnalysisTable extends StatelessWidget {
  final RatioResultData ratios;
  final String? periodLabel;

  const RatioAnalysisTable({
    super.key,
    required this.ratios,
    this.periodLabel,
  });

  List<Map<String, dynamic>> get _categories => [
        {
          'title': 'Trading Ratios',
          'items': [
            {'label': 'Stock Turnover', 'value': ratios.stockTurnover, 'unit': 'times'},
            {'label': 'Gross Profit Ratio', 'value': ratios.grossProfitRatio, 'unit': '%'},
            {'label': 'Net Profit Ratio', 'value': ratios.netProfitRatio, 'unit': '%'},
          ],
        },
        {
          'title': 'Capital Efficiency',
          'items': [
            {'label': 'Capital Turnover Ratio', 'value': ratios.capitalTurnoverRatio, 'unit': 'times'},
          ],
        },
        {
          'title': 'Fund Structure Ratios',
          'items': [
            {'label': 'Net Own Funds', 'value': ratios.netOwnFunds, 'unit': ''},
            {'label': 'Own Fund to Working Fund', 'value': ratios.ownFundToWf, 'unit': '%'},
            {'label': 'Deposits to Working Fund', 'value': ratios.depositsToWf, 'unit': '%'},
            {'label': 'Borrowings to Working Fund', 'value': ratios.borrowingsToWf, 'unit': '%'},
            {'label': 'Loans to Working Fund', 'value': ratios.loansToWf, 'unit': '%'},
            {'label': 'Investments to Working Fund', 'value': ratios.investmentsToWf, 'unit': '%'},
            {'label': 'Earning Assets to Working Fund', 'value': ratios.earningAssetsToWf, 'unit': '%'},
            {
              'label': 'Interest Tagged Funds to Working Fund',
              'value': ratios.interestTaggedFundsToWf,
              'unit': '%'
            },
          ],
        },
        {
          'title': 'Yield & Cost Ratios',
          'items': [
            {'label': 'Cost of Deposits', 'value': ratios.costOfDeposits, 'unit': '%'},
            {'label': 'Yield on Loans', 'value': ratios.yieldOnLoans, 'unit': '%'},
            {'label': 'Yield on Investments', 'value': ratios.yieldOnInvestments, 'unit': '%'},
            {'label': 'Credit Deposit Ratio', 'value': ratios.creditDepositRatio, 'unit': '%'},
            {'label': 'Avg Cost of Working Fund', 'value': ratios.avgCostOfWf, 'unit': '%'},
            {'label': 'Avg Yield on Working Fund', 'value': ratios.avgYieldOnWf, 'unit': '%'},
            {'label': 'Miscellaneous Income to WF', 'value': ratios.miscIncomeToWf, 'unit': '%'},
            {
              'label': 'Interest Expenses to Interest Income',
              'value': ratios.interestExpToInterestIncome,
              'unit': '%'
            },
          ],
        },
        {
          'title': 'Margin Ratios',
          'items': [
            {'label': 'Gross Financial Margin', 'value': ratios.grossFinMargin, 'unit': '%'},
            {'label': 'Operating Cost to Working Fund', 'value': ratios.operatingCostToWf, 'unit': '%'},
            {'label': 'Net Financial Margin', 'value': ratios.netFinMargin, 'unit': '%'},
            {'label': 'Risk Cost to Working Fund', 'value': ratios.riskCostToWf, 'unit': '%'},
            {'label': 'Net Margin', 'value': ratios.netMargin, 'unit': '%'},
          ],
        },
        {
          'title': 'Productivity Ratios',
          'items': [
            {'label': 'Per Employee Deposit', 'value': ratios.perEmployeeDeposit, 'unit': ' Lakhs'},
            {'label': 'Per Employee Loan', 'value': ratios.perEmployeeLoan, 'unit': ' Lakhs'},
            {
              'label': 'Per Employee Contribution',
              'value': ratios.perEmployeeContribution,
              'unit': ' Lakhs'
            },
            {
              'label': 'Per Employee Operating Cost',
              'value': ratios.perEmployeeOperatingCost,
              'unit': ' Lakhs'
            },
          ],
        },
      ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              'Ratio Analysis Table${periodLabel != null ? ' - $periodLabel' : ''}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ..._categories.map((category) => _buildCategorySection(category)),
        ],
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    List<Map<String, dynamic>> items =
        category['items'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade50,
          child: Text(
            category['title'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        ...items.map((item) => _buildRow(item)),
      ],
    );
  }

  Widget _buildRow(Map<String, dynamic> item) {
    dynamic value = item['value'];
    String displayValue = '-';
    if (value != null) {
      if (value is num) {
        displayValue = value.toStringAsFixed(2);
      } else {
        displayValue = value.toString();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item['label'] as String,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '$displayValue ${item['unit']}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
