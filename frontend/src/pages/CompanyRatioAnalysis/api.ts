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
export interface PeriodListData {
  id: number;
  company: number;
  period_type: "MONTHLY" | "QUARTERLY" | "HALF_YEARLY" | "YEARLY";
  label: string;
  start_date: string;
  end_date: string;
  is_finalized: boolean;
  uploaded_file?: string;
  file_type?: "excel" | "docx" | "pdf";
  created_at: string;
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
    console.log("Fetching from URL:", url);

    const headers = await getAuthHeaders();
    console.log("Using auth headers");

    const response = await axios.get(url, { headers });
    console.log(`API Response for company ${companyId}:`, response.data);

    return response.data;
  } catch (error: any) {
    console.error(`Error fetching periods for company ${companyId}:`, error);
    console.error("Error response:", error?.response?.data);
    console.error("Error status:", error?.response?.status);
    throw error;
  }
};

// Fetch lightweight period list for a specific company (minimal fields only - no financial data)
export const getCompanyPeriodsList = async (companyId: number): Promise<PeriodListData[]> => {
  try {
    const fields = "id,label,period_type,company,start_date,end_date,is_finalized,uploaded_file,file_type,created_at";
    const url = createApiUrl(`api/financial-periods/?company=${companyId}&fields=${fields}`);
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    return response.data;
  } catch (error: any) {
    console.error(`Error fetching period list for company ${companyId}:`, error);
    throw error;
  }
};

// Category types for trend analysis
export type RatioCategory = 
  | "Trading Ratios"
  | "Capital Ratios"
  | "Fund Structure"
  | "Yield & Cost"
  | "Margin Analysis"
  | "Capital Efficiency"
  | "Productivity Analysis";

// Fetch ratio trends for a company, optionally filtered by category
export const getCompanyRatioTrends = async (
  companyId: number,
  category?: RatioCategory
): Promise<any[]> => {
  try {
    let url = createApiUrl(`api/ratio-results/?period__company=${companyId}`);
    
    // Add category filter if provided
    if (category) {
      url += `&category=${encodeURIComponent(category)}`;
    }
    
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    return response.data;
  } catch (error) {
    console.error("Error fetching ratio trends:", error);
    throw error;
  }
};
