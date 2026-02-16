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
// Note: When using the new CompanyAllPeriodsView endpoint, only id, label, start_date, end_date, period_type are returned
export interface PeriodListData {
  id: number;

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

    period1: string;
    period2: string;
    ratios: Record<string, RatioComparison>;
  };
}





// Fetch all periods
export const getPeriodsList = async (): Promise<PeriodListData[]> => {
  try {
    const url = createApiUrl(`api/financial-periods/`);
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

    // For standard ModelViewSet response (pagination)
    if (response.data?.results && Array.isArray(response.data.results)) {
      return response.data.results;
    }

    throw new Error("Invalid response structure");
  } catch (error: any) {
    console.error(`Error fetching period list:`, error);
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
  period1: string,
  period2: string
): Promise<PeriodComparisonResponse> => {
  try {
    const url = createApiUrl(
      `api/period-comparison/?period1=${encodeURIComponent(
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
