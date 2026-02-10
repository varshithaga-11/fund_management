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
