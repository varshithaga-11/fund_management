import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../access/access.dart';

// -------------------- Interfaces --------------------

class FinancialPeriodData {
  final int id;
  final String periodType;
  final String startDate;
  final String endDate;
  final String label;
  final bool isFinalized;
  final String createdAt;
  final String? uploadedFile;
  final String? fileType;

  FinancialPeriodData({
    required this.id,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.label,
    required this.isFinalized,
    required this.createdAt,
    this.uploadedFile,
    this.fileType,
  });

  factory FinancialPeriodData.fromJson(Map<String, dynamic> json) {
    return FinancialPeriodData(
      id: json['id'],
      periodType: json['period_type'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      label: json['label'],
      isFinalized: json['is_finalized'],
      createdAt: json['created_at'],
      uploadedFile: json['uploaded_file'],
      fileType: json['file_type'],
    );
  }
}

class TradingAccountData {
  final int id;
  final int period;
  final double openingStock;
  final double purchases;
  final double tradeCharges;
  final double sales;
  final double closingStock;
  final double grossProfit;

  TradingAccountData({
    required this.id,
    required this.period,
    required this.openingStock,
    required this.purchases,
    required this.tradeCharges,
    required this.sales,
    required this.closingStock,
    required this.grossProfit,
  });

  factory TradingAccountData.fromJson(Map<String, dynamic> json) {
    return TradingAccountData(
      id: json['id'],
      period: json['period'],
      openingStock: _toDouble(json['opening_stock']),
      purchases: _toDouble(json['purchases']),
      tradeCharges: _toDouble(json['trade_charges']),
      sales: _toDouble(json['sales']),
      closingStock: _toDouble(json['closing_stock']),
      grossProfit: _toDouble(json['gross_profit']),
    );
  }
}

class ProfitAndLossData {
  final int id;
  final int period;
  final double interestOnLoans;
  final double interestOnBankAc;
  final double returnOnInvestment;
  final double miscellaneousIncome;
  final double interestOnDeposits;
  final double interestOnBorrowings;
  final double establishmentContingencies;
  final double provisions;
  final double netProfit;

  ProfitAndLossData({
    required this.id,
    required this.period,
    required this.interestOnLoans,
    required this.interestOnBankAc,
    required this.returnOnInvestment,
    required this.miscellaneousIncome,
    required this.interestOnDeposits,
    required this.interestOnBorrowings,
    required this.establishmentContingencies,
    required this.provisions,
    required this.netProfit,
  });

  factory ProfitAndLossData.fromJson(Map<String, dynamic> json) {
    return ProfitAndLossData(
      id: json['id'],
      period: json['period'],
      interestOnLoans: _toDouble(json['interest_on_loans']),
      interestOnBankAc: _toDouble(json['interest_on_bank_ac']),
      returnOnInvestment: _toDouble(json['return_on_investment']),
      miscellaneousIncome: _toDouble(json['miscellaneous_income']),
      interestOnDeposits: _toDouble(json['interest_on_deposits']),
      interestOnBorrowings: _toDouble(json['interest_on_borrowings']),
      establishmentContingencies: _toDouble(json['establishment_contingencies']),
      provisions: _toDouble(json['provisions']),
      netProfit: _toDouble(json['net_profit']),
    );
  }
}

class BalanceSheetData {
  final int id;
  final int period;
  final double shareCapital;
  final double deposits;
  final double borrowings;
  final double reservesStatutoryFree;
  final double undistributedProfit;
  final double provisions;
  final double otherLiabilities;
  final double cashInHand;
  final double cashAtBank;
  final double investments;
  final double loansAdvances;
  final double fixedAssets;
  final double otherAssets;
  final double stockInTrade;

  BalanceSheetData({
    required this.id,
    required this.period,
    required this.shareCapital,
    required this.deposits,
    required this.borrowings,
    required this.reservesStatutoryFree,
    required this.undistributedProfit,
    required this.provisions,
    required this.otherLiabilities,
    required this.cashInHand,
    required this.cashAtBank,
    required this.investments,
    required this.loansAdvances,
    required this.fixedAssets,
    required this.otherAssets,
    required this.stockInTrade,
  });

  factory BalanceSheetData.fromJson(Map<String, dynamic> json) {
    return BalanceSheetData(
      id: json['id'],
      period: json['period'],
      shareCapital: _toDouble(json['share_capital']),
      deposits: _toDouble(json['deposits']),
      borrowings: _toDouble(json['borrowings']),
      reservesStatutoryFree: _toDouble(json['reserves_statutory_free']),
      undistributedProfit: _toDouble(json['undistributed_profit']),
      provisions: _toDouble(json['provisions']),
      otherLiabilities: _toDouble(json['other_liabilities']),
      cashInHand: _toDouble(json['cash_in_hand']),
      cashAtBank: _toDouble(json['cash_at_bank']),
      investments: _toDouble(json['investments']),
      loansAdvances: _toDouble(json['loans_advances']),
      fixedAssets: _toDouble(json['fixed_assets']),
      otherAssets: _toDouble(json['other_assets']),
      stockInTrade: _toDouble(json['stock_in_trade']),
    );
  }
}

class OperationalMetricsData {
  final int id;
  final int period;
  final int staffCount;

  OperationalMetricsData({
    required this.id,
    required this.period,
    required this.staffCount,
  });

  factory OperationalMetricsData.fromJson(Map<String, dynamic> json) {
    return OperationalMetricsData(
      id: json['id'],
      period: json['period'],
      staffCount: json['staff_count'],
    );
  }
}

class RatioResultData {
  final int id;
  final int period;
  final double? workingFund; // made nullable to be safe
  final double? stockTurnover;
  final double? grossProfitRatio;
  final double? netProfitRatio;
  final double? netOwnFunds;
  final double? ownFundToWf;
  final double? depositsToWf;
  final double? borrowingsToWf;
  final double? loansToWf;
  final double? investmentsToWf;
  final double? costOfDeposits;
  final double? yieldOnLoans;
  final double? yieldOnInvestments;
  final double? creditDepositRatio;
  final double? avgCostOfWf;
  final double? avgYieldOnWf;
  final double? grossFinMargin;
  final double? operatingCostToWf;
  final double? netFinMargin;
  final double? riskCostToWf;
  final double? netMargin;
  final double? capitalTurnoverRatio;
  final double? earningAssetsToWf;
  final double? interestTaggedFundsToWf;
  final double? miscIncomeToWf;
  final double? interestExpToInterestIncome;
  final double? perEmployeeDeposit;
  final double? perEmployeeLoan;
  final double? perEmployeeContribution;
  final double? perEmployeeOperatingCost;
  final Map<String, String>? trafficLightStatus;
  final String? interpretation;

  RatioResultData({
    required this.id,
    required this.period,
    this.workingFund,
    this.stockTurnover,
    this.grossProfitRatio,
    this.netProfitRatio,
    this.netOwnFunds,
    this.ownFundToWf,
    this.depositsToWf,
    this.borrowingsToWf,
    this.loansToWf,
    this.investmentsToWf,
    this.costOfDeposits,
    this.yieldOnLoans,
    this.yieldOnInvestments,
    this.creditDepositRatio,
    this.avgCostOfWf,
    this.avgYieldOnWf,
    this.grossFinMargin,
    this.operatingCostToWf,
    this.netFinMargin,
    this.riskCostToWf,
    this.netMargin,
    this.capitalTurnoverRatio,
    this.earningAssetsToWf,
    this.interestTaggedFundsToWf,
    this.miscIncomeToWf,
    this.interestExpToInterestIncome,
    this.perEmployeeDeposit,
    this.perEmployeeLoan,
    this.perEmployeeContribution,
    this.perEmployeeOperatingCost,
    this.trafficLightStatus,
    this.interpretation,
  });

  factory RatioResultData.fromJson(Map<String, dynamic> json) {
    return RatioResultData(
      id: json['id'],
      period: json['period'],
      workingFund: _toDoubleNullable(json['working_fund']),
      stockTurnover: _toDoubleNullable(json['stock_turnover']),
      grossProfitRatio: _toDoubleNullable(json['gross_profit_ratio']),
      netProfitRatio: _toDoubleNullable(json['net_profit_ratio']),
      netOwnFunds: _toDoubleNullable(json['net_own_funds']),
      ownFundToWf: _toDoubleNullable(json['own_fund_to_wf']),
      depositsToWf: _toDoubleNullable(json['deposits_to_wf']),
      borrowingsToWf: _toDoubleNullable(json['borrowings_to_wf']),
      loansToWf: _toDoubleNullable(json['loans_to_wf']),
      investmentsToWf: _toDoubleNullable(json['investments_to_wf']),
      costOfDeposits: _toDoubleNullable(json['cost_of_deposits']),
      yieldOnLoans: _toDoubleNullable(json['yield_on_loans']),
      yieldOnInvestments: _toDoubleNullable(json['yield_on_investments']),
      creditDepositRatio: _toDoubleNullable(json['credit_deposit_ratio']),
      avgCostOfWf: _toDoubleNullable(json['avg_cost_of_wf']),
      avgYieldOnWf: _toDoubleNullable(json['avg_yield_on_wf']),
      grossFinMargin: _toDoubleNullable(json['gross_fin_margin']),
      operatingCostToWf: _toDoubleNullable(json['operating_cost_to_wf']),
      netFinMargin: _toDoubleNullable(json['net_fin_margin']),
      riskCostToWf: _toDoubleNullable(json['risk_cost_to_wf']),
      netMargin: _toDoubleNullable(json['net_margin']),
      capitalTurnoverRatio: _toDoubleNullable(json['capital_turnover_ratio']),
      earningAssetsToWf: _toDoubleNullable(json['earning_assets_to_wf']),
      interestTaggedFundsToWf: _toDoubleNullable(json['interest_tagged_funds_to_wf']),
      miscIncomeToWf: _toDoubleNullable(json['misc_income_to_wf']),
      interestExpToInterestIncome: _toDoubleNullable(json['interest_exp_to_interest_income']),
      perEmployeeDeposit: _toDoubleNullable(json['per_employee_deposit']),
      perEmployeeLoan: _toDoubleNullable(json['per_employee_loan']),
      perEmployeeContribution: _toDoubleNullable(json['per_employee_contribution']),
      perEmployeeOperatingCost: _toDoubleNullable(json['per_employee_operating_cost']),
      trafficLightStatus: json['traffic_light_status'] != null
          ? Map<String, String>.from(json['traffic_light_status'])
          : null,
      interpretation: json['interpretation'],
    );
  }
}

// Helpers
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

double? _toDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value);
  return null;
}

// -------------------- API Calls --------------------

Future<Map<String, String>> _headers() async => await getAuthHeaders();

Future<TradingAccountData?> getTradingAccount(int periodId) async {
  final url = createApiUrl('api/trading-accounts/?period=$periodId');
  final response = await http.get(Uri.parse(url), headers: await _headers());

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    if (data.isNotEmpty) {
      return TradingAccountData.fromJson(data[0]);
    }
    return null;
  }
  throw Exception('Failed to load trading account');
}

Future<void> createTradingAccount(int periodId, Map<String, dynamic> data) async {
  final url = createApiUrl('api/trading-accounts/');
  final body = jsonEncode({...data, 'period': periodId});
  final response = await http.post(Uri.parse(url), headers: await _headers(), body: body);

  if (response.statusCode != 201) {
    throw Exception('Failed to create trading account: ${response.body}');
  }
}

Future<void> updateTradingAccount(int id, Map<String, dynamic> data) async {
  final url = createApiUrl('api/trading-accounts/$id/');
  final body = jsonEncode(data);
  final response = await http.put(Uri.parse(url), headers: await _headers(), body: body);

  if (response.statusCode != 200) {
    throw Exception('Failed to update trading account: ${response.body}');
  }
}

// Profit & Loss
Future<ProfitAndLossData?> getProfitLoss(int periodId) async {
  final url = createApiUrl('api/profit-loss/?period=$periodId');
  final response = await http.get(Uri.parse(url), headers: await _headers());

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    if (data.isNotEmpty) {
      return ProfitAndLossData.fromJson(data[0]);
    }
    return null;
  }
  throw Exception('Failed to load profit & loss');
}

Future<void> createProfitLoss(int periodId, Map<String, dynamic> data) async {
  final url = createApiUrl('api/profit-loss/');
  final body = jsonEncode({...data, 'period': periodId});
  final response = await http.post(Uri.parse(url), headers: await _headers(), body: body);
  if (response.statusCode != 201) throw Exception('Failed to create profit & loss');
}

Future<void> updateProfitLoss(int id, Map<String, dynamic> data) async {
  final url = createApiUrl('api/profit-loss/$id/');
  final body = jsonEncode(data);
  final response = await http.put(Uri.parse(url), headers: await _headers(), body: body);
  if (response.statusCode != 200) throw Exception('Failed to update profit & loss');
}

// Balance Sheet
Future<BalanceSheetData?> getBalanceSheet(int periodId) async {
  final url = createApiUrl('api/balance-sheets/?period=$periodId');
  final response = await http.get(Uri.parse(url), headers: await _headers());

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    if (data.isNotEmpty) {
      return BalanceSheetData.fromJson(data[0]);
    }
    return null;
  }
  throw Exception('Failed to load balance sheet');
}

Future<void> createBalanceSheet(int periodId, Map<String, dynamic> data) async {
  final url = createApiUrl('api/balance-sheets/');
  final body = jsonEncode({...data, 'period': periodId});
  final response = await http.post(Uri.parse(url), headers: await _headers(), body: body);
  if (response.statusCode != 201) throw Exception('Failed to create balance sheet');
}

Future<void> updateBalanceSheet(int id, Map<String, dynamic> data) async {
  final url = createApiUrl('api/balance-sheets/$id/');
  final body = jsonEncode(data);
  final response = await http.put(Uri.parse(url), headers: await _headers(), body: body);
  if (response.statusCode != 200) throw Exception('Failed to update balance sheet');
}

// Operational Metrics
Future<OperationalMetricsData?> getOperationalMetrics(int periodId) async {
  final url = createApiUrl('api/operational-metrics/?period=$periodId');
  final response = await http.get(Uri.parse(url), headers: await _headers());

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    if (data.isNotEmpty) {
      return OperationalMetricsData.fromJson(data[0]);
    }
    return null;
  }
  throw Exception('Failed to load operational metrics');
}

Future<void> createOperationalMetrics(int periodId, Map<String, dynamic> data) async {
  final url = createApiUrl('api/operational-metrics/');
  final body = jsonEncode({...data, 'period': periodId});
  final response = await http.post(Uri.parse(url), headers: await _headers(), body: body);
  if (response.statusCode != 201) throw Exception('Failed to create operational metrics');
}

Future<void> updateOperationalMetrics(int id, Map<String, dynamic> data) async {
  final url = createApiUrl('api/operational-metrics/$id/');
  final body = jsonEncode(data);
  final response = await http.put(Uri.parse(url), headers: await _headers(), body: body);
  if (response.statusCode != 200) throw Exception('Failed to update operational metrics');
}

// Ratio Results
Future<RatioResultData?> getRatioResults(int periodId) async {
  final url = createApiUrl('api/ratio-results/?period=$periodId');
  final response = await http.get(Uri.parse(url), headers: await _headers());

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    if (data.isNotEmpty) {
      return RatioResultData.fromJson(data[0]);
    }
    return null;
  }
   // Sometimes empty list is valid if no ratios calculated
   if (response.statusCode == 200) return null;

  throw Exception('Failed to load ratio results');
}

Future<RatioResultData> calculateRatios(int periodId) async {
  final url = createApiUrl('api/periods/$periodId/calculate-ratios/');
  final response = await http.post(Uri.parse(url), headers: await _headers());

  if (response.statusCode == 200 || response.statusCode == 201) {
    final body = jsonDecode(response.body);
    return RatioResultData.fromJson(body['data']);
  }
  throw Exception('Failed to calculate ratios: ${response.body}');
}
