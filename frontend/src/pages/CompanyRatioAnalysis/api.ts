import { createApiUrl, getAuthHeaders } from "../../access/access.ts";
import axios from "axios";



export interface FinancialPeriodData {
  id: number;

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
// Fetch financial periods
export const getPeriods = async (): Promise<FinancialPeriodData[]> => {
  try {
    const url = createApiUrl("api/financial-periods/");
    console.log("Fetching from URL:", url);

    const headers = await getAuthHeaders();
    console.log("Using auth headers");

    const response = await axios.get(url, { headers });
    console.log("API Response:", response.data);

    return response.data;
  } catch (error: any) {
    console.error("Error fetching periods:", error);
    console.error("Error response:", error?.response?.data);
    console.error("Error status:", error?.response?.status);
    throw error;
  }
};

// Fetch financial periods for a specific company


// NEW: Fetch periods with ratio data using optimized dashboard endpoint
export const getPeriodsWithRatios = async (): Promise<PeriodWithRatiosData[]> => {
  try {
    const url = createApiUrl(`api/dashboard/?period=all&include_ratios=true`);
    console.log(`Fetching periods with ratios from: ${url}`);
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });

    console.log("Dashboard API response:", response.data);

    // Extract periods from response
    if (response.data?.data?.periods && response.data.data.periods.length > 0) {
      const periods = response.data.data.periods || [];
      console.log(`Extracted ${periods.length} periods from dashboard API`);
      periods.forEach((p: any, idx: number) => {
        console.log(`Period ${idx}:`, { label: p.label, has_ratios: !!p.ratios, ratios_keys: p.ratios ? Object.keys(p.ratios) : [] });
      });
      return periods;
    }
    console.warn("No periods found in dashboard response");
    return [];
  } catch (error: any) {
    console.error("Error fetching periods with ratios:", error);
    console.error("Error response data:", error?.response?.data);
    throw error;
  }
};

// Fetch lightweight period list (minimal fields only - no financial data)
// NOTE: This now returns periods WITH ratio data loaded from the optimized dashboard endpoint
export const getPeriodsList = async (): Promise<PeriodWithRatiosData[]> => {
  try {
    // Use the optimized dashboard endpoint with include_ratios to get all needed data in one call
    const periodsWithRatios = await getPeriodsWithRatios();

    // Return the periods with ratios already loaded
    // This eliminates the need for a second API call when a period is selected
    return periodsWithRatios;
  } catch (error: any) {
    console.error("Error fetching period list:", error);
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

// Fetch ratio trends, optionally filtered by category
export const getRatioTrends = async (
  category?: RatioCategory
): Promise<any[]> => {
  try {
    // Use dashboard endpoint to get detailed ratio data across all periods
    // Pass category parameter for filtering if provided
    let url = createApiUrl(`api/dashboard/?period=all&include_ratios=true`);
    if (category) {
      url += `&category=${encodeURIComponent(category)}`;
    }

    console.log(`Fetching trend data from: ${url}`);
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });

    console.log("Trend data API response:", response.data);

    // Extract periods from response
    if (response.data?.data?.periods && response.data.data.periods.length > 0) {
      const periods = response.data.data.periods || [];
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

    console.warn("No periods found in trend data response");
    return [];
  } catch (error: any) {
    console.error("Error fetching ratio trends:", error);
    console.error("Error response data:", error?.response?.data);
    throw error;
  }
};
