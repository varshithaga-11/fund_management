import React, { useState } from "react";
import { createClient, ClientFormData,ClientData } from "./api";
import Button from "../../../components/ui/button/Button";
import Input from "../../../components/form/input/InputField";
import Label from "../../../components/form/Label";
import { toast, ToastContainer } from "react-toastify";
import 'react-toastify/dist/ReactToastify.css';

interface AddClientProps {
  onClose: () => void;
  onAdd: (newClient: ClientData) => void;
}

const AddClient: React.FC<AddClientProps> = ({ onClose, onAdd }) => {
  const [companyName, setCompanyName] = useState("");
  const [companyAddress, setCompanyAddress] = useState("");
  const [gstNumber, setGstNumber] = useState("");
  const [capaxId, setCapaxId] = useState("");
  const [mobileNumber, setMobileNumber] = useState("");
  const [email, setEmail] = useState("");
  const [contactName, setContactName] = useState("");
  const [contactPhone, setContactPhone] = useState("");
  const [contactEmail, setContactEmail] = useState("");

  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Basic validation
    if (!companyName || !email || !gstNumber || !capaxId) {
      toast.error("Please fill all required fields");
      return;
    }

    const newClient: ClientFormData = {
      company_name: companyName,
      company_address: companyAddress,
      gst_number: gstNumber,
      capax_id: capaxId,
      mobile_number: mobileNumber,
      email: email,
      contact_person_name: contactName,
      contact_person_phone: contactPhone,
      contact_person_email: contactEmail,
    };

    setLoading(true);
    try {
      const createdClient = await createClient(newClient);
      toast.success("Client created successfully!");

      setTimeout(() => {
        onAdd(createdClient);
        onClose();
      }, 1500);
    } catch (err: any) {
      console.error("Error creating client:", err);
      if (err.response?.data) {
        Object.values(err.response.data).forEach((msg: any) => {
          toast.error(Array.isArray(msg) ? msg[0] : msg);
        });
      } else {
        toast.error(err.message || "Failed to create client");
      }
    } finally {
      setLoading(false);
    }
  };

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
          className="absolute top-3 right-3 w-10 h-10 flex items-center justify-center rounded-full text-gray-500 hover:text-gray-800 dark:hover:text-gray-200 text-4xl font-bold"
        >
          ×
        </button>

        <h2 className="text-2xl font-bold mb-4 text-gray-900 dark:text-white">
          Add New Client
        </h2>

        <form onSubmit={handleSubmit} className="space-y-4">

          {/* Company Name */}
          <div>
            <Label htmlFor="companyName">Company Name *</Label>
            <Input
              id="companyName"
              type="text"
              value={companyName}
              onChange={(e) => setCompanyName(e.target.value)}
              required
              disabled={loading}
            />
          </div>

          {/* Company Address */}
          <div>
            <Label htmlFor="companyAddress">Company Address</Label>
            <Input
              id="companyAddress"
              type="text"
              value={companyAddress}
              onChange={(e) => setCompanyAddress(e.target.value)}
              disabled={loading}
            />
          </div>

          {/* GST Number */}
          <div>
            <Label htmlFor="gstNumber">GST Number *</Label>
            <Input
              id="gstNumber"
              type="text"
              value={gstNumber}
              onChange={(e) => setGstNumber(e.target.value)}
              required
              disabled={loading}
            />
          </div>

          {/* Capax ID */}
          <div>
            <Label htmlFor="capaxId">Capax ID *</Label>
            <Input
              id="capaxId"
              type="text"
              value={capaxId}
              onChange={(e) => setCapaxId(e.target.value)}
              required
              disabled={loading}
            />
          </div>

          {/* Mobile Number */}
          <div>
            <Label htmlFor="mobileNumber">Mobile Number</Label>
            <Input
              id="mobileNumber"
              type="text"
              value={mobileNumber}
              onChange={(e) => setMobileNumber(e.target.value)}
              disabled={loading}
            />
          </div>

          {/* Email */}
          <div>
            <Label htmlFor="email">Email *</Label>
            <Input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              disabled={loading}
            />
          </div>

          {/* Contact Person Name */}
          <div>
            <Label htmlFor="contactName">Contact Person Name</Label>
            <Input
              id="contactName"
              type="text"
              value={contactName}
              onChange={(e) => setContactName(e.target.value)}
              disabled={loading}
            />
          </div>

          {/* Contact Phone */}
          <div>
            <Label htmlFor="contactPhone">Contact Person Phone</Label>
            <Input
              id="contactPhone"
              type="text"
              value={contactPhone}
              onChange={(e) => setContactPhone(e.target.value)}
              disabled={loading}
            />
          </div>

          {/* Contact Email */}
          <div>
            <Label htmlFor="contactEmail">Contact Person Email</Label>
            <Input
              id="contactEmail"
              type="email"
              value={contactEmail}
              onChange={(e) => setContactEmail(e.target.value)}
              disabled={loading}
            />
          </div>

          {/* Buttons */}
          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose} disabled={loading}>
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

export default AddClient;
