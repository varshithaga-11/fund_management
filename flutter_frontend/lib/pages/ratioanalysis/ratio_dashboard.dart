import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../routes/route_constants.dart';
import '../financialstatements/financial_statements_api.dart';
import 'ratio_card.dart';
import 'ratio_analysis_table.dart';
import '../companyratioanalysis/period_data_edit_form.dart';
import 'dart:convert' show utf8;
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ─── Page ────────────────────────────────────────────────────────────────────

class RatioDashboardPage extends StatefulWidget {
  final int periodId;
  const RatioDashboardPage({super.key, required this.periodId});

  @override
  State<RatioDashboardPage> createState() => _RatioDashboardPageState();
}

class _RatioDashboardPageState extends State<RatioDashboardPage> {
  RatioResultData? _ratios;
  FinancialPeriodData? _period;
  bool _loading = true;
  String _viewMode = 'cards'; // 'cards' | 'table'
  String _userRole = '';
  bool _showExportMenu = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadData();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _userRole = prefs.getString('userRole') ?? '');
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
        setState(() => _loading = false);
      }
    }
  }

  // Export to CSV/Excel
  Future<void> _exportToExcel() async {
    if (_ratios == null || _period == null) return;

    try {
      final buffer = StringBuffer();

      // Header
      buffer.writeln('PERIOD ANALYSIS REPORT');
      buffer.writeln('');
      buffer.writeln('Period Label,${_period!.label}');
      buffer.writeln('Period Type,${_period!.periodType}');
      buffer.writeln('Start Date,${_period!.startDate}');
      buffer.writeln('End Date,${_period!.endDate}');
      buffer.writeln('');

      // Key Metrics
      buffer.writeln('WORKING FUND');
      buffer.writeln('Amount,${_ratios!.workingFund}');
      buffer.writeln('');

      // Trading Ratios
      buffer.writeln('TRADING RATIOS');
      buffer.writeln('Metric,Value,Unit,Status');
      buffer.writeln('Stock Turnover,${_ratios!.stockTurnover},times,${_ratios!.trafficLightStatus['stock_turnover'] ?? ''}');
      buffer.writeln('Gross Profit Ratio,${_ratios!.grossProfitRatio},%,${_ratios!.trafficLightStatus['gross_profit_ratio'] ?? ''}');
      buffer.writeln('Net Profit Ratio,${_ratios!.netProfitRatio},%,${_ratios!.trafficLightStatus['net_profit_ratio'] ?? ''}');
      buffer.writeln('');

      // Fund Structure
      buffer.writeln('FUND STRUCTURE RATIOS');
      buffer.writeln('Metric,Value,Status');
      buffer.writeln('Own Fund to WF,${_ratios!.ownFundToWf},%,${_ratios!.trafficLightStatus['own_fund_to_wf'] ?? ''}');
      buffer.writeln('Deposits to WF,${_ratios!.depositsToWf},%,${_ratios!.trafficLightStatus['deposits_to_wf'] ?? ''}');
      buffer.writeln('Borrowings to WF,${_ratios!.borrowingsToWf},%,${_ratios!.trafficLightStatus['borrowings_to_wf'] ?? ''}');
      buffer.writeln('Loans to WF,${_ratios!.loansToWf},%,${_ratios!.trafficLightStatus['loans_to_wf'] ?? ''}');
      buffer.writeln('');

      // Yield & Cost Ratios
      buffer.writeln('YIELD & COST RATIOS');
      buffer.writeln('Metric,Value,Status');
      buffer.writeln('Cost of Deposits,${_ratios!.costOfDeposits},%,${_ratios!.trafficLightStatus['cost_of_deposits'] ?? ''}');
      buffer.writeln('Yield on Loans,${_ratios!.yieldOnLoans},%,${_ratios!.trafficLightStatus['yield_on_loans'] ?? ''}');
      buffer.writeln('Credit Deposit Ratio,${_ratios!.creditDepositRatio},%,${_ratios!.trafficLightStatus['credit_deposit_ratio'] ?? ''}');
      buffer.writeln('');

      // Margin Ratios
      buffer.writeln('MARGIN RATIOS');
      buffer.writeln('Metric,Value,Status');
      buffer.writeln('Gross Financial Margin,${_ratios!.grossFinMargin},%,${_ratios!.trafficLightStatus['gross_fin_margin'] ?? ''}');
      buffer.writeln('Operating Cost to WF,${_ratios!.operatingCostToWf},%,${_ratios!.trafficLightStatus['operating_cost_to_wf'] ?? ''}');
      buffer.writeln('Net Financial Margin,${_ratios!.netFinMargin},%,${_ratios!.trafficLightStatus['net_fin_margin'] ?? ''}');
      buffer.writeln('');

      // For web, show share dialog to save as CSV
      final bytes = utf8.encode(buffer.toString());
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'RatioAnalysis_${_period!.label}_${DateTime.now().toIso8601String().split('T')[0]}.csv',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV file ready to save!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e')),
        );
      }
    }
  }

  // Export to PDF
  Future<void> _exportToPDF() async {
    if (_ratios == null || _period == null) return;

    try {
      final pdf = pw.Document();

      // Helper to add formatted value
      String formatValue(dynamic value) {
        if (value == null) return '-';
        if (value is double) return value.toStringAsFixed(2);
        return value.toString();
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Title
            pw.Text(
              'Ratio Analysis Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),

            // Period Info
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFDEF5FF)),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Period: ${_period!.label}',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('Type: ${_period!.periodType}',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.Text(
                      'From ${_period!.startDate} to ${_period!.endDate}',
                      style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Working Fund
            pw.Text('Working Fund',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                )),
            pw.SizedBox(height: 8),
            pw.Text('₹${formatValue(_ratios!.workingFund)}',
                style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 20),

            // Trading Ratios Table
            pw.Text('Trading Ratios',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                )),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFDEF5FF)),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Metric',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Value',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Status',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Stock Turnover'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(formatValue(_ratios!.stockTurnover)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(_ratios!.trafficLightStatus['stock_turnover'] ??
                        '-'),
                  ),
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Gross Profit Ratio'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(formatValue(_ratios!.grossProfitRatio)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(_ratios!.trafficLightStatus['gross_profit_ratio'] ??
                        '-'),
                  ),
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Net Profit Ratio'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(formatValue(_ratios!.netProfitRatio)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                        _ratios!.trafficLightStatus['net_profit_ratio'] ?? '-'),
                  ),
                ]),
              ],
            ),
          ],
        ),
      );

      // Print/Download
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'RatioAnalysis_${_period!.label}_${DateTime.now().toIso8601String().split('T')[0]}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(strokeWidth: 3),
              SizedBox(height: 16),
              Text('Loading ratios…',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_ratios == null || _period == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              const Text('Ratios Not Calculated Yet',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                  'Financial ratio analysis hasn\'t been calculated for this period.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final calculatedDate =
        DateTime.parse(_ratios!.calculatedAt).toLocal().toString().split(' ')[0];

    // ── ratio groups (matching React) ────────────────────────────────────────

    final tradingRatios = [
      RatioCard(name: 'Stock Turnover', value: _ratios!.stockTurnover, unit: 'times', idealValue: 15.0, status: _ratios!.trafficLightStatus['stock_turnover']),
      RatioCard(name: 'Gross Profit Ratio', value: _ratios!.grossProfitRatio, unit: '%', idealValue: 10.0, status: _ratios!.trafficLightStatus['gross_profit_ratio']),
      RatioCard(name: 'Net Profit Ratio', value: _ratios!.netProfitRatio, unit: '%', status: _ratios!.trafficLightStatus['net_profit_ratio']),
    ];

    final capitalEfficiencyRatios = [
      RatioCard(name: 'Capital Turnover Ratio', value: _ratios!.capitalTurnoverRatio ?? 0, unit: 'times', idealValue: 6.0, status: _ratios!.trafficLightStatus['capital_turnover_ratio']),
    ];

    final fundStructureRatios = [
      RatioCard(name: 'Net Own Funds', value: _ratios!.netOwnFunds ?? 0, unit: '', status: (_ratios!.netOwnFunds != null && _ratios!.netOwnFunds! > 0) ? 'green' : 'red'),
      RatioCard(name: 'Own Fund to Working Fund', value: _ratios!.ownFundToWf, unit: '%', idealValue: 8.0, status: _ratios!.trafficLightStatus['own_fund_to_wf']),
      RatioCard(name: 'Deposits to Working Fund', value: _ratios!.depositsToWf, unit: '%', status: _ratios!.trafficLightStatus['deposits_to_wf']),
      RatioCard(name: 'Borrowings to Working Fund', value: _ratios!.borrowingsToWf, unit: '%', status: _ratios!.trafficLightStatus['borrowings_to_wf']),
      RatioCard(name: 'Loans to Working Fund', value: _ratios!.loansToWf, unit: '%', idealValue: 70.0, status: _ratios!.trafficLightStatus['loans_to_wf']),
      RatioCard(name: 'Investments to Working Fund', value: _ratios!.investmentsToWf, unit: '%', idealValue: 25.0, status: _ratios!.trafficLightStatus['investments_to_wf']),
      RatioCard(name: 'Earning Assets to Working Fund', value: _ratios!.earningAssetsToWf ?? 0, unit: '%', idealValue: 80.0, status: _ratios!.trafficLightStatus['earning_assets_to_wf']),
      RatioCard(name: 'Interest Tagged Funds to WF', value: _ratios!.interestTaggedFundsToWf ?? 0, unit: '%', status: _ratios!.trafficLightStatus['interest_tagged_funds_to_wf']),
    ];

    final yieldCostRatios = [
      RatioCard(name: 'Cost of Deposits', value: _ratios!.costOfDeposits, unit: '%', status: _ratios!.trafficLightStatus['cost_of_deposits']),
      RatioCard(name: 'Yield on Loans', value: _ratios!.yieldOnLoans, unit: '%', status: _ratios!.trafficLightStatus['yield_on_loans']),
      RatioCard(name: 'Yield on Investments', value: _ratios!.yieldOnInvestments, unit: '%', status: _ratios!.trafficLightStatus['yield_on_investments']),
      RatioCard(name: 'Credit Deposit Ratio', value: _ratios!.creditDepositRatio, unit: '%', idealValue: 70.0, status: _ratios!.trafficLightStatus['credit_deposit_ratio']),
      RatioCard(name: 'Avg Cost of Working Fund', value: _ratios!.avgCostOfWf, unit: '%', idealValue: 3.5, status: _ratios!.trafficLightStatus['avg_cost_of_wf']),
      RatioCard(name: 'Avg Yield on Working Fund', value: _ratios!.avgYieldOnWf, unit: '%', idealValue: 3.5, status: _ratios!.trafficLightStatus['avg_yield_on_wf']),
      RatioCard(name: 'Miscellaneous Income to WF', value: _ratios!.miscIncomeToWf ?? 0, unit: '%', idealValue: 0.5, status: _ratios!.trafficLightStatus['misc_income_to_wf']),
      RatioCard(name: 'Interest Expenses to Interest Income', value: _ratios!.interestExpToInterestIncome ?? 0, unit: '%', idealValue: 62.0, status: _ratios!.trafficLightStatus['interest_exp_to_interest_income']),
    ];

    final marginRatios = [
      RatioCard(name: 'Gross Financial Margin', value: _ratios!.grossFinMargin, unit: '%', idealValue: 3.5, status: _ratios!.trafficLightStatus['gross_fin_margin']),
      RatioCard(name: 'Operating Cost to Working Fund', value: _ratios!.operatingCostToWf, unit: '%', idealValue: 2.5, status: _ratios!.trafficLightStatus['operating_cost_to_wf']),
      RatioCard(name: 'Net Financial Margin', value: _ratios!.netFinMargin, unit: '%', idealValue: 1.5, status: _ratios!.trafficLightStatus['net_fin_margin']),
      RatioCard(name: 'Risk Cost to Working Fund', value: _ratios!.riskCostToWf, unit: '%', idealValue: 0.25, status: _ratios!.trafficLightStatus['risk_cost_to_wf']),
      RatioCard(name: 'Net Margin', value: _ratios!.netMargin, unit: '%', idealValue: 1.0, status: _ratios!.trafficLightStatus['net_margin']),
    ];

    final productivityRatios = [
      RatioCard(name: 'Per Employee Deposit', value: _ratios!.perEmployeeDeposit ?? 0, unit: ' Lakhs', idealValue: 200.0, status: _ratios!.trafficLightStatus['per_employee_deposit']),
      RatioCard(name: 'Per Employee Loan', value: _ratios!.perEmployeeLoan ?? 0, unit: ' Lakhs', idealValue: 150.0, status: _ratios!.trafficLightStatus['per_employee_loan']),
      RatioCard(name: 'Per Employee Contribution', value: _ratios!.perEmployeeContribution ?? 0, unit: ' Lakhs', status: _ratios!.trafficLightStatus['per_employee_contribution']),
      RatioCard(name: 'Per Employee Operating Cost', value: _ratios!.perEmployeeOperatingCost ?? 0, unit: ' Lakhs', status: _ratios!.trafficLightStatus['per_employee_operating_cost']),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back,
                                      size: 20,
                                      color: isDark
                                          ? const Color(0xFF60A5FA)
                                          : const Color(0xFF2563EB)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Back to Periods',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFF60A5FA)
                                          : const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ratio Analysis Dashboard',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_period!.label} — Calculated on $calculatedDate',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _tabBtn('Cards', Icons.grid_view_rounded, 'cards', isDark),
                                _tabBtn('Table', Icons.table_chart_outlined, 'table', isDark),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _actionBtn(
                            icon: Icons.bar_chart_rounded,
                            label: 'Productivity',
                            color: const Color(0xFF16A34A),
                            onTap: () => Navigator.pushNamed(context, '${AppRoutes.productivityAnalysis}/${widget.periodId}'),
                          ),
                          const SizedBox(width: 8),
                          _actionBtn(
                            icon: Icons.message_outlined,
                            label: 'Interpretation',
                            color: const Color(0xFF9333EA),
                            onTap: () => Navigator.pushNamed(context, '${AppRoutes.interpretation}/${widget.periodId}'),
                          ),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (buttonContext) => _HoverableButton(
                              onTap: () async {
                                final RenderBox button = buttonContext.findRenderObject() as RenderBox;
                                final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                                final RelativeRect position = RelativeRect.fromRect(
                                  Rect.fromPoints(
                                    button.localToGlobal(button.size.bottomLeft(Offset.zero), ancestor: overlay),
                                    button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                                  ),
                                  Offset.zero & overlay.size,
                                );
                                setState(() => _showExportMenu = true);
                                final String? result = await showMenu<String>(
                                  context: context,
                                  position: position,
                                  items: [
                                    PopupMenuItem<String>(
                                      value: 'excel',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.table_chart,
                                              size: 18,
                                              color: Color(0xFF16A34A)),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: const [
                                              Text('Excel',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14)),
                                              Text('All details in xlsx',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'pdf',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.description,
                                              size: 18,
                                              color: Color(0xFFDC2626)),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: const [
                                              Text('PDF',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14)),
                                              Text('Formatted report pdf',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                                setState(() => _showExportMenu = false);
                                
                                if (result == 'excel') {
                                  _exportToExcel();
                                } else if (result == 'pdf') {
                                  _exportToPDF();
                                }
                              },
                              baseColor: const Color(0xFF4F46E5),
                              hoverColor: const Color(0xFF4338CA),
                              label: 'Export',
                              icon: Icons.download,
                              showChevron: true,
                              isRotated: _showExportMenu,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.2) : const Color(0xFFEFF6FF),
                      border: Border.all(color: isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Working Fund',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827))),
                        const SizedBox(height: 8),
                        Text('₹${_ratios!.workingFund.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_ratios!.interpretation != null &&
                      _ratios!.interpretation!.isNotEmpty &&
                      _ratios!.interpretation != 'null')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E3A8A).withOpacity(0.15)
                            : const Color(0xFFEFF6FF),
                        border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E40AF)
                                : const Color(0xFFBFDBFE)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Interpretation',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827))),
                          const SizedBox(height: 8),
                          Text(_ratios!.interpretation!,
                              style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: isDark
                                      ? const Color(0xFFD1D5DB)
                                      : const Color(0xFF374151))),
                        ],
                      ),
                    ),
                  if (_ratios!.interpretation != null &&
                      _ratios!.interpretation!.isNotEmpty &&
                      _ratios!.interpretation != 'null')
                    const SizedBox(height: 24),
                  if (_viewMode == 'table')
                    RatioAnalysisTable(ratios: _ratios!, periodLabel: _period?.label ?? '')
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _section('Trading Ratios', tradingRatios),
                        _section('Capital Efficiency', capitalEfficiencyRatios),
                        _section('Fund Structure Ratios', fundStructureRatios),
                        _section('Yield & Cost Ratios', yieldCostRatios),
                        _section('Margin Ratios', marginRatios),
                        _section('Productivity Ratios', productivityRatios),
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 48),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('STATUS LEGEND',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 32,
                                runSpacing: 12,
                                children: [
                                  _legendItem(const Color(0xFF22C55E), 'Meets or exceeds ideal', isDark),
                                  _legendItem(const Color(0xFFEAB308), 'Sub-optimal but acceptable', isDark),
                                  _legendItem(const Color(0xFFEF4444), 'Critical - requires attention', isDark),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (_userRole == 'master')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(top: 24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.white,
                        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit period data & recalculate ratios',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF111827))),
                          const SizedBox(height: 8),
                          Text('Update Trading Account, Profit & Loss, Balance Sheet, and Operational Metrics. Then click "Update data & recalculate ratios" to save and store updated ratio results.',
                              style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563))),
                          const SizedBox(height: 16),
                          PeriodDataEditForm(periodId: widget.periodId, onSuccess: _loadData),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  /// View toggle tab button  (like React <button onClick=…>)
  Widget _tabBtn(String label, IconData icon, String mode, bool isDark) {
    final selected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB) // bg-blue-600
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : (isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF4B5563))),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF4B5563)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Action button (Productivity / Interpretation) with hover effect
  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _HoverableButton(
      onTap: onTap,
      baseColor: color,
      hoverColor: _getLighterColor(color),
      label: label,
      icon: icon,
    );
  }

  /// Get lighter shade of color for hover effect
  Color _getLighterColor(Color color) {
    // Simple approach: adjust the color for hover state
    if (color == const Color(0xFF16A34A)) {
      return const Color(0xFF15803D); // darker green
    } else if (color == const Color(0xFF9333EA)) {
      return const Color(0xFF7E22CE); // darker purple
    } else if (color == const Color(0xFF4F46E5)) {
      return const Color(0xFF4338CA); // darker indigo
    }
    return color;
  }

  /// Section: title + 3-column responsive card grid
  Widget _section(String title, List<RatioCard> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
        ),
        LayoutBuilder(builder: (ctx, bc) {
          final cols = bc.maxWidth > 900 ? 3 : (bc.maxWidth > 600 ? 2 : 1);
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: cols == 1 ? 3.2 : 2.8,
            children: cards,
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _legendItem(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }
}

/// Hoverable button widget
class _HoverableButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color baseColor;
  final Color hoverColor;
  final String label;
  final IconData icon;
  final bool showChevron;
  final bool isRotated;

  const _HoverableButton({
    required this.onTap,
    required this.baseColor,
    required this.hoverColor,
    required this.label,
    required this.icon,
    this.showChevron = false,
    this.isRotated = false,
  });

  @override
  State<_HoverableButton> createState() => _HoverableButtonState();
}

class _HoverableButtonState extends State<_HoverableButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovering ? widget.hoverColor : widget.baseColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.showChevron)
                const SizedBox(width: 4),
              if (widget.showChevron)
                AnimatedRotation(
                  turns: widget.isRotated ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more,
                      size: 16, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Export menu item widget with hover effect
class _ExportMenuItemWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ExportMenuItemWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ExportMenuItemWidget> createState() => _ExportMenuItemWidgetState();
}

class _ExportMenuItemWidgetState extends State<_ExportMenuItemWidget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovering
                ? (widget.isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFF3F4F6))
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(widget.icon, size: 20, color: widget.color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.isDark
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
