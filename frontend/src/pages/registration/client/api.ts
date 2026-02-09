import { createApiUrl, getAuthHeaders } from "../../../access/access.ts";
import axios from "axios";

// -------------------- Interfaces --------------------

export interface ClientData {
  id: number;
  company_name: string;
  registration_number: string;
  company_address: string;
  gst_number: string;
  capax_id: string;
  mobile_number: string;
  email: string;
  contact_person_name: string;
  contact_person_phone: string;
  contact_person_email: string;
}

export interface ClientFormData {
  company_name: string;
  company_address: string;
  gst_number: string;
  capax_id: string;
  mobile_number: string;
  email: string;
  contact_person_name: string;
  contact_person_phone: string;
  contact_person_email: string;
}

// -------------------- API Calls --------------------

// ✅ Fetch all clients
export const getClientList = async (): Promise<ClientData[]> => {
  try {
    const url = createApiUrl("api/clients/");
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    console.log("Client list:", response.data);
    return response.data;
  } catch (error) {
    console.error("Error fetching client list:", error);
    throw error;
  }
};

// ✅ Fetch client by ID
export const getClientById = async (id: number): Promise<ClientData> => {
  try {
    const url = createApiUrl(`api/clients/${id}/`);
    const response = await axios.get(url, {
      headers: await getAuthHeaders(),
    });
    console.log(`Fetched client ID ${id}:`, response.data);
    return response.data;
  } catch (error) {
    console.error(`Error fetching client with ID ${id}:`, error);
    throw error;
  }
};

// ✅ Create new client
export const createClient = async (data: ClientFormData): Promise<ClientData> => {
  try {
    const url = createApiUrl("api/clients/");
    const response = await axios.post(url, data, {
      headers: await getAuthHeaders(),
    });
    console.log("Client created:", response.data);
    return response.data;
  } catch (error) {
    console.error("Error creating client:", error);
    throw error;
  }
};

// ✅ Update client
export const updateClient = async (
  id: number,
  data: Partial<ClientFormData>
): Promise<ClientData> => {
  try {
    const url = createApiUrl(`api/clients/${id}/`);
    const response = await axios.put(url, data, {
      headers: await getAuthHeaders(),
    });
    console.log("Client updated:", response.data);
    return response.data;
  } catch (error) {
    console.error("Error updating client:", error);
    throw error;
  }
};

// ✅ Delete client
export const deleteClient = async (id: number): Promise<void> => {
  try {
    const url = createApiUrl(`api/clients/${id}/`);
    await axios.delete(url, {
      headers: await getAuthHeaders(),
    });
    console.log(`Client ${id} deleted successfully`);
  } catch (error) {
    console.error("Error deleting client:", error);
    throw error;
  }
};
