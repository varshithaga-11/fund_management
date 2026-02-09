import React, { useEffect, useState } from "react";
import { getSupplierById, updateSupplier, SupplierData, SupplierFormData } from "./api";
import Button from "../../../components/ui/button/Button";
import Input from "../../../components/form/input/InputField";
import Label from "../../../components/form/Label";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

interface EditSupplierProps {
  supplierId: number;
  isOpen: boolean;
  onClose: () => void;
  onUpdated: () => void;
}

const EditSupplier: React.FC<EditSupplierProps> = ({ supplierId, isOpen, onClose, onUpdated }) => {
  const [supplierData, setSupplierData] = useState<Partial<SupplierFormData>>({});
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  // Fetch supplier data when modal opens
  useEffect(() => {
    if (!isOpen) return;

    setLoading(true);
    setError("");
    getSupplierById(supplierId)
      .then((data) => setSupplierData(data))
      .catch(() => setError("Failed to load supplier data"))
      .finally(() => setLoading(false));
  }, [isOpen, supplierId]);

  const handleChange = (field: keyof SupplierFormData, value: any) => {
    setSupplierData((prev) => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    setSaving(true);
    try {
      await updateSupplier(supplierId, supplierData as Partial<SupplierFormData>);
      toast.success("Supplier updated successfully!");

      setTimeout(() => {
        onUpdated();
        onClose();
      }, 1500);
    } catch (err: any) {
      console.error("Error updating supplier:", err);
      if (err.response?.data) {
        Object.values(err.response.data).forEach((msg: any) => {
          toast.error(Array.isArray(msg) ? msg[0] : msg);
        });
      } else {
        toast.error(err.message || "Failed to update supplier");
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
          Loading supplier data...
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
        <button
          onClick={onClose}
          className="absolute top-3 right-3 w-10 h-10 flex items-center justify-center rounded-full 
                    text-gray-500 hover:text-gray-800 dark:hover:text-gray-200 text-4xl font-bold"
        >
          ×
        </button>

        <h2 className="text-2xl font-bold mb-4 text-gray-900 dark:text-white">
          Edit Supplier
        </h2>

        {error && <p className="text-red-600 mb-2">{error}</p>}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="companyName">Company Name *</Label>
            <Input
              id="companyName"
              type="text"
              value={supplierData.company_name || ""}
              onChange={(e) => handleChange("company_name", e.target.value)}
              required
              disabled={saving}
            />
          </div>

          <div>
            <Label htmlFor="supplierName">Supplier Name *</Label>
            <Input
              id="supplierName"
              type="text"
              value={supplierData.supplier_name || ""}
              onChange={(e) => handleChange("supplier_name", e.target.value)}
              required
              disabled={saving}
            />
          </div>

          <div>
            <Label htmlFor="gstId">GST ID</Label>
            <Input
              id="gstId"
              type="text"
              value={supplierData.gst_id || ""}
              onChange={(e) => handleChange("gst_id", e.target.value)}
              disabled={saving}
            />
          </div>

          <div>
            <Label htmlFor="gstNumber">GST Number *</Label>
            <Input
              id="gstNumber"
              type="text"
              value={supplierData.gst_number || ""}
              onChange={(e) => handleChange("gst_number", e.target.value)}
              required
              disabled={saving}
            />
          </div>

          <div>
            <Label htmlFor="mobileNumber">Mobile Number</Label>
            <Input
              id="mobileNumber"
              type="text"
              value={supplierData.mobile_number || ""}
              onChange={(e) => handleChange("mobile_number", e.target.value)}
              disabled={saving}
            />
          </div>

          <div>
            <Label htmlFor="address">Address</Label>
            <Input
              id="address"
              type="text"
              value={supplierData.address || ""}
              onChange={(e) => handleChange("address", e.target.value)}
              disabled={saving}
            />
          </div>

          <div>
            <Label htmlFor="email">Email *</Label>
            <Input
              id="email"
              type="email"
              value={supplierData.email_id || ""}
              onChange={(e) => handleChange("email_id", e.target.value)}
              required
              disabled={saving}
            />
          </div>

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

export default EditSupplier;
