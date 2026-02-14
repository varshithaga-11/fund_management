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

// Extended period data with ratio information from dashboard
export interface PeriodWithRatiosData extends PeriodListData {
  net_revenue: number;
  net_profit: number;
  ratios: any; // Full RatioResultData structure
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

// NEW: Fetch periods with ratio data for a company using optimized dashboard endpoint
export const getCompanyPeriodsWithRatios = async (companyId: number): Promise<PeriodWithRatiosData[]> => {
  try {
    const url = createApiUrl(`api/dashboard/?company=${companyId}&period=all&include_ratios=true`);
    console.log(`Fetching periods with ratios from: ${url}`);
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    
    console.log("Dashboard API response:", response.data);
    
    // Extract periods from company_data response
    if (response.data?.data?.company_data && response.data.data.company_data.length > 0) {
      const periods = response.data.data.company_data[0]?.periods || [];
      console.log(`Extracted ${periods.length} periods from dashboard API`);
      periods.forEach((p: any, idx: number) => {
        console.log(`Period ${idx}:`, { label: p.label, has_ratios: !!p.ratios, ratios_keys: p.ratios ? Object.keys(p.ratios) : [] });
      });
      return periods;
    }
    console.warn("No company_data found in dashboard response");
    return [];
  } catch (error: any) {
    console.error(`Error fetching periods with ratios for company ${companyId}:`, error);
    console.error("Error response data:", error?.response?.data);
    throw error;
  }
};

// Fetch lightweight period list for a specific company (minimal fields only - no financial data)
// NOTE: This now returns periods WITH ratio data loaded from the optimized dashboard endpoint
export const getCompanyPeriodsList = async (companyId: number): Promise<PeriodWithRatiosData[]> => {
  try {
    // Use the optimized dashboard endpoint with include_ratios to get all needed data in one call
    const periodsWithRatios = await getCompanyPeriodsWithRatios(companyId);
    
    // Return the periods with ratios already loaded
    // This eliminates the need for a second API call when a period is selected
    return periodsWithRatios;
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
    // Use dashboard endpoint to get detailed ratio data across all periods
    // Pass category parameter for filtering if provided
    let url = createApiUrl(`api/dashboard/?company=${companyId}&period=all&include_ratios=true`);
    if (category) {
      url += `&category=${encodeURIComponent(category)}`;
    }
    
    console.log(`Fetching trend data from: ${url}`);
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    
    console.log("Trend data API response:", response.data);
    
    // Extract periods from company_data response
    if (response.data?.data?.company_data && response.data.data.company_data.length > 0) {
      const periods = response.data.data.company_data[0]?.periods || [];
      console.log(`Trend data: Extracted ${periods.length} periods`);
      
      // Filter periods with ratio data AND transform to flat structure
      // Chart expects: { period: id, stock_turnover: value, ... }
      // Not: { id, label, ratios: { stock_turnover: value, ... } }
      const trendData = periods
        .filter((p: any) => p.ratios != null)
        .map((p: any) => ({
          period: p.id,
          period_label: p.label,
          ...p.ratios  // Flatten ratio fields into root object
        }));
      
      console.log(`Trend data: Flattened to ${trendData.length} periods for chart`);
      console.log("Transformed trend data:", trendData);
      
      return trendData;
    }
    
    console.warn("No company_data found in trend data response");
    return [];
  } catch (error: any) {
    console.error("Error fetching ratio trends:", error);
    console.error("Error response data:", error?.response?.data);
    throw error;
  }
};
