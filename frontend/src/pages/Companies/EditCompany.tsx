import React, { useEffect, useState } from "react";
import {
  getCompanyById,
  updateCompany,
  CompanyData,
  CompanyFormData,
} from "./api";
import Button from "../../components/ui/button/Button";
import Input from "../../components/form/input/InputField";
import Label from "../../components/form/Label";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

interface EditCompanyProps {
  companyId: number;
  isOpen: boolean;
  onClose: () => void;
  onUpdated: () => void;
}

const EditCompany: React.FC<EditCompanyProps> = ({
  companyId,
  isOpen,
  onClose,
  onUpdated,
}) => {
  const [companyData, setCompanyData] = useState<Partial<CompanyFormData>>({});
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  // Fetch company data when modal opens
  useEffect(() => {
    if (!isOpen) return;

    setLoading(true);
    setError("");

    getCompanyById(companyId)
      .then((data: CompanyData) => {
        setCompanyData({
          name: data.name,
          registration_no: data.registration_no,
        });
      })
      .catch(() => setError("Failed to load company data"))
      .finally(() => setLoading(false));
  }, [isOpen, companyId]);

  const handleChange = (field: keyof CompanyFormData, value: any) => {
    setCompanyData((prev) => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    setSaving(true);
    try {
      await updateCompany(companyId, companyData);
      toast.success("Company updated successfully!");

      setTimeout(() => {
        onUpdated();
        onClose();
      }, 1200);
    } catch (err: any) {
      console.error("Error updating company:", err);
      if (err.response?.data) {
        Object.values(err.response.data).forEach((msg: any) => {
          toast.error(Array.isArray(msg) ? msg[0] : msg);
        });
      } else {
        toast.error(err.message || "Failed to update company");
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
          Loading company data...
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-white/50 backdrop-blur-sm flex items-center justify-center z-50">
      <ToastContainer position="bottom-right" autoClose={3000} />

      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 w-full max-w-md relative mt-24">
        {/* Close button */}
        <button
          onClick={onClose}
          className="absolute top-3 right-3 w-10 h-10 flex items-center justify-center rounded-full 
                     text-gray-500 hover:text-gray-800 dark:hover:text-gray-200 text-4xl font-bold"
        >
          ×
        </button>

        <h2 className="text-2xl font-bold mb-4 text-gray-900 dark:text-white">
          Edit Company
        </h2>

        {error && <p className="text-red-600 mb-2">{error}</p>}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Company Name */}
          <div>
            <Label htmlFor="name">Company Name *</Label>
            <Input
              id="name"
              type="text"
              value={companyData.name || ""}
              onChange={(e) => handleChange("name", e.target.value)}
              required
              disabled={saving}
            />
          </div>

          {/* Registration Number */}
          <div>
            <Label htmlFor="registrationNo">Registration Number *</Label>
            <Input
              id="registrationNo"
              type="text"
              value={companyData.registration_no || ""}
              onChange={(e) =>
                handleChange("registration_no", e.target.value)
              }
              required
              disabled={saving}
            />
          </div>

          {/* Buttons */}
          <div className="flex justify-end gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={onClose}
              disabled={saving}
            >
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

export default EditCompany;
