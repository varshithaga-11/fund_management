import React, { useState } from "react";
import { createCompany, CompanyFormData, CompanyData } from "./api";
import Button from "../../components/ui/button/Button";
import Input from "../../components/form/input/InputField";
import Label from "../../components/form/Label";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

interface AddCompanyProps {
  onClose: () => void;
  onAdd: (newCompany: CompanyData) => void;
}

const AddCompany: React.FC<AddCompanyProps> = ({ onClose, onAdd }) => {
  const [name, setName] = useState("");
  const [registrationNo, setRegistrationNo] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!name || !registrationNo) {
      toast.error("Please fill all required fields");
      return;
    }

    const newCompany: CompanyFormData = {
      name: name,
      registration_no: registrationNo,
    };

    setLoading(true);
    try {
      const createdCompany = await createCompany(newCompany);
      toast.success("Company created successfully!");

      setTimeout(() => {
        onAdd(createdCompany);
        onClose();
      }, 1200);
    } catch (err: any) {
      console.error("Error creating company:", err);
      if (err.response?.data) {
        Object.values(err.response.data).forEach((msg: any) => {
          toast.error(Array.isArray(msg) ? msg[0] : msg);
        });
      } else {
        toast.error(err.message || "Failed to create company");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-white/50 backdrop-blur-sm flex items-center justify-center z-50">
      <ToastContainer position="bottom-right" autoClose={3000} />

      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 w-full max-w-md relative mt-24">
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-3 right-3 w-10 h-10 flex items-center justify-center rounded-full text-gray-500 hover:text-gray-800 dark:hover:text-gray-200 text-4xl font-bold"
        >
          ×
        </button>

        <h2 className="text-2xl font-bold mb-4 text-gray-900 dark:text-white">
          Add New Company
        </h2>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Company Name */}
          <div>
            <Label htmlFor="name">Company Name *</Label>
            <Input
              id="name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
              disabled={loading}
            />
          </div>

          {/* Registration Number */}
          <div>
            <Label htmlFor="registrationNo">Registration Number *</Label>
            <Input
              id="registrationNo"
              type="text"
              value={registrationNo}
              onChange={(e) => setRegistrationNo(e.target.value)}
              required
              disabled={loading}
            />
          </div>

          {/* Buttons */}
          <div className="flex justify-end gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={onClose}
              disabled={loading}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? "Saving..." : "Save"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AddCompany;
