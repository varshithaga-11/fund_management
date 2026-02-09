import React, { useEffect, useState } from "react";
import { getClientById, updateClient, ClientData, ClientFormData } from "./api";
import Button from "../../../components/ui/button/Button";
import Input from "../../../components/form/input/InputField";
import Label from "../../../components/form/Label";
import { toast, ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

interface EditClientProps {
  clientId: number;
  isOpen: boolean;
  onClose: () => void;
  onUpdated: () => void;
}

const EditClient: React.FC<EditClientProps> = ({ clientId, isOpen, onClose, onUpdated }) => {
  const [clientData, setClientData] = useState<Partial<ClientFormData>>({});
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  // Fetch client data when modal opens
  useEffect(() => {
    if (!isOpen) return;

    setLoading(true);
    setError("");
    getClientById(clientId)
      .then((data) => setClientData(data))
      .catch(() => setError("Failed to load client data"))
      .finally(() => setLoading(false));
  }, [isOpen, clientId]);

  const handleChange = (field: keyof ClientFormData, value: any) => {
    setClientData((prev) => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    setSaving(true);
    try {
      await updateClient(clientId, clientData as Partial<ClientFormData>);
      toast.success("Client updated successfully!");

      setTimeout(() => {
        onUpdated();
        onClose();
      }, 1500);
    } catch (err: any) {
      console.error("Error updating client:", err);
      if (err.response?.data) {
        Object.values(err.response.data).forEach((msg: any) => {
          toast.error(Array.isArray(msg) ? msg[0] : msg);
        });
      } else {
        toast.error(err.message || "Failed to update client");
      }
    } finally {
      setSaving(false);
    }
  };

  if (!isOpen) return null;

  if (loading) {
    return (
      <div className="fixed inset-0 flex items-center justify-center bg-white/50 backdrop-blur-sm z-50">
        <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md text-black dark:text-white">
          Loading client data...
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-white/50 backdrop-blur-sm flex items-center justify-center z-50">
      <ToastContainer
        position="bottom-right"
        autoClose={3000}
        hideProgressBar={false}
        newestOnTop
        closeOnClick
        rtl={false}
        pauseOnFocusLoss
        draggable
        pauseOnHover
        theme="light"
      />

      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 w-full max-w-md max-h-[90vh] overflow-auto relative mt-24">
        {/* Close button */}
        <button
          onClick={onClose}
          className="absolute top-3 right-3 w-10 h-10 flex items-center justify-center rounded-full 
                    text-gray-500 hover:text-gray-800 dark:hover:text-gray-200 text-4xl font-bold"
        >
          ×
        </button>

        <h2 className="text-2xl font-bold mb-4 text-gray-900 dark:text-white">
          Edit Client
        </h2>

        {error && <p className="text-red-600 mb-2">{error}</p>}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Company Name */}
          <div>
            <Label htmlFor="companyName">Company Name *</Label>
            <Input
              id="companyName"
              type="text"
              value={clientData.company_name || ""}
              onChange={(e) => handleChange("company_name", e.target.value)}
              required
              disabled={saving}
            />
          </div>

          {/* Company Address */}
          <div>
            <Label htmlFor="companyAddress">Company Address</Label>
            <Input
              id="companyAddress"
              type="text"
              value={clientData.company_address || ""}
              onChange={(e) => handleChange("company_address", e.target.value)}
              disabled={saving}
            />
          </div>

          {/* GST Number */}
          <div>
            <Label htmlFor="gstNumber">GST Number *</Label>
            <Input
              id="gstNumber"
              type="text"
              value={clientData.gst_number || ""}
              onChange={(e) => handleChange("gst_number", e.target.value)}
              required
              disabled={saving}
            />
          </div>

          {/* Capax ID */}
          <div>
            <Label htmlFor="capaxId">Capax ID *</Label>
            <Input
              id="capaxId"
              type="text"
              value={clientData.capax_id || ""}
              onChange={(e) => handleChange("capax_id", e.target.value)}
              required
              disabled={saving}
            />
          </div>

          {/* Mobile Number */}
          <div>
            <Label htmlFor="mobileNumber">Mobile Number</Label>
            <Input
              id="mobileNumber"
              type="text"
              value={clientData.mobile_number || ""}
              onChange={(e) => handleChange("mobile_number", e.target.value)}
              disabled={saving}
            />
          </div>

          {/* Email */}
          <div>
            <Label htmlFor="email">Email *</Label>
            <Input
              id="email"
              type="email"
              value={clientData.email || ""}
              onChange={(e) => handleChange("email", e.target.value)}
              required
              disabled={saving}
            />
          </div>

          {/* Contact Person Name */}
          <div>
            <Label htmlFor="contactName">Contact Person Name</Label>
            <Input
              id="contactName"
              type="text"
              value={clientData.contact_person_name || ""}
              onChange={(e) => handleChange("contact_person_name", e.target.value)}
              disabled={saving}
            />
          </div>

          {/* Contact Phone */}
          <div>
            <Label htmlFor="contactPhone">Contact Person Phone</Label>
            <Input
              id="contactPhone"
              type="text"
              value={clientData.contact_person_phone || ""}
              onChange={(e) => handleChange("contact_person_phone", e.target.value)}
              disabled={saving}
            />
          </div>

          {/* Contact Email */}
          <div>
            <Label htmlFor="contactEmail">Contact Person Email</Label>
            <Input
              id="contactEmail"
              type="email"
              value={clientData.contact_person_email || ""}
              onChange={(e) => handleChange("contact_person_email", e.target.value)}
              disabled={saving}
            />
          </div>

          {/* Buttons */}
          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button type="submit" disabled={saving}>
              {saving ? "Saving..." : "Save"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default EditClient;
