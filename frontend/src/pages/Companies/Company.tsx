import { useEffect, useState, useMemo } from "react";
import { FiTrash2, FiEdit, FiSearch, FiPlus, FiChevronLeft, FiChevronRight, FiBriefcase } from "react-icons/fi";
import { BeatLoader } from "react-spinners";
import PageBreadcrumb from "../../components/common/PageBreadCrumb";
import PageMeta from "../../components/common/PageMeta";
import {
  getCompanyList,
  deleteCompany,
  CompanyData,
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

const CompanyPage: React.FC = () => {
  const [companies, setCompanies] = useState<CompanyData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editCompanyId, setEditCompanyId] = useState<number | null>(null);

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
                    className={`px-3 py-1.5 text-sm rounded-lg transition-colors ${
                      currentPage === pageNum
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
    </>
  );
};

export default CompanyPage;
