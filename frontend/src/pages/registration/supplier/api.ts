import { createApiUrl, getAuthHeaders } from "../../../access/access.ts";
import axios from "axios";

export interface SupplierData {
  id: number;
  registration_number: string;
  company_name: string;
  supplier_name: string;
  gst_id: string;
  gst_number: string;
  mobile_number: string;
  address: string;
  email_id: string;
}

export interface SupplierFormData {
  company_name: string;
  supplier_name: string;
  gst_id: string;
  gst_number: string;
  mobile_number: string;
  address: string;
  email_id: string;
}

// -------------------- Existing --------------------

// Get all suppliers
export const getSupplierList = async (): Promise<SupplierData[]> => {
  try {
    const url = createApiUrl("api/suppliers/");
    const response = await axios.get(url, { headers: await getAuthHeaders() });
    return response.data;
  } catch (error) {
    console.error("Error fetching supplier list:", error);
    throw error;
  }
};

// Get supplier by ID
export const getSupplierById = async (id: number): Promise<SupplierData> => {
  try {
    const url = createApiUrl(`api/suppliers/${id}/`);
    const response = await axios.get(url, { headers: await getAuthHeaders() });
    return response.data;
  } catch (error) {
    console.error(`Error fetching supplier ${id}:`, error);
    throw error;
  }
};

// Create a new supplier
export const createSupplier = async (data: SupplierFormData): Promise<SupplierData> => {
  try {
    const url = createApiUrl("api/suppliers/");
    const response = await axios.post(url, data, { headers: await getAuthHeaders() });
    return response.data;
  } catch (error) {
    console.error("Error creating supplier:", error);
    throw error;
  }
};

// -------------------- New: Update Supplier --------------------
export const updateSupplier = async (id: number, data: Partial<SupplierFormData>): Promise<SupplierData> => {
  try {
    const url = createApiUrl(`api/suppliers/${id}/`);
    const response = await axios.put(url, data, { headers: await getAuthHeaders() });
    console.log(`Supplier ${id} updated successfully`);
    return response.data;
  } catch (error) {
    console.error(`Error updating supplier ${id}:`, error);
    throw error;
  }
};

// -------------------- New: Delete Supplier --------------------
export const deleteSupplier = async (id: number): Promise<void> => {
  try {
    const url = createApiUrl(`api/suppliers/${id}/`);
    await axios.delete(url, { headers: await getAuthHeaders() });
    console.log(`Supplier ${id} deleted successfully`);
  } catch (error) {
    console.error(`Error deleting supplier ${id}:`, error);
    throw error;
  }
};
