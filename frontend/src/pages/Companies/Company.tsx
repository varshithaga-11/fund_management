import { useEffect, useState, useMemo } from "react";
import { FiTrash2, FiEdit } from "react-icons/fi";
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

  if (loading) return <div>Loading companies...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <>
      <PageMeta title="Company" description="Manage companies" />
      <PageBreadcrumb pageTitle="Company Management" />

      {/* Top Controls */}
      <div className="mb-6 flex justify-between items-center">
        <input
          type="text"
          placeholder="Search company..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full max-w-md px-4 py-2 border rounded-lg"
        />

        <div className="flex items-center gap-4">
          <Button onClick={() => setIsAddModalOpen(true)}>Add Company</Button>

          <div className="flex items-center gap-2">
            <Label>Show</Label>
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
              ]}
            />
          </div>
        </div>
      </div>

      {/* Table */}
      <Table>
        <TableHeader>
          <TableRow>
            <TableCell isHeader>#</TableCell>

            <TableCell isHeader onClick={() => handleSort("name")}>
              Company Name {sortField === "name" && (sortDirection === "asc" ? "↑" : "↓")}
            </TableCell>

            <TableCell isHeader onClick={() => handleSort("registration_no")}>
              Registration No {sortField === "registration_no" && (sortDirection === "asc" ? "↑" : "↓")}
            </TableCell>

            <TableCell isHeader>Action</TableCell>
          </TableRow>
        </TableHeader>

        <TableBody>
          {paginatedCompanies.map((company, index) => (
            <TableRow key={company.id}>
              <TableCell>
                {(currentPage - 1) * pageSize + index + 1}
              </TableCell>

              <TableCell>{company.name}</TableCell>
              <TableCell>{company.registration_no}</TableCell>

              <TableCell>
                <div className="flex gap-3">
                  <button
                    className="text-blue-600"
                    onClick={() => {
                      setEditCompanyId(company.id);
                      setIsEditModalOpen(true);
                    }}
                  >
                    <FiEdit />
                  </button>
                  <button
                    className="text-red-600"
                    onClick={() => handleDelete(company.id)}
                  >
                    <FiTrash2 />
                  </button>
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="mt-4 flex justify-between">
          <Button
            disabled={currentPage === 1}
            onClick={() => setCurrentPage((p) => p - 1)}
          >
            Previous
          </Button>

          <span>
            Page {currentPage} of {totalPages}
          </span>

          <Button
            disabled={currentPage === totalPages}
            onClick={() => setCurrentPage((p) => p + 1)}
          >
            Next
          </Button>
        </div>
      )}

      {/* Modals */}
      {isAddModalOpen && (
        <AddCompany
          onClose={() => setIsAddModalOpen(false)}
          onAdded={fetchCompanies}
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
