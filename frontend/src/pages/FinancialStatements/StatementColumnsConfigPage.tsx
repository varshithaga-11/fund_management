import React, { useEffect, useMemo, useState } from "react";
import { getCompanyList, CompanyData } from "../Companies/api";
import { createApiUrl, getAuthHeaders } from "../../access/access";
import Label from "../../components/form/Label";
import Input from "../../components/form/input/InputField";
import Button from "../../components/ui/button/Button";
import {
  Table,
  TableBody,
  TableCell,
  TableHeader,
  TableRow,
} from "../../components/ui/table";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

type StatementType = "TRADING" | "PL" | "BALANCE_SHEET" | "OPERATIONAL";

interface StatementColumnConfig {
  id: number;
  company: number | null;
  company_name?: string | null;
  statement_type: StatementType;
  canonical_field: string;
  display_name: string;
  order_index: number;
  is_required: boolean;
}

const STATEMENT_TYPE_OPTIONS: { value: StatementType; label: string }[] = [
  { value: "TRADING", label: "Trading Account" },
  { value: "PL", label: "Profit & Loss" },
  { value: "BALANCE_SHEET", label: "Balance Sheet" },
  { value: "OPERATIONAL", label: "Operational" },
];

const StatementColumnsConfigPage: React.FC = () => {
  const [companies, setCompanies] = useState<CompanyData[]>([]);
  const [selectedCompanyId, setSelectedCompanyId] = useState<string>("global");
  const [statementType, setStatementType] =
    useState<StatementType>("TRADING");
  const [rows, setRows] = useState<StatementColumnConfig[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);

  const userRole =
    typeof window !== "undefined" ? localStorage.getItem("userRole") || "" : "";
  const canUpdate = userRole === "master";

  useEffect(() => {
    loadCompanies();
  }, []);

  useEffect(() => {
    if (statementType) {
      loadConfigs();
    }
  }, [statementType, selectedCompanyId]);

  const loadCompanies = async () => {
    try {
      const data = await getCompanyList();
      setCompanies(data);
    } catch (e) {
      console.error("Failed to load companies", e);
    }
  };

  const loadConfigs = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      params.append("statement_type", statementType);
      if (selectedCompanyId) {
        params.append("company", selectedCompanyId);
      }
      const url = `${createApiUrl("api/statement-columns/")}?${params.toString()}`;
      const headers = await getAuthHeaders();
      const res = await fetch(url, { headers });
      if (!res.ok) {
        throw new Error("Failed to load column config");
      }
      const data: StatementColumnConfig[] = await res.json();
      setRows(data);
    } catch (e) {
      console.error(e);
      toast.error("Failed to load column configuration");
    } finally {
      setLoading(false);
    }
  };

  const handleFieldChange = (
    id: number,
    field: keyof StatementColumnConfig,
    value: string | boolean
  ) => {
    setRows((prev) =>
      prev.map((row) =>
        row.id === id
          ? {
              ...row,
              [field]:
                field === "order_index"
                  ? parseInt(String(value) || "0", 10)
                  : field === "is_required"
                  ? Boolean(value)
                  : value,
            }
          : row
      )
    );
  };

  const sortedRows = useMemo(
    () =>
      [...rows].sort((a, b) => {
        if (a.order_index === b.order_index) {
          return a.canonical_field.localeCompare(b.canonical_field);
        }
        return a.order_index - b.order_index;
      }),
    [rows]
  );

  const handleSave = async () => {
    if (!canUpdate) return;
    setSaving(true);
    try {
      const headers = await getAuthHeaders();
      for (const row of rows) {
        const url = createApiUrl(`api/statement-columns/${row.id}/`);
        const body = {
          display_name: row.display_name,
          order_index: row.order_index,
          is_required: row.is_required,
        };
        const res = await fetch(url, {
          method: "PATCH",
          headers,
          body: JSON.stringify(body),
        });
        if (!res.ok) {
          throw new Error("Failed to update some columns");
        }
      }
      toast.success("Column configuration updated.");
      await loadConfigs();
    } catch (e: any) {
      console.error(e);
      toast.error(e?.message || "Failed to update configuration");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="p-6">
      <ToastContainer position="bottom-right" autoClose={3000} />
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Statement Column Mapping
          </h1>
          <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
            Choose a statement type and (optionally) a company to manage
            display names and ordering of financial statement fields.
          </p>
        </div>
        {canUpdate ? (
          <Button onClick={handleSave} disabled={saving || rows.length === 0}>
            {saving ? "Saving..." : "Save changes"}
          </Button>
        ) : (
          <p className="text-sm text-amber-600 dark:text-amber-400">
            Only Master role can update mappings.
          </p>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div>
          <Label htmlFor="statement_type">Statement Type</Label>
          <select
            id="statement_type"
            value={statementType}
            onChange={(e) => setStatementType(e.target.value as StatementType)}
            className="h-11 w-full rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-900 px-3 text-sm text-gray-900 dark:text-white"
          >
            {STATEMENT_TYPE_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>
        <div>
          <Label htmlFor="company">Company (optional)</Label>
          <select
            id="company"
            value={selectedCompanyId}
            onChange={(e) => setSelectedCompanyId(e.target.value)}
            className="h-11 w-full rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-900 px-3 text-sm text-gray-900 dark:text-white"
          >
            <option value="global">Global (all companies)</option>
            {companies.map((c) => (
              <option key={c.id} value={String(c.id)}>
                {c.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center h-48">
          <p className="text-gray-600 dark:text-gray-400">
            Loading column configuration...
          </p>
        </div>
      ) : rows.length === 0 ? (
        <p className="text-gray-600 dark:text-gray-400">
          No column configuration found for this selection.
        </p>
      ) : (
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableCell className="font-semibold text-gray-700 dark:text-gray-300">
                  Canonical Field (Backend)
                </TableCell>
                <TableCell className="font-semibold text-gray-700 dark:text-gray-300">
                  Display Name (UI / PDF)
                </TableCell>
                <TableCell className="font-semibold text-gray-700 dark:text-gray-300">
                  Order
                </TableCell>
                <TableCell className="font-semibold text-gray-700 dark:text-gray-300">
                  Required
                </TableCell>
              </TableRow>
            </TableHeader>
            <TableBody>
              {sortedRows.map((row) => (
                <TableRow key={row.id}>
                  <TableCell className="text-sm text-gray-800 dark:text-gray-100">
                    {row.canonical_field}
                  </TableCell>
                  <TableCell>
                    <Input
                      type="text"
                      value={row.display_name}
                      onChange={(e) =>
                        handleFieldChange(row.id, "display_name", e.target.value)
                      }
                      disabled={!canUpdate}
                    />
                  </TableCell>
                  <TableCell className="w-24">
                    <Input
                      type="number"
                      value={row.order_index}
                      onChange={(e) =>
                        handleFieldChange(row.id, "order_index", e.target.value)
                      }
                      disabled={!canUpdate}
                    />
                  </TableCell>
                  <TableCell className="w-24">
                    <input
                      type="checkbox"
                      checked={row.is_required}
                      onChange={(e) =>
                        handleFieldChange(row.id, "is_required", e.target.checked)
                      }
                      disabled={!canUpdate}
                    />
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </div>
  );
};

export default StatementColumnsConfigPage;

