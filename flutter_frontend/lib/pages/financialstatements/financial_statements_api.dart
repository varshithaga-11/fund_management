import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../access/access.dart';

// -------------------- Models --------------------

class FinancialPeriodData {
  final int id;
  final String periodType;
  final String startDate;
  final String endDate;
  final String label;
  final bool isFinalized;
  final String createdAt;
  final TradingAccountData? tradingAccount;
  final ProfitAndLossData? profitLoss;
  final BalanceSheetData? balanceSheet;
  final OperationalMetricsData? operationalMetrics;
  final RatioResultData? ratios;
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
    this.tradingAccount,
    this.profitLoss,
    this.balanceSheet,
    this.operationalMetrics,
    this.ratios,
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
      tradingAccount: json['trading_account'] != null
          ? TradingAccountData.fromJson(json['trading_account'])
          : null,
      profitLoss: json['profit_loss'] != null
          ? ProfitAndLossData.fromJson(json['profit_loss'])
          : null,
      balanceSheet: json['balance_sheet'] != null
          ? BalanceSheetData.fromJson(json['balance_sheet'])
          : null,
      operationalMetrics: json['operational_metrics'] != null
          ? OperationalMetricsData.fromJson(json['operational_metrics'])
          : null,
      ratios: json['ratios'] != null
          ? RatioResultData.fromJson(json['ratios'])
          : null,
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

  Map<String, dynamic> toJson() {
    return {
      'opening_stock': openingStock,
      'purchases': purchases,
      'trade_charges': tradeCharges,
      'sales': sales,
      'closing_stock': closingStock,
    };
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
  final double totalInterestIncome;
  final double totalInterestExpense;

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
    required this.totalInterestIncome,
    required this.totalInterestExpense,
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
      totalInterestIncome: _toDouble(json['total_interest_income']),
      totalInterestExpense: _toDouble(json['total_interest_expense']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interest_on_loans': interestOnLoans,
      'interest_on_bank_ac': interestOnBankAc,
      'return_on_investment': returnOnInvestment,
      'miscellaneous_income': miscellaneousIncome,
      'interest_on_deposits': interestOnDeposits,
      'interest_on_borrowings': interestOnBorrowings,
      'establishment_contingencies': establishmentContingencies,
      'provisions': provisions,
      'net_profit': netProfit,
    };
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
  final double workingFund;
  final double ownFunds;

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
    required this.workingFund,
    required this.ownFunds,
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
      workingFund: _toDouble(json['working_fund']),
      ownFunds: _toDouble(json['own_funds']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'share_capital': shareCapital,
      'deposits': deposits,
      'borrowings': borrowings,
      'reserves_statutory_free': reservesStatutoryFree,
      'undistributed_profit': undistributedProfit,
      'provisions': provisions,
      'other_liabilities': otherLiabilities,
      'cash_in_hand': cashInHand,
      'cash_at_bank': cashAtBank,
      'investments': investments,
      'loans_advances': loansAdvances,
      'fixed_assets': fixedAssets,
      'other_assets': otherAssets,
      'stock_in_trade': stockInTrade,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'staff_count': staffCount,
    };
  }
}

class RatioResultData {
  final int id;
  final int period;
  final double workingFund;
  final double stockTurnover;
  final double grossProfitRatio;
  final double netProfitRatio;
  final double? netOwnFunds;
  final double ownFundToWf;
  final double depositsToWf;
  final double borrowingsToWf;
  final double loansToWf;
  final double investmentsToWf;
  final double costOfDeposits;
  final double yieldOnLoans;
  final double yieldOnInvestments;
  final double creditDepositRatio;
  final double avgCostOfWf;
  final double avgYieldOnWf;
  final double grossFinMargin;
  final double operatingCostToWf;
  final double netFinMargin;
  final double riskCostToWf;
  final double netMargin;
  final double? capitalTurnoverRatio;
  final double? earningAssetsToWf;
  final double? interestTaggedFundsToWf;
  final double? miscIncomeToWf;
  final double? interestExpToInterestIncome;
  final double? perEmployeeDeposit;
  final double? perEmployeeLoan;
  final double? perEmployeeContribution;
  final double? perEmployeeOperatingCost;
  final Map<String, String> trafficLightStatus;
  final String calculatedAt;
  final String? interpretation;

  RatioResultData({
    required this.id,
    required this.period,
    required this.workingFund,
    required this.stockTurnover,
    required this.grossProfitRatio,
    required this.netProfitRatio,
    this.netOwnFunds,
    required this.ownFundToWf,
    required this.depositsToWf,
    required this.borrowingsToWf,
    required this.loansToWf,
    required this.investmentsToWf,
    required this.costOfDeposits,
    required this.yieldOnLoans,
    required this.yieldOnInvestments,
    required this.creditDepositRatio,
    required this.avgCostOfWf,
    required this.avgYieldOnWf,
    required this.grossFinMargin,
    required this.operatingCostToWf,
    required this.netFinMargin,
    required this.riskCostToWf,
    required this.netMargin,
    this.capitalTurnoverRatio,
    this.earningAssetsToWf,
    this.interestTaggedFundsToWf,
    this.miscIncomeToWf,
    this.interestExpToInterestIncome,
    this.perEmployeeDeposit,
    this.perEmployeeLoan,
    this.perEmployeeContribution,
    this.perEmployeeOperatingCost,
    required this.trafficLightStatus,
    required this.calculatedAt,
    this.interpretation,
  });

  factory RatioResultData.fromJson(Map<String, dynamic> json) {
    return RatioResultData(
      id: json['id'],
      period: json['period'],
      workingFund: _toDouble(json['working_fund']),
      stockTurnover: _toDouble(json['stock_turnover']),
      grossProfitRatio: _toDouble(json['gross_profit_ratio']),
      netProfitRatio: _toDouble(json['net_profit_ratio']),
      netOwnFunds: json['net_own_funds'] != null ? _toDouble(json['net_own_funds']) : null,
      ownFundToWf: _toDouble(json['own_fund_to_wf']),
      depositsToWf: _toDouble(json['deposits_to_wf']),
      borrowingsToWf: _toDouble(json['borrowings_to_wf']),
      loansToWf: _toDouble(json['loans_to_wf']),
      investmentsToWf: _toDouble(json['investments_to_wf']),
      costOfDeposits: _toDouble(json['cost_of_deposits']),
      yieldOnLoans: _toDouble(json['yield_on_loans']),
      yieldOnInvestments: _toDouble(json['yield_on_investments']),
      creditDepositRatio: _toDouble(json['credit_deposit_ratio']),
      avgCostOfWf: _toDouble(json['avg_cost_of_wf']),
      avgYieldOnWf: _toDouble(json['avg_yield_on_wf']),
      grossFinMargin: _toDouble(json['gross_fin_margin']),
      operatingCostToWf: _toDouble(json['operating_cost_to_wf']),
      netFinMargin: _toDouble(json['net_fin_margin']),
      riskCostToWf: _toDouble(json['risk_cost_to_wf']),
      netMargin: _toDouble(json['net_margin']),
      capitalTurnoverRatio: json['capital_turnover_ratio'] != null ? _toDouble(json['capital_turnover_ratio']) : null,
      earningAssetsToWf: json['earning_assets_to_wf'] != null ? _toDouble(json['earning_assets_to_wf']) : null,
      interestTaggedFundsToWf: json['interest_tagged_funds_to_wf'] != null ? _toDouble(json['interest_tagged_funds_to_wf']) : null,
      miscIncomeToWf: json['misc_income_to_wf'] != null ? _toDouble(json['misc_income_to_wf']) : null,
      interestExpToInterestIncome: json['interest_exp_to_interest_income'] != null ? _toDouble(json['interest_exp_to_interest_income']) : null,
      perEmployeeDeposit: json['per_employee_deposit'] != null ? _toDouble(json['per_employee_deposit']) : null,
      perEmployeeLoan: json['per_employee_loan'] != null ? _toDouble(json['per_employee_loan']) : null,
      perEmployeeContribution: json['per_employee_contribution'] != null ? _toDouble(json['per_employee_contribution']) : null,
      perEmployeeOperatingCost: json['per_employee_operating_cost'] != null ? _toDouble(json['per_employee_operating_cost']) : null,
      trafficLightStatus: Map<String, String>.from(json['traffic_light_status'] ?? {}),
      calculatedAt: json['calculated_at'],
      interpretation: json['interpretation'],
    );
  }
}

class StatementColumnConfig {
  final int id;
  final String statementType;
  final String canonicalField;
  final String displayName;
  final List<String> aliases;
  final bool isRequired;

  StatementColumnConfig({
    required this.id,
    required this.statementType,
    required this.canonicalField,
    required this.displayName,
    required this.aliases,
    required this.isRequired,
  });

  factory StatementColumnConfig.fromJson(Map<String, dynamic> json) {
    return StatementColumnConfig(
      id: json['id'],
      statementType: json['statement_type'],
      canonicalField: json['canonical_field'],
      displayName: json['display_name'],
      aliases: (json['aliases'] as List<dynamic>).map((e) => e.toString()).toList(),
      isRequired: json['is_required'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statement_type': statementType,
      'canonical_field': canonicalField,
      'display_name': displayName,
      'aliases': aliases,
      'is_required': isRequired,
    };
  }
}

// -------------------- Helper --------------------

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

// -------------------- API Calls --------------------

// Financial Periods

Future<List<FinancialPeriodData>> getFinancialPeriods() async {
  final url = createApiUrl('api/financial-periods/');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => FinancialPeriodData.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load financial periods');
  }
}

Future<FinancialPeriodData> getFinancialPeriod(int id) async {
  final url = createApiUrl('api/financial-periods/$id/');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    return FinancialPeriodData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load financial period $id');
  }
}

Future<FinancialPeriodData> createFinancialPeriod(Map<String, dynamic> data) async {
  final url = createApiUrl('api/financial-periods/');
  final response = await http.post(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(data),
  );

  if (response.statusCode == 201) {
    return FinancialPeriodData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to create financial period: ${response.body}');
  }
}

Future<FinancialPeriodData> updateFinancialPeriod(int id, Map<String, dynamic> data) async {
  final url = createApiUrl('api/financial-periods/$id/');
  final response = await http.put(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    return FinancialPeriodData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update financial period: ${response.body}');
  }
}

// Trading Account

Future<TradingAccountData?> getTradingAccount(int periodId) async {
  final url = createApiUrl('api/trading-accounts/?period=$periodId');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    if (data.isNotEmpty) {
      return TradingAccountData.fromJson(data[0]);
    }
  }
  return null;
}

Future<TradingAccountData> createTradingAccount(int periodId, Map<String, dynamic> data) async {
  final url = createApiUrl('api/trading-accounts/');
  final body = {...data, 'period': periodId};
  final response = await http.post(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(body),
  );

  if (response.statusCode == 201) {
    return TradingAccountData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to create trading account: ${response.body}');
  }
}

Future<TradingAccountData> updateTradingAccount(int id, Map<String, dynamic> data) async {
  final url = createApiUrl('api/trading-accounts/$id/');
  final response = await http.put(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    return TradingAccountData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update trading account: ${response.body}');
  }
}

// Profit & Loss

Future<ProfitAndLossData?> getProfitLoss(int periodId) async {
  final url = createApiUrl('api/profit-loss/?period=$periodId');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    if (data.isNotEmpty) {
      return ProfitAndLossData.fromJson(data[0]);
    }
  }
  return null;
}

Future<ProfitAndLossData> createProfitLoss(int periodId, Map<String, dynamic> data) async {
  final url = createApiUrl('api/profit-loss/');
  final body = {...data, 'period': periodId};
  final response = await http.post(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(body),
  );

  if (response.statusCode == 201) {
    return ProfitAndLossData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to create profit & loss: ${response.body}');
  }
}

Future<ProfitAndLossData> updateProfitLoss(int id, Map<String, dynamic> data) async {
  final url = createApiUrl('api/profit-loss/$id/');
  final response = await http.put(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    return ProfitAndLossData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update profit & loss: ${response.body}');
  }
}

// Balance Sheet

Future<BalanceSheetData?> getBalanceSheet(int periodId) async {
  final url = createApiUrl('api/balance-sheets/?period=$periodId');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    if (data.isNotEmpty) {
      return BalanceSheetData.fromJson(data[0]);
    }
  }
  return null;
}

Future<BalanceSheetData> createBalanceSheet(int periodId, Map<String, dynamic> data) async {
  final url = createApiUrl('api/balance-sheets/');
  final body = {...data, 'period': periodId};
  final response = await http.post(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(body),
  );

  if (response.statusCode == 201) {
    return BalanceSheetData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to create balance sheet: ${response.body}');
  }
}

Future<BalanceSheetData> updateBalanceSheet(int id, Map<String, dynamic> data) async {
  final url = createApiUrl('api/balance-sheets/$id/');
  final response = await http.put(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    return BalanceSheetData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update balance sheet: ${response.body}');
  }
}

// Operational Metrics

Future<OperationalMetricsData?> getOperationalMetrics(int periodId) async {
  final url = createApiUrl('api/operational-metrics/?period=$periodId');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    if (data.isNotEmpty) {
      return OperationalMetricsData.fromJson(data[0]);
    }
  }
  return null;
}

Future<OperationalMetricsData> createOperationalMetrics(int periodId, Map<String, dynamic> data) async {
  final url = createApiUrl('api/operational-metrics/');
  final body = {...data, 'period': periodId};
  final response = await http.post(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(body),
  );

  if (response.statusCode == 201) {
    return OperationalMetricsData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to create operational metrics: ${response.body}');
  }
}

Future<OperationalMetricsData> updateOperationalMetrics(int id, Map<String, dynamic> data) async {
  final url = createApiUrl('api/operational-metrics/$id/');
  final response = await http.put(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    return OperationalMetricsData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update operational metrics: ${response.body}');
  }
}

// Ratio Results

Future<RatioResultData?> getRatioResults(int periodId) async {
  final url = createApiUrl('api/ratio-results/?period=$periodId');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    if (data.isNotEmpty) {
      return RatioResultData.fromJson(data[0]);
    }
  }
  return null;
}

Future<RatioResultData> calculateRatios(int periodId) async {
  final url = createApiUrl('api/periods/$periodId/calculate-ratios/');
  final response = await http.post(
    Uri.parse(url),
    headers: await getAuthHeaders(),
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    return RatioResultData.fromJson(body['data']);
  } else {
    throw Exception('Failed to calculate ratios: ${response.body}');
  }
}

// Statement Columns

Future<List<StatementColumnConfig>> getStatementColumns(String statementType) async {
  final url = createApiUrl('api/statement-columns/?statement_type=$statementType');
  final response = await http.get(Uri.parse(url), headers: await getAuthHeaders());

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => StatementColumnConfig.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load statement columns');
  }
}

Future<void> createStatementColumn(Map<String, dynamic> data) async {
  final url = createApiUrl('api/statement-columns/');
  final response = await http.post(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(data),
  );

  if (response.statusCode != 201) {
    throw Exception('Failed to create statement column: ${response.body}');
  }
}

Future<void> updateStatementColumn(int id, Map<String, dynamic> data) async {
  final url = createApiUrl('api/statement-columns/$id/');
  final response = await http.patch(
    Uri.parse(url),
    headers: await getAuthHeaders(),
    body: jsonEncode(data),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to update statement column: ${response.body}');
  }
}

// Download Templates

Future<List<int>> downloadExcelTemplate() async {
  final url = createApiUrl("api/download-excel-template/");
  final response = await http.get(
    Uri.parse(url),
    headers: await getAuthHeaders(),
  );

  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw Exception('Failed to download Excel template: ${response.body}');
  }
}

Future<List<int>> downloadWordTemplate() async {
  final url = createApiUrl("api/download-word-template/");
  final response = await http.get(
    Uri.parse(url),
    headers: await getAuthHeaders(),
  );

  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw Exception('Failed to download Word template: ${response.body}');
  }
}

// Excel Upload
Future<Map<String, dynamic>> uploadExcelData(http.MultipartFile file) async {
  final url = createApiUrl("api/upload-excel/");
  var request = http.MultipartRequest('POST', Uri.parse(url));
  
  Map<String, String> headers = await getAuthHeaders();
  // Remove content-type as multipart request sets it
  headers.remove('Content-Type');
  
  request.headers.addAll(headers);
  request.files.add(file);
  
  var streamedResponse = await request.send();
  var response = await http.Response.fromStream(streamedResponse);
  
  if (response.statusCode == 200 || response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to upload file: ${response.body}');
  }
}
