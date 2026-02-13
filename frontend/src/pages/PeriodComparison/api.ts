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

export interface RatioComparison {
  period1: number | null;
  period2: number | null;
  difference: number | null;
  percentage_change: number | null;
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

// Compare periods for a company
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
