import { useEffect, useState, useMemo, useRef } from "react";
import { FiTrash2, FiEdit, FiSearch, FiPlus, FiChevronLeft, FiChevronRight, FiBriefcase, FiUpload, FiDownload } from "react-icons/fi";
import { HiOutlineDocumentArrowUp, HiOutlineArrowDownTray, HiOutlineXMark } from "react-icons/hi2";
import { BeatLoader } from "react-spinners";
import { toast } from "react-toastify";
import * as XLSX from 'xlsx';
import PageBreadcrumb from "../../components/common/PageBreadCrumb";
import PageMeta from "../../components/common/PageMeta";
import {
  getCompanyList,
  deleteCompany,
  CompanyData,
  bulkImportCompanies,
  CompanyFormData,
} from "./api";
import {
  Table,
  TableBody,
  TableCell,
  TableHeader,
  TableRow,
} from "../../components/ui/table";
import Button from "../../components/ui/button/Button";
import Select from "../../components/form/Select";
import Label from "../../components/form/Label";
import EditCompany from "./EditCompany";
import AddCompany from "./AddCompany";
import { exportCompaniesToExcel, exportCompanyDetailsToPDF } from "../../utils/exportUtils";

// Type for Excel row data
type ExcelCompanyRow = CompanyFormData & {
  errors: string[];
};

const CompanyPage: React.FC = () => {
  const [companies, setCompanies] = useState<CompanyData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [isExporting, setIsExporting] = useState(false);

  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editCompanyId, setEditCompanyId] = useState<number | null>(null);

  const [isImportModalOpen, setIsImportModalOpen] = useState(false);
  const [excelData, setExcelData] = useState<ExcelCompanyRow[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [searchTerm, setSearchTerm] = useState("");
  const [sortField, setSortField] = useState<keyof CompanyData | null>(null);
  const [sortDirection, setSortDirection] = useState<"asc" | "desc">("asc");

  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);

  useEffect(() => {
    fetchCompanies();
  }, []);

  const fetchCompanies = async () => {
    try {
      const data = await getCompanyList();
      setCompanies(data);
    } catch (err: any) {
      setError(err.message || "Failed to fetch companies");
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!window.confirm("Are you sure you want to delete this company?")) return;

    try {
      await deleteCompany(id);
      setCompanies((prev) => prev.filter((c) => c.id !== id));
    } catch {
      alert("Failed to delete company");
    }
  };

  const handleExportToExcel = async () => {
    if (sortedCompanies.length === 0) {
      toast.warning("No companies to export");
      return;
    }

    try {
      setIsExporting(true);
      exportCompaniesToExcel(sortedCompanies, "Companies_List");
      toast.success("Companies exported to Excel successfully!");
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Failed to export to Excel");
    } finally {
      setIsExporting(false);
    }
  };


  const handleExportDetailsToPDF = async () => {
    if (sortedCompanies.length === 0) {
      toast.warning("No companies to export");
      return;
    }

    try {
      setIsExporting(true);
      exportCompanyDetailsToPDF(sortedCompanies, "Company_Details");
      toast.success("Company details exported to PDF successfully!");
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Failed to export company details");
    } finally {
      setIsExporting(false);
    }
  };

  const [excelFile, setExcelFile] = useState<File | null>(null);
  const [selectedRows, setSelectedRows] = useState<Set<number>>(new Set());

  // Handle Excel file selection
  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setExcelFile(file);
      setExcelData([]); // Clear previous data
      setSelectedRows(new Set());
    }
  };

  const handleSelectAll = () => {
    const validIndices = excelData
      .map((row, index) => (!row.errors || row.errors.length === 0) ? index : -1)
      .filter(index => index !== -1);

    if (selectedRows.size === validIndices.length && validIndices.length > 0) {
      setSelectedRows(new Set());
    } else {
      setSelectedRows(new Set(validIndices));
    }
  };

  const handleSelectRow = (index: number) => {
    if (excelData[index].errors && excelData[index].errors.length > 0) return;

    const newSelected = new Set(selectedRows);
    if (newSelected.has(index)) {
      newSelected.delete(index);
    } else {
      newSelected.add(index);
    }
    setSelectedRows(newSelected);
  };

  // Read Excel file and process data
  const handleImportExcel = async () => {
    if (!excelFile) {
      toast.error('Please select an Excel file first');
      return;
    }

    try {
      const reader = new FileReader();

      reader.onload = async (e) => {
        try {
          const data = e.target?.result;
          const workbook = XLSX.read(data, { type: 'binary' });
          const sheetName = workbook.SheetNames[0];
          const worksheet = workbook.Sheets[sheetName];
          const jsonData: any[] = XLSX.utils.sheet_to_json(worksheet);

          if (jsonData.length === 0) {
            toast.error('No data found in the Excel file');
            return;
          }

          // Create lookup maps for existing companies
          const existingRegMap = new Set(companies.map(c => c.registration_no.toLowerCase().trim()));
          const existingNameMap = new Set(companies.map(c => c.name.toLowerCase().trim()));

          // Process each row
          const processedData: ExcelCompanyRow[] = jsonData.map((row: any, index: number) => {
            const errors: string[] = [];

            // Helper to get value
            const getValue = (keys: string[]) => {
              for (const k of keys) {
                if (row[k] !== undefined) return String(row[k]).trim();
              }
              return '';
            };

            const name = getValue(['Company Name', 'name', 'Name', 'company_name']);
            const regNo = getValue(['Registration No', 'registration_no', 'Registration Number', 'Reg No']);

            const companyRow: ExcelCompanyRow = {
              name: name,
              registration_no: regNo,
              errors: [],
            };

            // Validation errors
            if (!companyRow.name) {
              errors.push(`Row ${index + 2}: Company Name is required`);
            } else if (existingNameMap.has(companyRow.name.toLowerCase())) {
              errors.push(`Row ${index + 2}: Company Name "${companyRow.name}" already exists`);
            }

            if (!companyRow.registration_no) {
              errors.push(`Row ${index + 2}: Registration No is required`);
            } else if (existingRegMap.has(companyRow.registration_no.toLowerCase())) {
              errors.push(`Row ${index + 2}: Registration No "${companyRow.registration_no}" already exists`);
            }

            companyRow.errors = errors;
            return companyRow;
          });

          setExcelData(processedData);

          // Pre-select all valid rows
          const validIndices = processedData
            .map((row, index) => (!row.errors || row.errors.length === 0) ? index : -1)
            .filter(index => index !== -1);
          setSelectedRows(new Set(validIndices));

          toast.success('Excel file processed successfully!');
        } catch (error) {
          toast.error('Error processing Excel data.');
          console.error('Error:', error);
        }
      };

      reader.onerror = () => {
        toast.error('Error reading Excel file');
      };

      reader.readAsBinaryString(excelFile);
    } catch (error) {
      toast.error('Error initiating file read');
      console.error('Error:', error);
    }
  };

  const handleDownloadTemplate = () => {
    try {
      const templateData = [
        {
          'Company Name': 'Example Company Ltd',
          'Registration No': 'ABC12345',
        },
      ];

      const worksheet = XLSX.utils.json_to_sheet(templateData);
      worksheet['!cols'] = [
        { wch: 30 },
        { wch: 20 },
      ];

      const workbook = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(workbook, worksheet, 'Companies');
      XLSX.writeFile(workbook, 'Company_Import_Template.xlsx');
      toast.success('Template downloaded successfully!');
    } catch (error) {
      toast.error('Failed to download template');
      console.error('Error:', error);
    }
  };

  const closeModal = () => {
    setIsImportModalOpen(false);
    setExcelData([]);
    setExcelFile(null);
    setSelectedRows(new Set());
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const handleBulkSubmit = async () => {
    if (selectedRows.size === 0) {
      toast.error('Please select at least one valid company to import.');
      return;
    }

    setIsUploading(true);
    try {
      // Filter only selected rows for submission
      const companiesToImport = excelData
        .filter((_, index) => selectedRows.has(index))
        .map(({ errors, ...rest }) => rest) as CompanyFormData[];

      const result = await bulkImportCompanies(companiesToImport);

      if (result.success > 0) {
        toast.success(`Successfully imported ${result.success} companies!`);
        await fetchCompanies();
        closeModal();
      }

      if (result.failed > 0) {
        toast.warning(`Failed to import ${result.failed} companies. Check console for details.`);
        console.error('Import errors:', result.errors);
      }
    } catch (error) {
      console.error('Bulk submit error:', error);
      toast.error(error instanceof Error ? error.message : 'Failed to import companies');
    } finally {
      setIsUploading(false);
    }
  };


  const handleCompanyAdded = (newCompany: CompanyData) => {
    setCompanies((prev) => [newCompany, ...prev]);
    setIsAddModalOpen(false);
  };

  const filteredCompanies = useMemo(() => {
    let filtered = companies;

    if (searchTerm) {
      filtered = filtered.filter(
        (c) =>
          c.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
          c.registration_no
            .toLowerCase()
            .includes(searchTerm.toLowerCase())
      );
    }

    return filtered;
  }, [companies, searchTerm]);

  const sortedCompanies = useMemo(() => {
    if (!sortField) return filteredCompanies;

    return [...filteredCompanies].sort((a, b) => {
      const aValue = a[sortField];
      const bValue = b[sortField];

      if (!aValue && !bValue) return 0;
      if (!aValue) return 1;
      if (!bValue) return -1;

      if (sortDirection === "asc") {
        return aValue < bValue ? -1 : aValue > bValue ? 1 : 0;
      } else {
        return aValue > bValue ? -1 : aValue < bValue ? 1 : 0;
      }
    });
  }, [filteredCompanies, sortField, sortDirection]);

  const paginatedCompanies = useMemo(() => {
    const start = (currentPage - 1) * pageSize;
    return sortedCompanies.slice(start, start + pageSize);
  }, [sortedCompanies, currentPage, pageSize]);

  const totalPages = Math.ceil(sortedCompanies.length / pageSize);

  const handleSort = (field: keyof CompanyData) => {
    if (sortField === field) {
      setSortDirection(sortDirection === "asc" ? "desc" : "asc");
    } else {
      setSortField(field);
      setSortDirection("asc");
    }
    setCurrentPage(1);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <BeatLoader color="#465fff" size={10} />
          <p className="mt-4 text-gray-600 dark:text-gray-400">Loading companies...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-lg border border-red-200 bg-red-50 dark:border-red-900 dark:bg-red-900/20 p-6">
        <div className="flex items-center gap-3">
          <div className="flex-shrink-0">
            <svg className="h-6 w-6 text-red-600 dark:text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <h3 className="text-lg font-semibold text-red-800 dark:text-red-300">Error</h3>
            <p className="text-red-700 dark:text-red-400">{error}</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <>
      <PageMeta title="Company" description="Manage companies" />
      <PageBreadcrumb pageTitle="Company Management" />

      {/* Top Controls */}
      <div className="mb-6 space-y-4">
        <div className="flex flex-col sm:flex-row gap-4 justify-between items-start sm:items-center">
          {/* Search Input */}
          <div className="relative flex-1 max-w-md">
            <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search companies..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-500 focus:border-transparent dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:placeholder-gray-400 transition-all"
            />
          </div>

          <div className="flex items-center gap-4">
            {/* Import Button */}
            <button
              onClick={() => setIsImportModalOpen(true)}
              className="inline-flex items-center gap-2 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium transition-colors cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300"
            >
              <FiUpload className="w-4 h-4" />
              Import
            </button>

            {/* Export Buttons */}
            <div className="flex items-center gap-2">
              <div className="relative group">
                <Button
                  variant="outline"
                  startIcon={<FiDownload className="w-4 h-4" />}
                  disabled={isExporting || sortedCompanies.length === 0}
                  className="flex items-center gap-2"
                >
                  Export
                  <svg className="w-4 h-4 text-gray-500 group-hover:text-gray-700 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" />
                  </svg>
                </Button>
                <div className="absolute right-0 mt-0 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50">
                  <button
                    onClick={handleExportToExcel}
                    disabled={isExporting || sortedCompanies.length === 0}
                    className="w-full px-4 py-2 text-left text-sm hover:bg-gray-50 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 first:rounded-t-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                  >
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6z"></path>
                    </svg>
                    Export to Excel
                  </button>
                  {/* <button
                    onClick={handleExportToPDF}
                    disabled={isExporting || sortedCompanies.length === 0}
                    className="w-full px-4 py-2 text-left text-sm hover:bg-gray-50 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                  >
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                      <polyline points="13 2 13 9 20 9"></polyline>
                    </svg>
                    Export to PDF
                  </button> */}
                  <button
                    onClick={handleExportDetailsToPDF}
                    disabled={isExporting || sortedCompanies.length === 0}
                    className="w-full px-4 py-2 text-left text-sm hover:bg-gray-50 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 last:rounded-b-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                  >
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M9 12h6m-6 4h6M7 20h10a2 2 0 002-2V4a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"></path>
                    </svg>
                    Export to PDF
                  </button>
                </div>
              </div>
            </div>

            {/* Add Company Button */}
            <Button
              onClick={() => setIsAddModalOpen(true)}
              startIcon={<FiPlus className="w-4 h-4" />}
            >
              Add Company
            </Button>

            {/* Page Size Selector */}
            <div className="flex items-center gap-2">
              <Label className="text-sm text-gray-600 dark:text-gray-400 whitespace-nowrap">Show:</Label>
              <Select
                value={String(pageSize)}
                onChange={(val) => {
                  setPageSize(Number(val));
                  setCurrentPage(1);
                }}
                options={[
                  { value: "5", label: "5" },
                  { value: "10", label: "10" },
                  { value: "25", label: "25" },
                  { value: "50", label: "50" },
                ]}
                className="w-20"
              />
              <span className="text-sm text-gray-600 dark:text-gray-400 whitespace-nowrap">
                entries
              </span>
            </div>
          </div>
        </div>

        {/* Results Info */}
        <div className="flex justify-between items-center text-sm text-gray-600 dark:text-gray-400">
          <div>
            Showing {sortedCompanies.length === 0 ? 0 : ((currentPage - 1) * pageSize) + 1} to {Math.min(currentPage * pageSize, sortedCompanies.length)} of {sortedCompanies.length} entries
            {searchTerm && ` (filtered from ${companies.length} total entries)`}
          </div>
          {searchTerm && (
            <button
              onClick={() => setSearchTerm("")}
              className="text-brand-600 hover:text-brand-700 dark:text-brand-400 dark:hover:text-brand-300 text-sm font-medium transition-colors"
            >
              Clear filter
            </button>
          )}
        </div>
      </div>

      {/* Table Container */}
      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-white/[0.05] dark:bg-white/[0.03] shadow-sm">
        <div className="max-w-full overflow-x-auto">
          {paginatedCompanies.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 px-4">
              <div className="rounded-full bg-gray-100 dark:bg-gray-800 p-4 mb-4">
                <FiBriefcase className="w-8 h-8 text-gray-400 dark:text-gray-500" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                {searchTerm ? "No companies found" : "No companies yet"}
              </h3>
              <p className="text-gray-600 dark:text-gray-400 text-center max-w-md mb-6">
                {searchTerm
                  ? "Try adjusting your search terms to find what you're looking for."
                  : "Get started by adding your first company to the system."}
              </p>
              {!searchTerm && (
                <Button
                  onClick={() => setIsAddModalOpen(true)}
                  startIcon={<FiPlus className="w-4 h-4" />}
                >
                  Add Your First Company
                </Button>
              )}
            </div>
          ) : (
            <Table>
              <TableHeader className="border-b border-gray-100 dark:border-white/[0.05] bg-gray-50 dark:bg-gray-800/50">
                <TableRow>
                  <TableCell
                    isHeader
                    className="px-5 py-4 font-semibold text-gray-700 text-start text-sm dark:text-gray-300"
                  >
                    #
                  </TableCell>
                  <TableCell
                    isHeader
                    onClick={() => handleSort("name")}
                    className="px-5 py-4 font-semibold text-gray-700 text-start text-sm dark:text-gray-300 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700/50 transition-colors"
                  >
                    <div className="flex items-center gap-2">
                      Company Name
                      <span className="text-gray-400 dark:text-gray-600 text-xs">
                        {sortField === "name" ? (sortDirection === "asc" ? "↑" : "↓") : "↕"}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell
                    isHeader
                    onClick={() => handleSort("registration_no")}
                    className="px-5 py-4 font-semibold text-gray-700 text-start text-sm dark:text-gray-300 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700/50 transition-colors"
                  >
                    <div className="flex items-center gap-2">
                      Registration No
                      <span className="text-gray-400 dark:text-gray-600 text-xs">
                        {sortField === "registration_no" ? (sortDirection === "asc" ? "↑" : "↓") : "↕"}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell
                    isHeader
                    className="px-5 py-4 font-semibold text-gray-700 text-start text-sm dark:text-gray-300"
                  >
                    Actions
                  </TableCell>
                </TableRow>
              </TableHeader>

              <TableBody>
                {paginatedCompanies.map((company, index) => (
                  <TableRow
                    key={company.id}
                    className="border-b border-gray-100 dark:border-white/[0.05] hover:bg-gray-50 dark:hover:bg-gray-800/30 transition-colors"
                  >
                    <TableCell className="px-5 py-4 text-gray-700 dark:text-gray-300">
                      <span className="font-medium">{(currentPage - 1) * pageSize + index + 1}</span>
                    </TableCell>
                    <TableCell className="px-5 py-4">
                      <div className="flex items-center gap-2">
                        <div className="flex-shrink-0 w-8 h-8 rounded-lg bg-brand-100 dark:bg-brand-900/30 flex items-center justify-center">
                          <FiBriefcase className="w-4 h-4 text-brand-600 dark:text-brand-400" />
                        </div>
                        <span className="font-medium text-gray-900 dark:text-white">{company.name}</span>
                      </div>
                    </TableCell>
                    <TableCell className="px-5 py-4 text-gray-700 dark:text-gray-300">
                      <span className="font-mono text-sm">{company.registration_no}</span>
                    </TableCell>
                    <TableCell className="px-5 py-4">
                      <div className="flex items-center gap-2">
                        <button
                          className="p-2 rounded-lg text-brand-600 hover:bg-brand-50 dark:hover:bg-brand-900/20 dark:text-brand-400 transition-colors"
                          onClick={() => {
                            setEditCompanyId(company.id);
                            setIsEditModalOpen(true);
                          }}
                          title="Edit company"
                        >
                          <FiEdit className="w-4 h-4" />
                        </button>
                        <button
                          className="p-2 rounded-lg text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 dark:text-red-400 transition-colors"
                          onClick={() => handleDelete(company.id)}
                          title="Delete company"
                        >
                          <FiTrash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </div>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="mt-6 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="text-sm text-gray-600 dark:text-gray-400">
            Page <span className="font-semibold text-gray-900 dark:text-white">{currentPage}</span> of{" "}
            <span className="font-semibold text-gray-900 dark:text-white">{totalPages}</span>
          </div>

          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={currentPage === 1}
              onClick={() => setCurrentPage((p) => p - 1)}
              startIcon={<FiChevronLeft className="w-4 h-4" />}
            >
              Previous
            </Button>

            {/* Page Numbers */}
            <div className="flex items-center gap-1">
              {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                let pageNum;
                if (totalPages <= 5) {
                  pageNum = i + 1;
                } else if (currentPage <= 3) {
                  pageNum = i + 1;
                } else if (currentPage >= totalPages - 2) {
                  pageNum = totalPages - 4 + i;
                } else {
                  pageNum = currentPage - 2 + i;
                }

                return (
                  <button
                    key={pageNum}
                    onClick={() => setCurrentPage(pageNum)}
                    className={`px-3 py-1.5 text-sm rounded-lg transition-colors ${currentPage === pageNum
                      ? "bg-brand-500 text-white"
                      : "text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800"
                      }`}
                  >
                    {pageNum}
                  </button>
                );
              })}
            </div>

            <Button
              variant="outline"
              size="sm"
              disabled={currentPage === totalPages}
              onClick={() => setCurrentPage((p) => p + 1)}
              endIcon={<FiChevronRight className="w-4 h-4" />}
            >
              Next
            </Button>
          </div>
        </div>
      )}

      {/* Modals */}
      {isAddModalOpen && (
        <AddCompany
          onClose={() => setIsAddModalOpen(false)}
          onAdd={handleCompanyAdded}
        />
      )}

      {isEditModalOpen && editCompanyId !== null && (
        <EditCompany
          companyId={editCompanyId}
          isOpen={isEditModalOpen}
          onClose={() => setIsEditModalOpen(false)}
          onUpdated={fetchCompanies}
        />
      )}

      {/* Import Excel Modal */}
      {isImportModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-white/10 backdrop-blur-md p-4">
          <div className="relative w-full max-w-6xl max-h-[90vh] rounded-xl bg-white shadow-xl dark:bg-gray-800 overflow-hidden flex flex-col">
            {/* Modal Header */}
            <div className="flex items-center justify-between border-b border-gray-200 px-6 py-4 dark:border-gray-700">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white">Import Excel - Companies</h2>
              <button
                onClick={closeModal}
                className="rounded-lg p-1 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-gray-700 dark:hover:text-gray-300"
              >
                <HiOutlineXMark className="h-6 w-6" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="px-6 py-6 overflow-y-auto flex-1">
              {/* Upload Excel Section */}
              <div className="mb-6 text-center">
                <h3 className="mb-4 text-lg font-medium text-gray-900 dark:text-white">Upload Excel</h3>

                {/* Download Template Button */}
                <div className="mb-4">
                  <button
                    onClick={handleDownloadTemplate}
                    className="inline-flex items-center justify-center gap-2 rounded-lg border border-emerald-600 bg-emerald-50 px-6 py-3 text-sm font-medium text-emerald-700 transition-all hover:bg-emerald-100 dark:border-emerald-500 dark:bg-emerald-900/20 dark:text-emerald-400 dark:hover:bg-emerald-900/30"
                  >
                    <HiOutlineArrowDownTray className="h-5 w-5" />
                    Download Template
                  </button>
                </div>

                {/* File Input (Dashed Box) */}
                <div
                  onClick={() => fileInputRef.current?.click()}
                  className="mb-6 cursor-pointer rounded-xl border-2 border-dashed border-gray-300 bg-gray-50 py-12 text-center transition-all hover:border-emerald-500 hover:bg-emerald-50/30 dark:border-gray-600 dark:bg-gray-800/50 dark:hover:bg-gray-800"
                >
                  <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400">
                    <HiOutlineDocumentArrowUp className="h-8 w-8" />
                  </div>
                  <h3 className="text-lg font-medium text-gray-900 dark:text-white">
                    Select Excel File
                  </h3>
                  <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                    {excelFile ? (
                      <span className="font-medium text-emerald-600 dark:text-emerald-400">{excelFile.name}</span>
                    ) : (
                      "Click to browse your device"
                    )}
                  </p>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept=".xlsx,.xls"
                    onChange={handleFileSelect}
                    className="hidden"
                  />
                </div>

                {/* Import Excel Button */}
                <div className="mb-4">
                  <button
                    onClick={handleImportExcel}
                    disabled={!excelFile}
                    className="inline-flex items-center justify-center gap-2 rounded-lg bg-indigo-600 px-6 py-3 text-sm font-medium text-white shadow-sm transition-all hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    <HiOutlineDocumentArrowUp className="h-5 w-5" />
                    Import Excel
                  </button>
                </div>

                {/* Excel Data Preview */}
                {excelData.length > 0 && (
                  <div className="mt-6 rounded-lg border border-gray-200 bg-gray-50 p-4 dark:border-gray-700 dark:bg-gray-900/50">
                    <div className="mb-3 flex items-center justify-between">
                      <div className="text-sm font-semibold text-gray-900 dark:text-white">
                        Total Records: {excelData.length}
                      </div>
                      <div className="flex items-center gap-3">
                        {excelData.some(row => row.errors && row.errors.length > 0) && (
                          <div className="text-sm font-semibold text-red-600 dark:text-red-400">
                            {excelData.filter(row => row.errors && row.errors.length > 0).length} record(s) have errors
                          </div>
                        )}
                      </div>
                    </div>
                    <div className="max-h-96 overflow-y-auto overflow-x-auto bg-white dark:bg-gray-800">
                      <Table className="w-full min-w-[600px] bg-white dark:bg-gray-800">
                        <TableHeader>
                          <TableRow className="bg-gray-100 dark:bg-gray-800">
                            <TableCell isHeader className="py-2 px-3 w-10 sticky left-0 bg-gray-100 dark:bg-gray-800 z-10">
                              <input
                                type="checkbox"
                                checked={selectedRows.size > 0 && selectedRows.size === excelData.filter(r => !r.errors || r.errors.length === 0).length}
                                onChange={handleSelectAll}
                                className="rounded border-gray-300 text-brand-600 focus:ring-brand-500"
                                disabled={!excelData.some(r => !r.errors || r.errors.length === 0)}
                              />
                            </TableCell>
                            <TableCell isHeader className="py-2 px-3 text-left text-xs font-bold text-gray-700 dark:text-gray-300 w-16 sticky left-10 bg-gray-100 dark:bg-gray-800 z-10">Row</TableCell>
                            <TableCell isHeader className="py-2 px-3 text-left text-xs font-bold text-gray-700 dark:text-gray-300">Company Name</TableCell>
                            <TableCell isHeader className="py-2 px-3 text-left text-xs font-bold text-gray-700 dark:text-gray-300">Registration No</TableCell>
                            <TableCell isHeader className="py-2 px-3 text-left text-xs font-bold text-gray-700 dark:text-gray-300">Status</TableCell>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {excelData.map((row, rowIndex) => (
                            <TableRow
                              key={rowIndex}
                              className={`border-b border-gray-100 dark:border-gray-700 ${row.errors && row.errors.length > 0 ? 'bg-red-50 dark:bg-red-900/20 hover:bg-red-100 dark:hover:bg-red-900/30' : 'bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700'}`}
                              onClick={() => handleSelectRow(rowIndex)}
                            >
                              <TableCell className={`py-2 px-3 sticky left-0 z-10 ${row.errors && row.errors.length > 0 ? 'bg-red-50 dark:bg-red-900/20' : 'bg-white dark:bg-gray-800'}`}>
                                <input
                                  type="checkbox"
                                  checked={selectedRows.has(rowIndex)}
                                  onChange={(e) => { e.stopPropagation(); handleSelectRow(rowIndex); }}
                                  className="rounded border-gray-300 text-brand-600 focus:ring-brand-500"
                                  disabled={!!(row.errors && row.errors.length > 0)}
                                />
                              </TableCell>
                              <TableCell className={`py-2 px-3 text-xs text-gray-900 dark:text-white sticky left-10 z-10 ${row.errors && row.errors.length > 0 ? 'bg-red-50 dark:bg-red-900/20' : 'bg-white dark:bg-gray-800'}`}>
                                {rowIndex + 2}
                              </TableCell>
                              <TableCell className="py-2 px-3 text-xs text-gray-900 dark:text-white">
                                {row.name || 'N/A'}
                              </TableCell>
                              <TableCell className="py-2 px-3 text-xs text-gray-900 dark:text-white font-mono">
                                {row.registration_no || 'N/A'}
                              </TableCell>
                              <TableCell className="py-2 px-3">
                                {row.errors && row.errors.length > 0 ? (
                                  <div className="flex flex-col gap-1">
                                    <span className="inline-flex w-fit rounded-full bg-red-100 px-2 py-0.5 text-xs font-semibold text-red-800 dark:bg-red-900/30 dark:text-red-400 whitespace-nowrap">
                                      {row.errors.length} error(s)
                                    </span>
                                    <ul className="list-disc pl-4 text-xs text-red-600 dark:text-red-400">
                                      {row.errors.map((err, i) => (
                                        <li key={i}>{err}</li>
                                      ))}
                                    </ul>
                                  </div>
                                ) : (
                                  <span className="inline-flex rounded-full bg-green-100 px-2 py-0.5 text-xs font-semibold text-green-800 dark:bg-green-900/30 dark:text-green-400 whitespace-nowrap">
                                    Valid
                                  </span>
                                )}
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </div>
                  </div>
                )}

                {/* Submit Button */}
                {excelData.length > 0 && (
                  <div className="mt-6">
                    <button
                      onClick={handleBulkSubmit}
                      disabled={isUploading || selectedRows.size === 0}
                      className="w-full rounded-lg bg-emerald-600 px-6 py-3 text-sm font-medium text-white shadow-sm transition-all hover:bg-emerald-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      {isUploading ? (
                        <span className="flex items-center justify-center gap-2">
                          <svg className="h-5 w-5 animate-spin" viewBox="0 0 24 24">
                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                          </svg>
                          Uploading...
                        </span>
                      ) : (
                        `Submit ${selectedRows.size} Selected Compan${selectedRows.size === 1 ? 'y' : 'ies'}`
                      )}
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default CompanyPage;
