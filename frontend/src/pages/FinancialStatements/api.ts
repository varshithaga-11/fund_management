import { LucideOmega } from "lucide-react";
import { createApiUrl, getAuthHeaders } from "../../access/access.ts";
import axios from "axios";

// -------------------- Interfaces --------------------

export interface FinancialPeriodData {
  id: number;
  company: number;
  period_type: "MONTHLY" | "QUARTERLY" | "HALF_YEARLY" | "YEARLY";
  start_date: string;
  end_date: string;
  label: string;
  is_finalized: boolean;
  created_at: string;
  trading_account?: TradingAccountData;
  profit_loss?: ProfitAndLossData;
  balance_sheet?: BalanceSheetData;
  operational_metrics?: OperationalMetricsData;
  ratios?: RatioResultData;
}

export interface TradingAccountData {
  id: number;
  period: number;
  opening_stock: number;
  purchases: number;
  trade_charges: number;
  sales: number;
  closing_stock: number;
  gross_profit: number;
}

export interface ProfitAndLossData {
  id: number;
  period: number;
  interest_on_loans: number;
  interest_on_bank_ac: number;
  return_on_investment: number;
  miscellaneous_income: number;
  interest_on_deposits: number;
  interest_on_borrowings: number;
  establishment_contingencies: number;
  provisions: number;
  net_profit: number;
  total_interest_income: number;
  total_interest_expense: number;
}

export interface BalanceSheetData {
  id: number;
  period: number;
  share_capital: number;
  deposits: number;
  borrowings: number;
  reserves_statutory_free: number;
  undistributed_profit: number;
  provisions: number;
  other_liabilities: number;
  cash_in_hand: number;
  cash_at_bank: number;
  investments: number;
  loans_advances: number;
  fixed_assets: number;
  other_assets: number;
  stock_in_trade: number;
  working_fund: number;
  own_funds: number;
}

export interface OperationalMetricsData {
  id: number;
  period: number;
  staff_count: number;
}

export interface RatioResultData {
  id: number;
  period: number;
  working_fund: number;
  stock_turnover: number;
  gross_profit_ratio: number;
  net_profit_ratio: number;
  net_own_funds?: number;
  own_fund_to_wf: number;
  deposits_to_wf: number;
  borrowings_to_wf: number;
  loans_to_wf: number;
  investments_to_wf: number;
  cost_of_deposits: number;
  yield_on_loans: number;
  yield_on_investments: number;
  credit_deposit_ratio: number;
  avg_cost_of_wf: number;
  avg_yield_on_wf: number;
  gross_fin_margin: number;
  operating_cost_to_wf: number;
  net_fin_margin: number;
  risk_cost_to_wf: number;
  net_margin: number;
  capital_turnover_ratio?: number;
  earning_assets_to_wf?: number;
  interest_tagged_funds_to_wf?: number;
  misc_income_to_wf?: number;
  interest_exp_to_interest_income?: number;
  per_employee_deposit?: number;
  per_employee_loan?: number;
  per_employee_contribution?: number;
  per_employee_operating_cost?: number;
  all_ratios: Record<string, any>;
  traffic_light_status: Record<string, "green" | "yellow" | "red">;
  calculated_at: string;
  interpretation: string;
}

export interface FinancialPeriodFormData {
  company: number;
  period_type: "MONTHLY" | "QUARTERLY" | "HALF_YEARLY" | "YEARLY";
  start_date: string;
  end_date: string;
  label: string;
  is_finalized?: boolean;
}

// -------------------- API Calls --------------------

// Financial Periods
export const getFinancialPeriods = async (companyId?: number): Promise<FinancialPeriodData[]> => {
  try {
    const url = createApiUrl("api/financial-periods/");
    const params = companyId ? { company: companyId } : {};
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
      params,
    });
    return response.data;
  } catch (error) {
    console.error("Error fetching financial periods:", error);
    throw error;
  }
};

export const getFinancialPeriod = async (id: number): Promise<FinancialPeriodData> => {
  try {
    const url = createApiUrl(`api/financial-periods/${id}/`);
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    return response.data;
  } catch (error) {
    console.error(`Error fetching financial period ${id}:`, error);
    throw error;
  }
};

export const createFinancialPeriod = async (
  data: FinancialPeriodFormData
): Promise<FinancialPeriodData> => {
  try {
    const url = createApiUrl("api/financial-periods/");
    const response = await axios.post(url, data, {
      headers: await getAuthHeaders(),
    });
    return response.data;
  } catch (error) {
    console.error("Error creating financial period:", error);
    throw error;
  }
};

export const updateFinancialPeriod = async (
  id: number,
  data: Partial<FinancialPeriodFormData>
): Promise<FinancialPeriodData> => {
  try {
    const url = createApiUrl(`api/financial-periods/${id}/`);
    const response = await axios.put(url, data, {
      headers: await getAuthHeaders(),
    });
    return response.data;
  } catch (error) {
    console.error("Error updating financial period:", error);
    throw error;
  }
};

// Trading Account
export const getTradingAccount = async (periodId: number): Promise<TradingAccountData | null> => {
  try {
    const url = createApiUrl("api/trading-accounts/");
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
      params: { period: periodId },
    });
    return response.data.length > 0 ? response.data[0] : null;
  } catch (error) {
    console.error("Error fetching trading account:", error);
    throw error;
  }
};

export const createTradingAccount = async (
  periodId: number,
  data: Omit<TradingAccountData, "id" | "period" | "gross_profit">
): Promise<TradingAccountData> => {
  try {
    const url = createApiUrl("api/trading-accounts/");
    const response = await axios.post(
      url,
      { ...data, period: periodId },
      {
        headers: await getAuthHeaders(),
      }
    );
    return response.data;
  } catch (error) {
    console.error("Error creating trading account:", error);
    throw error;
  }
};

export const updateTradingAccount = async (
  id: number,
  data: Partial<Omit<TradingAccountData, "id" | "period" | "gross_profit">>
): Promise<TradingAccountData> => {
  try {
    const url = createApiUrl(`api/trading-accounts/${id}/`);
    const response = await axios.put(url, data, {
      headers: await getAuthHeaders(),
    });
    return response.data;
  } catch (error) {
    console.error("Error updating trading account:", error);
    throw error;
  }
};

// Profit & Loss
export const getProfitLoss = async (periodId: number): Promise<ProfitAndLossData | null> => {
  try {
    const url = createApiUrl("api/profit-loss/");
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
      params: { period: periodId },
    });
    return response.data.length > 0 ? response.data[0] : null;
  } catch (error) {
    console.error("Error fetching profit & loss:", error);
    throw error;
  }
};

export const createProfitLoss = async (
  periodId: number,
  data: Omit<ProfitAndLossData, "id" | "period" | "total_interest_income" | "total_interest_expense">
): Promise<ProfitAndLossData> => {
  try {
    const url = createApiUrl("api/profit-loss/");
    const response = await axios.post(
      url,
      { ...data, period: periodId },
      {
        headers: await getAuthHeaders(),
      }
    );
    return response.data;
  } catch (error) {
    console.error("Error creating profit & loss:", error);
    throw error;
  }
};

export const updateProfitLoss = async (
  id: number,
  data: Partial<Omit<ProfitAndLossData, "id" | "period" | "total_interest_income" | "total_interest_expense">>
): Promise<ProfitAndLossData> => {
  try {
    const url = createApiUrl(`api/profit-loss/${id}/`);
    const response = await axios.put(url, data, {
      headers: await getAuthHeaders(),
    });
    return response.data;
  } catch (error) {
    console.error("Error updating profit & loss:", error);
    throw error;
  }
};

// Balance Sheet
export const getBalanceSheet = async (periodId: number): Promise<BalanceSheetData | null> => {
  try {
    const url = createApiUrl("api/balance-sheets/");
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
      params: { period: periodId },
    });
    return response.data.length > 0 ? response.data[0] : null;
  } catch (error) {
    console.error("Error fetching balance sheet:", error);
    throw error;
  }
};

export const createBalanceSheet = async (
  periodId: number,
  data: Omit<BalanceSheetData, "id" | "period" | "working_fund" | "own_funds">
): Promise<BalanceSheetData> => {
  try {
    const url = createApiUrl("api/balance-sheets/");
    const response = await axios.post(
      url,
      { ...data, period: periodId },
      {
        headers: await getAuthHeaders(),
      }
    );
    return response.data;
  } catch (error) {
    console.error("Error creating balance sheet:", error);
    throw error;
  }
};

export const updateBalanceSheet = async (
  id: number,
  data: Partial<Omit<BalanceSheetData, "id" | "period" | "working_fund" | "own_funds">>
): Promise<BalanceSheetData> => {
  try {
    const url = createApiUrl(`api/balance-sheets/${id}/`);
    const response = await axios.put(url, data, {
      headers: await getAuthHeaders(),
    });
    return response.data;
  } catch (error) {
    console.error("Error updating balance sheet:", error);
    throw error;
  }
};

// Operational Metrics
export const getOperationalMetrics = async (periodId: number): Promise<OperationalMetricsData | null> => {
  try {
    const url = createApiUrl("api/operational-metrics/");
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
      params: { period: periodId },
    });
    return response.data.length > 0 ? response.data[0] : null;
  } catch (error) {
    console.error("Error fetching operational metrics:", error);
    throw error;
  }
};

export const createOperationalMetrics = async (
  periodId: number,
  data: Omit<OperationalMetricsData, "id" | "period">
): Promise<OperationalMetricsData> => {
  try {
    const url = createApiUrl("api/operational-metrics/");
    const response = await axios.post(
      url,
      { ...data, period: periodId },
      {
        headers: await getAuthHeaders(),
      }
    );
    return response.data;
  } catch (error) {
    console.error("Error creating operational metrics:", error);
    throw error;
  }
};

export const updateOperationalMetrics = async (
  id: number,
  data: Partial<Omit<OperationalMetricsData, "id" | "period">>
): Promise<OperationalMetricsData> => {
  try {
    const url = createApiUrl(`api/operational-metrics/${id}/`);
    const response = await axios.put(url, data, {
      headers: await getAuthHeaders(),
    });
    return response.data;
  } catch (error) {
    console.error("Error updating operational metrics:", error);
    throw error;
  }
};

// Ratio Results
export const getRatioResults = async (periodId: number): Promise<RatioResultData | null> => {
  try {
    const url = createApiUrl("api/ratio-results/");
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
      params: { period: periodId },
    });
    return response.data.length > 0 ? response.data[0] : null;
  } catch (error) {
    console.error("Error fetching ratio results:", error);
    throw error;
  }
};

export const calculateRatios = async (periodId: number): Promise<RatioResultData> => {
  try {
    const url = createApiUrl(`api/periods/${periodId}/calculate-ratios/`);
    const response = await axios.post(
      url,
      {},
      {
        headers: await getAuthHeaders(),
      }
    );
    return response.data.data;
  } catch (error) {
    console.error("Error calculating ratios:", error);
    throw error;
  }
};

// Download Templates
export const downloadExcelTemplate = async (): Promise<void> => {
  try {
    const url = createApiUrl("api/download-excel-template/");
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
      responseType: "blob",
    });

    const blob = new Blob([response.data], {
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    });
    const downloadUrl = window.URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = downloadUrl;
    link.download = "Financial_Data_Template.xlsx";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(downloadUrl);
  } catch (error) {
    console.error("Error downloading Excel template:", error);
    throw error;
  }
};

export const downloadWordTemplate = async (): Promise<void> => {
  try {
    const url = createApiUrl("api/download-word-template/");
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
      responseType: "blob",
    });

    const blob = new Blob([response.data], {
      type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    });
    const downloadUrl = window.URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = downloadUrl;
    link.download = "Financial_Data_Template.docx";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(downloadUrl);
  } catch (error) {
    console.error("Error downloading Word template:", error);
    throw error;
  }
};

// Excel Upload
export const uploadExcelData = async (formData: FormData): Promise<{ period_id: number }> => {
  try {
    const url = createApiUrl("api/upload-excel/");
    const headers = await getAuthHeaders();
    // Remove Content-Type header for FormData (browser will set it with boundary)
    delete headers['Content-Type'];

    const response = await axios.post(url, formData, {
      headers,
    });
    return response.data;
  } catch (error) {
    console.error("Error uploading Excel file:", error);
    throw error;
  }
};
