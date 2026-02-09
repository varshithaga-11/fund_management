import { createApiUrl, getAuthHeaders } from "../../access/access.ts";
import axios from "axios";

// -------------------- Interfaces --------------------

export interface CompanyData {
  id: number;
  name: string;
  registration_no: string;
  created_at: string;
}

export interface CompanyFormData {
  name: string;
  registration_no: string;
}

// -------------------- API Calls --------------------

// ✅ Fetch all companies
export const getCompanyList = async (): Promise<CompanyData[]> => {
  try {
    const url = createApiUrl("api/companies/");
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    console.log("Company list:", response.data);
    return response.data;
  } catch (error) {
    console.error("Error fetching company list:", error);
    throw error;
  }
};

// ✅ Fetch company by ID
export const getCompanyById = async (id: number): Promise<CompanyData> => {
  try {
    const url = createApiUrl(`api/companies/${id}/`);
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    console.log(`Fetched company ID ${id}:`, response.data);
    return response.data;
  } catch (error) {
    console.error(`Error fetching company with ID ${id}:`, error);
    throw error;
  }
};

// ✅ Create new company
export const createCompany = async (
  data: CompanyFormData
): Promise<CompanyData> => {
  try {
    const url = createApiUrl("api/companies/");
    const response = await axios.post(url, data, {
      headers: await getAuthHeaders(),
    });
    console.log("Company created:", response.data);
    return response.data;
  } catch (error) {
    console.error("Error creating company:", error);
    throw error;
  }
};

// ✅ Update company
export const updateCompany = async (
  id: number,
  data: Partial<CompanyFormData>
): Promise<CompanyData> => {
  try {
    const url = createApiUrl(`api/companies/${id}/`);
    const response = await axios.put(url, data, {
      headers: await getAuthHeaders(),
    });
    console.log("Company updated:", response.data);
    return response.data;
  } catch (error) {
    console.error("Error updating company:", error);
    throw error;
  }
};

// ✅ Delete company
export const deleteCompany = async (id: number): Promise<void> => {
  try {
    const url = createApiUrl(`api/companies/${id}/`);
    await axios.delete(url, {
      headers: await getAuthHeaders(),
    });
    console.log(`Company ${id} deleted successfully`);
  } catch (error) {
    console.error("Error deleting company:", error);
    throw error;
  }
};
