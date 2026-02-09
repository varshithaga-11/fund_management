import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { getCompanyList, CompanyData } from "../Companies/api";
import Button from "../../components/ui/button/Button";
import Select from "../../components/form/Select";
import Label from "../../components/form/Label";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import { uploadExcelData } from "./api";

const UploadDataPage: React.FC = () => {
  const navigate = useNavigate();
  const [companies, setCompanies] = useState<CompanyData[]>([]);
  const [selectedCompany, setSelectedCompany] = useState<number | null>(null);
  const [file, setFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    loadCompanies();
  }, []);

  const loadCompanies = async () => {
    try {
      const data = await getCompanyList();
      setCompanies(data);
    } catch (error) {
      console.error("Error loading companies:", error);
      toast.error("Failed to load companies");
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const selectedFile = e.target.files[0];
      // Validate file type
      if (
        !selectedFile.name.endsWith(".xlsx") &&
        !selectedFile.name.endsWith(".xls")
      ) {
        toast.error("Please upload a valid Excel file (.xlsx or .xls)");
        return;
      }
      setFile(selectedFile);
    }
  };

  const handleCompanyChange = (value: string) => {
    setSelectedCompany(parseInt(value));
  };

  const handleUpload = async () => {
    if (!file) {
      toast.error("Please select an Excel file");
      return;
    }

    if (!selectedCompany) {
      toast.error("Please select a company");
      return;
    }

    setUploading(true);
    try {
      const formData = new FormData();
      formData.append("file", file);
      formData.append("company_id", selectedCompany.toString());

      const result = await uploadExcelData(formData);
      
      toast.success("Data uploaded successfully!");
      
      // Navigate to the financial period page
      if (result.period_id) {
        setTimeout(() => {
          navigate(`/financial-statements/${result.period_id}`);
        }, 1500);
      }
    } catch (error: any) {
      console.error("Error uploading file:", error);
      if (error.response?.data?.message) {
        toast.error(error.response.data.message);
      } else {
        toast.error("Failed to upload Excel file. Please check the file format.");
      }
    } finally {
      setUploading(false);
    }
  };

  const companyOptions = companies.map((company) => ({
    value: company.id.toString(),
    label: company.name,
  }));

  return (
    <div className="p-6 space-y-6">
      <ToastContainer position="bottom-right" autoClose={3000} />
      
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Upload Financial Data
        </h1>
        <p className="text-sm text-gray-600 dark:text-gray-400 mt-2">
          Upload an Excel file containing Balance Sheet, Profit & Loss, Trading Account, and Operational Metrics
        </p>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 space-y-6">
        {/* File Upload Section */}
        <div>
          <Label htmlFor="excel-file">Excel File *</Label>
          <div className="mt-2">
            <input
              id="excel-file"
              type="file"
              accept=".xlsx,.xls"
              onChange={handleFileChange}
              className="block w-full text-sm text-gray-500
                file:mr-4 file:py-2 file:px-4
                file:rounded-lg file:border-0
                file:text-sm file:font-semibold
                file:bg-brand-50 file:text-brand-700
                hover:file:bg-brand-100
                dark:file:bg-brand-900/20 dark:file:text-brand-400
                dark:hover:file:bg-brand-900/30
                cursor-pointer"
              disabled={uploading}
            />
            {file && (
              <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
                Selected: {file.name}
              </p>
            )}
          </div>
          <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
            Supported formats: .xlsx, .xls
          </p>
        </div>

        {/* Company Selection */}
        <div>
          <Label htmlFor="company">Select Company *</Label>
          <Select
            id="company"
            options={companyOptions}
            placeholder="Select a company"
            onChange={handleCompanyChange}
            className="mt-2 dark:bg-dark-900"
            disabled={uploading}
          />
        </div>

        {/* Excel Format Instructions */}
        <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
          <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-2">
            Excel File Format Requirements:
          </h3>
          <ul className="text-xs text-gray-700 dark:text-gray-300 space-y-1 list-disc list-inside">
            <li>The Excel file must contain 4 sheets with exact names:</li>
            <li className="ml-4">1. <strong>Balance Sheet</strong> - Liabilities and Assets</li>
            <li className="ml-4">2. <strong>Profit and Loss</strong> - Income and Expenses</li>
            <li className="ml-4">3. <strong>Trading Account</strong> - Trading data</li>
            <li className="ml-4">4. <strong>Operational Metrics</strong> - Staff count</li>
            <li>Column headers should match the field names exactly</li>
            <li>Data should start from row 2 (row 1 should be headers)</li>
          </ul>
        </div>

        {/* Upload Button */}
        <div className="flex justify-end">
          <Button
            onClick={handleUpload}
            disabled={!file || !selectedCompany || uploading}
          >
            {uploading ? "Uploading..." : "Upload & Process"}
          </Button>
        </div>
      </div>

      {/* Sample Format Info */}
      <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
        <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-2">
          Expected Sheet Structures:
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs text-gray-600 dark:text-gray-400">
          <div>
            <strong>Balance Sheet:</strong> Share Capital, Deposits, Borrowings, Reserves, UDP, Provisions, Other Liabilities, Cash in Hand, Cash at Bank, Investments, Loans & Advances, Fixed Assets, Other Assets, Stock in Trade
          </div>
          <div>
            <strong>Profit and Loss:</strong> Interest on Loans, Interest on Bank A/c, Return on Investment, Miscellaneous Income, Interest on Deposits, Interest on Borrowings, Establishment & Contingencies, Provisions, Net Profit
          </div>
          <div>
            <strong>Trading Account:</strong> Opening Stock, Purchases, Trade Charges, Sales, Closing Stock
          </div>
          <div>
            <strong>Operational Metrics:</strong> Staff Count
          </div>
        </div>
      </div>
    </div>
  );
};

export default UploadDataPage;
