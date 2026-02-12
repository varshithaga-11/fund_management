import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { getCompanyList, CompanyData } from "../Companies/api";
import Button from "../../components/ui/button/Button";
import Select from "../../components/form/Select";
import Label from "../../components/form/Label";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import { uploadExcelData, downloadExcelTemplate, downloadWordTemplate } from "./api";
import { Download } from "lucide-react";

const UploadDataPage: React.FC = () => {
  const navigate = useNavigate();
  const [companies, setCompanies] = useState<CompanyData[]>([]);
  const [selectedCompany, setSelectedCompany] = useState<number | null>(null);
  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [downloadingTemplate, setDownloadingTemplate] = useState<string | null>(null);

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

  const ACCEPTED_EXTENSIONS = [".xlsx", ".xls", ".docx", ".pdf"];
  const isAcceptedFile = (name: string) =>
    ACCEPTED_EXTENSIONS.some((ext) => name.toLowerCase().endsWith(ext));

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const selectedFile = e.target.files[0];
      if (!isAcceptedFile(selectedFile.name)) {
        toast.error("Please upload a valid file (.xlsx, .xls, .docx, or .pdf)");
        return;
      }
      setFile(selectedFile);
    }
  };

  const handleCompanyChange = (value: string) => {
    setSelectedCompany(parseInt(value));
  };

  const handleDownloadExcelTemplate = async () => {
    try {
      setDownloadingTemplate("excel");
      await downloadExcelTemplate();
      toast.success("Excel template downloaded successfully!");
    } catch (error: any) {
      console.error("Error downloading Excel template:", error);
      toast.error(error?.response?.data?.message || "Failed to download Excel template");
    } finally {
      setDownloadingTemplate(null);
    }
  };

  const handleDownloadWordTemplate = async () => {
    try {
      setDownloadingTemplate("word");
      await downloadWordTemplate();
      toast.success("Word template downloaded successfully!");
    } catch (error: any) {
      console.error("Error downloading Word template:", error);
      toast.error(error?.response?.data?.message || "Failed to download Word template");
    } finally {
      setDownloadingTemplate(null);
    }
  };

  const handleUpload = async () => {
    if (!file) {
      toast.error("Please select a file (Excel, Word, or PDF)");
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
      const message =
        error.response?.data?.message ??
        (typeof error.response?.data === "string" ? error.response.data : null) ??
        error.message;
      const displayMessage = message
        ? String(message)
        : "Failed to upload file. Please check the file format.";
      toast.error(displayMessage, { autoClose: 10000 });
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
          Upload an Excel file (.xlsx, .xls), Word document (.docx), or PDF for financial data or statements
        </p>
        
        {/* Download Template Buttons */}
        <div className="mt-4 flex gap-3">
          <button
            onClick={handleDownloadExcelTemplate}
            disabled={downloadingTemplate !== null}
            className="flex items-center gap-2 px-4 py-2 bg-green-600 hover:bg-green-700 dark:bg-green-500 dark:hover:bg-green-600 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
          >
            <Download className="w-4 h-4" />
            {downloadingTemplate === "excel" ? "Downloading..." : "Download Excel Template"}
          </button>
          <button
            onClick={handleDownloadWordTemplate}
            disabled={downloadingTemplate !== null}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
          >
            <Download className="w-4 h-4" />
            {downloadingTemplate === "word" ? "Downloading..." : "Download Word Template"}
          </button>
        </div>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 space-y-6">
        {/* File Upload Section */}
        <div>
          <Label htmlFor="upload-file">File (Excel, Word, or PDF) *</Label>
          <div className="mt-2">
            <input
              id="upload-file"
              type="file"
              accept=".xlsx,.xls,.docx,.pdf"
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
            Supported formats: .xlsx, .xls (Excel), .docx (Word), .pdf
          </p>
        </div>

        {/* Company Selection */}
        <div>
          <Label htmlFor="company">Select Company *</Label>
          <Select
            options={companyOptions}
            placeholder="Select a company"
            onChange={handleCompanyChange}
            className="mt-2 dark:bg-dark-900"
            disabled={uploading}
          />
        </div>

        {/* Period label – India FY (Apr–Mar) */}
        <div className="bg-amber-50 dark:bg-amber-900/20 rounded-lg p-4 border border-amber-200 dark:border-amber-800">
          <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-2">
            Filename = Period (India FY Apr–Mar)
          </h3>
          <p className="text-xs text-gray-600 dark:text-gray-400 mb-2">
            Name the file to auto-detect period. Use <code className="px-1 py-0.5 bg-amber-100 dark:bg-amber-800 rounded">_</code> format:
          </p>
          <div className="text-xs text-gray-700 dark:text-gray-300 space-y-1">
            <div><strong>MONTHLY:</strong> Apr_2024, May_2024, Jun_2024, Jul_2024, Aug_2024, Sep_2024, Oct_2024, Nov_2024, Dec_2024, Jan_2025, Feb_2025, Mar_2025</div>
            <div><strong>QUARTERLY:</strong> Q1_FY_2024_25, Q2_FY_2024_25, Q3_FY_2024_25, Q4_FY_2024_25</div>
            <div><strong>HALF YEARLY:</strong> H1_FY_2024_25, H2_FY_2024_25</div>
            <div><strong>YEARLY:</strong> FY_2024_25</div>
          </div>
        </div>

        {/* Excel Format Instructions */}
        <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
          <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-2">
            Excel File Format (recommended – 5 sheets):
          </h3>
          <ul className="text-xs text-gray-700 dark:text-gray-300 space-y-1 list-disc list-inside">
            <li><strong>Financial_Statement</strong> – Entity Name, Fiscal Year End, Currency, Staff Count</li>
            <li><strong>Balance_Sheet_Liabilities</strong> – Liability Type, Amount (e.g. Share Capital, Deposits, Borrowings, Reserves, Provisions, Other Liabilities, Undistributed Profit)</li>
            <li><strong>Balance_Sheet_Assets</strong> – Asset Type, Amount (e.g. Cash in Hand, Cash at Bank, Investments, Loans &amp; Advances, Fixed Assets, Other Assets, Stock in Trade)</li>
            <li><strong>Profit_Loss</strong> – Category, Item, Amount (Income / Expense / Net Profit rows)</li>
            <li><strong>Trading_Account</strong> – Item, Amount (Opening Stock, Purchases, Trade Charges, Sales, Closing Stock)</li>
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
          Expected Sheet Structures (5-sheet format):
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs text-gray-600 dark:text-gray-400">
          <div>
            <strong>Financial_Statement:</strong> Entity Name, Fiscal Year End, Currency, Staff Count
          </div>
          <div>
            <strong>Balance_Sheet_Liabilities:</strong> Liability Type, Amount (one row per liability)
          </div>
          <div>
            <strong>Balance_Sheet_Assets:</strong> Asset Type, Amount (one row per asset)
          </div>
          <div>
            <strong>Profit_Loss:</strong> Category, Item, Amount (Income / Expense / Net Profit)
          </div>
          <div>
            <strong>Trading_Account:</strong> Item, Amount (Opening Stock, Purchases, Trade Charges, Sales, Closing Stock)
          </div>
        </div>
      </div>
    </div>
  );
};

export default UploadDataPage;
