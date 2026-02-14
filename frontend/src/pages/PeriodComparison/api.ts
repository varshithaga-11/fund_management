import { createApiUrl, getAuthHeaders } from "../../access/access.ts";
import axios from "axios";

export interface CompanyData {
  id: number;
  name: string;
  registration_no: string;
  created_at: string;
}

export interface FinancialPeriodData {
  id: number;
  company: number;
  period_type: "MONTHLY" | "QUARTERLY" | "HALF_YEARLY" | "YEARLY";
  start_date: string;
  end_date: string;
  label: string;
  is_finalized: boolean;
  uploaded_file?: string;
  file_type?: "excel" | "docx" | "pdf";
  created_at: string;
}

// Lightweight period data for listing (minimal fields - no financial data)
// Note: When using the new CompanyAllPeriodsView endpoint, only id, label, start_date, end_date, period_type are returned
export interface PeriodListData {
  id: number;
  company?: number;
  period_type: "MONTHLY" | "QUARTERLY" | "HALF_YEARLY" | "YEARLY";
  label: string;
  start_date: string;
  end_date: string;
  is_finalized?: boolean;
  uploaded_file?: string;
  file_type?: "excel" | "docx" | "pdf";
  created_at?: string;
}

export interface RatioComparison {
  period1: number | null;
  period2: number | null;
  difference: number | null;
  percentage_change: number | null;
}

export interface RawPeriodComparisonResponse {
  status: string;
  response_code: number;
  data: {
    period_1: Record<string, any>;
    period_2: Record<string, any>;
    difference: Record<string, { value: number; percentage_change: number | null }>;
  };
}

export interface PeriodComparisonResponse {
  status: string;
  response_code: number;
  data: {
    company: string;
    period1: string;
    period2: string;
    ratios: Record<string, RatioComparison>;
  };
}

// Fetch all companies
export const getCompanies = async (): Promise<CompanyData[]> => {
  try {
    const url = createApiUrl("api/companies/");
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    return response.data;
  } catch (error) {
    console.error("Error fetching companies:", error);
    throw error;
  }
};

// Fetch financial periods for a specific company
export const getCompanyPeriods = async (companyId: number): Promise<FinancialPeriodData[]> => {
  try {
    const url = createApiUrl(`api/financial-periods/?company=${companyId}`);
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    return response.data;
  } catch (error) {
    console.error("Error fetching periods:", error);
    throw error;
  }
};

// Fetch lightweight period list for a specific company (minimal fields only - no financial data)
// Uses the optimized CompanyAllPeriodsView endpoint
export const getCompanyPeriodsList = async (companyId: number): Promise<PeriodListData[]> => {
  try {
    const url = createApiUrl(`api/companies/all-periods/?company_id=${companyId}`);
    console.log(`Fetching periods from: ${url}`);
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    console.log("Periods response:", response.data);
    
    // Extract data array from response
    if (response.data?.data && Array.isArray(response.data.data)) {
      return response.data.data;
    }
    
    // Fallback: if response.data is directly an array
    if (Array.isArray(response.data)) {
      return response.data;
    }
    
    throw new Error("Invalid response structure");
  } catch (error: any) {
    console.error(`Error fetching period list for company ${companyId}:`, error);
    throw error;
  }
};

// Compare periods for a company using period IDs (optimized)
export const comparePeriodsById = async (
  period1Id: number,
  period2Id: number
): Promise<RawPeriodComparisonResponse> => {
  try {
    // Use the optimized period-comparison-by-id endpoint
    const url = createApiUrl(
      `api/period-comparison-by-id/?period_id1=${period1Id}&period_id2=${period2Id}`
    );
    console.log(`Comparing periods: ${url}`);
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    console.log("Period comparison response:", response.data);
    return response.data;
  } catch (error: any) {
    console.error("Error comparing periods:", error);
    throw error;
  }
};

// Compare periods for a company (legacy - uses labels)
export const comparePeriods = async (
  companyId: number,
  period1: string,
  period2: string
): Promise<PeriodComparisonResponse> => {
  try {
    const url = createApiUrl(
      `api/period-comparison/?company_id=${companyId}&period1=${encodeURIComponent(
        period1
      )}&period2=${encodeURIComponent(period2)}`
    );
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    return response.data;
  } catch (error: any) {
    console.error("Error comparing periods:", error);
    throw error;
  }
};
