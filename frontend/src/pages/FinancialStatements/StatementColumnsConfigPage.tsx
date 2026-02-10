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
import { Modal } from "../../components/ui/modal";
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
  aliases: string[];
  is_required: boolean;
}

const STATEMENT_TYPE_OPTIONS: { value: StatementType; label: string }[] = [
  { value: "TRADING", label: "Trading Account" },
  { value: "PL", label: "Profit & Loss" },
  { value: "BALANCE_SHEET", label: "Balance Sheet" },
  { value: "OPERATIONAL", label: "Operational" },
];

const CANONICAL_FIELDS_BY_STATEMENT: Record<StatementType, string[]> = {
  TRADING: ["opening_stock", "purchases", "trade_charges", "sales", "closing_stock"],
  PL: [
    "interest_on_loans",
    "interest_on_bank_ac",
    "return_on_investment",
    "miscellaneous_income",
    "interest_on_deposits",
    "interest_on_borrowings",
    "establishment_contingencies",
    "provisions",
    "net_profit",
  ],
  BALANCE_SHEET: [
    "share_capital",
    "deposits",
    "borrowings",
    "reserves_statutory_free",
    "undistributed_profit",
    "provisions",
    "other_liabilities",
    "cash_in_hand",
    "cash_at_bank",
    "investments",
    "loans_advances",
    "fixed_assets",
    "other_assets",
    "stock_in_trade",
  ],
  OPERATIONAL: ["staff_count"],
};

const StatementColumnsConfigPage: React.FC = () => {
  const [companies, setCompanies] = useState<CompanyData[]>([]);
  const [selectedCompanyId, setSelectedCompanyId] = useState<string>("global");
  const [statementType, setStatementType] =
    useState<StatementType>("TRADING");
  const [rows, setRows] = useState<StatementColumnConfig[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  const [newConfig, setNewConfig] = useState({
    canonical_field: "",
    display_name: "",
    aliases: "",
    is_required: true,
  });
  const [editingRow, setEditingRow] = useState<StatementColumnConfig | null>(null);
  const [editForm, setEditForm] = useState({ display_name: "", aliases: "", is_required: true });
  const [adding, setAdding] = useState(false);
  const [savingEdit, setSavingEdit] = useState(false);

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
    value: string | boolean | string[]
  ) => {
    setRows((prev) =>
      prev.map((row) =>
        row.id === id
          ? {
              ...row,
              [field]:
                field === "is_required"
                  ? Boolean(value)
                  : field === "aliases"
                  ? Array.isArray(value)
                    ? value
                    : String(value)
                        .split(",")
                        .map((s) => s.trim().replace(/\s+/g, "_"))
                        .filter(Boolean)
                  : value,
            }
          : row
      )
    );
  };

  const sortedRows = useMemo(
    () => [...rows].sort((a, b) => a.canonical_field.localeCompare(b.canonical_field)),
    [rows]
  );

  const availableFields = useMemo(() => {
    const all = CANONICAL_FIELDS_BY_STATEMENT[statementType] ?? [];
    const configured = new Set(rows.map((r) => r.canonical_field));
    return all.filter((f) => !configured.has(f));
  }, [statementType, rows]);

  const handleAddConfig = async () => {
    if (!canUpdate || !newConfig.canonical_field.trim()) {
      toast.error("Select a canonical field.");
      return;
    }
    setAdding(true);
    try {
      const headers = await getAuthHeaders();
      const body = {
        company: selectedCompanyId === "global" ? null : parseInt(selectedCompanyId, 10),
        statement_type: statementType,
        canonical_field: newConfig.canonical_field.trim(),
        display_name: newConfig.display_name.trim() || newConfig.canonical_field,
        aliases: newConfig.aliases
          .split(",")
          .map((s) => s.trim().replace(/\s+/g, "_"))
          .filter(Boolean),
        is_required: newConfig.is_required,
      };
      const res = await fetch(createApiUrl("api/statement-columns/"), {
        method: "POST",
        headers: { ...headers, "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.detail || err.canonical_field?.[0] || "Failed to add configuration");
      }
      toast.success("Configuration added.");
      setShowAddModal(false);
      setNewConfig({ canonical_field: "", display_name: "", aliases: "", is_required: true });
      await loadConfigs();
    } catch (e: any) {
      toast.error(e?.message || "Failed to add configuration");
    } finally {
      setAdding(false);
    }
  };

  const handleSaveEdit = async () => {
    if (!editingRow || !canUpdate) return;
    setSavingEdit(true);
    try {
      const headers = await getAuthHeaders();
      const body = {
        display_name: editForm.display_name.trim(),
        aliases: editForm.aliases
          .split(",")
          .map((s) => s.trim().replace(/\s+/g, "_"))
          .filter(Boolean),
        is_required: editForm.is_required,
      };
      const res = await fetch(createApiUrl(`api/statement-columns/${editingRow.id}/`), {
        method: "PATCH",
        headers: { ...headers, "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error("Failed to update");
      toast.success("Configuration updated.");
      setEditingRow(null);
      await loadConfigs();
    } catch (e: any) {
      toast.error(e?.message || "Failed to update");
    } finally {
      setSavingEdit(false);
    }
  };

  const handleSave = async () => {
    if (!canUpdate) return;
    setSaving(true);
    try {
      const headers = await getAuthHeaders();
      for (const row of rows) {
        const url = createApiUrl(`api/statement-columns/${row.id}/`);
        const body = {
          display_name: row.display_name,
          aliases: row.aliases ?? [],
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
          <div className="flex gap-2">
            <Button
              variant="outline"
              onClick={() => setShowAddModal(true)}
              disabled={loading || availableFields.length === 0}
            >
              Add configuration
            </Button>
            <Button onClick={handleSave} disabled={saving || rows.length === 0}>
              {saving ? "Saving..." : "Save changes"}
            </Button>
          </div>
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
      ) : rows.length === 0 && !canUpdate ? (
        <p className="text-gray-600 dark:text-gray-400">
          No column configuration found for this selection.
        </p>
      ) : rows.length === 0 && canUpdate ? (
        <div className="rounded-lg border border-dashed border-gray-300 dark:border-gray-600 p-8 text-center">
          <p className="text-gray-600 dark:text-gray-400 mb-4">
            No configuration for this statement type yet.
          </p>
          <Button onClick={() => setShowAddModal(true)} disabled={availableFields.length === 0}>
            Add configuration
          </Button>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableCell className="font-semibold text-gray-700 dark:text-gray-300">
                  Canonical Field (Model)
                </TableCell>
                <TableCell className="font-semibold text-gray-700 dark:text-gray-300">
                  Display Name (UI / PDF)
                </TableCell>
                <TableCell className="font-semibold text-gray-700 dark:text-gray-300 min-w-[280px]">
                  Alternative Names / Aliases
                </TableCell>
                <TableCell className="font-semibold text-gray-700 dark:text-gray-300">
                  Required
                </TableCell>
                {canUpdate && (
                  <TableCell className="font-semibold text-gray-700 dark:text-gray-300 w-20">
                    Actions
                  </TableCell>
                )}
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
                  <TableCell>
                    <Input
                      type="text"
                      value={Array.isArray(row.aliases) ? row.aliases.join(", ") : ""}
                      onChange={(e) =>
                        handleFieldChange(row.id, "aliases", e.target.value)
                      }
                      placeholder="e.g. beginning_stock, opening_inventory (spaces auto-converted to _)"
                      disabled={!canUpdate}
                      className="w-full"
                    />
                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                      Comma-separated names to match during upload
                    </p>
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
                  {canUpdate && (
                    <TableCell>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => {
                          setEditingRow(row);
                          setEditForm({
                            display_name: row.display_name,
                            aliases: Array.isArray(row.aliases) ? row.aliases.join(", ") : "",
                            is_required: row.is_required,
                          });
                        }}
                      >
                        Edit
                      </Button>
                    </TableCell>
                  )}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      <Modal
        isOpen={showAddModal}
        onClose={() => {
          setShowAddModal(false);
          setNewConfig({ canonical_field: "", display_name: "", aliases: "", is_required: true });
        }}
        className="max-w-md p-6 rounded-xl shadow-xl bg-white dark:bg-gray-900"
      >
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Add column configuration
        </h3>
        {availableFields.length === 0 ? (
          <p className="text-gray-600 dark:text-gray-400">
            All fields for this statement type are already configured.
          </p>
        ) : (
          <div className="space-y-4">
            <div>
              <Label htmlFor="new_canonical">Canonical field</Label>
              <select
                id="new_canonical"
                value={newConfig.canonical_field}
                onChange={(e) =>
                  setNewConfig((prev) => ({
                    ...prev,
                    canonical_field: e.target.value,
                    display_name: prev.display_name || e.target.value.replace(/_/g, " "),
                  }))
                }
                className="h-11 w-full rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-900 px-3 text-sm text-gray-900 dark:text-white"
              >
                <option value="">Select field</option>
                {availableFields.map((f) => (
                  <option key={f} value={f}>
                    {f}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <Label htmlFor="new_display">Display name</Label>
              <Input
                id="new_display"
                type="text"
                value={newConfig.display_name}
                onChange={(e) =>
                  setNewConfig((prev) => ({ ...prev, display_name: e.target.value }))
                }
                placeholder="e.g. Opening Stock"
              />
            </div>
            <div>
              <Label htmlFor="new_aliases">Alternative names (comma-separated)</Label>
              <Input
                id="new_aliases"
                type="text"
                value={newConfig.aliases}
                onChange={(e) =>
                  setNewConfig((prev) => ({ ...prev, aliases: e.target.value }))
                }
                placeholder="e.g. beginning_stock, opening_inventory (spaces → _)"
              />
            </div>
            <div className="flex items-center gap-2">
              <label className="flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300">
                <input
                  type="checkbox"
                  checked={newConfig.is_required}
                  onChange={(e) =>
                    setNewConfig((prev) => ({ ...prev, is_required: e.target.checked }))
                  }
                />
                Required
              </label>
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <Button variant="outline" onClick={() => setShowAddModal(false)}>
                Cancel
              </Button>
              <Button onClick={handleAddConfig} disabled={adding || !newConfig.canonical_field}>
                {adding ? "Adding..." : "Add"}
              </Button>
            </div>
          </div>
        )}
      </Modal>

      <Modal
        isOpen={!!editingRow}
        onClose={() => setEditingRow(null)}
        className="max-w-md p-6 rounded-xl shadow-xl bg-white dark:bg-gray-900"
      >
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Edit column configuration
        </h3>
        {editingRow && (
          <div className="space-y-4">
            <div>
              <Label>Canonical field</Label>
              <p className="text-sm text-gray-700 dark:text-gray-300 mt-1">
                {editingRow.canonical_field}
              </p>
            </div>
            <div>
              <Label htmlFor="edit_display">Display name (UI / PDF)</Label>
              <Input
                id="edit_display"
                type="text"
                value={editForm.display_name}
                onChange={(e) =>
                  setEditForm((prev) => ({ ...prev, display_name: e.target.value }))
                }
                placeholder="e.g. Opening Stock"
              />
            </div>
            <div>
              <Label htmlFor="edit_aliases">Alternative names (comma-separated)</Label>
              <Input
                id="edit_aliases"
                type="text"
                value={editForm.aliases}
                onChange={(e) =>
                  setEditForm((prev) => ({ ...prev, aliases: e.target.value }))
                }
                placeholder="e.g. beginning_stock, opening_inventory (spaces → _)"
              />
            </div>
            <div>
              <label className="flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300">
                <input
                  type="checkbox"
                  checked={editForm.is_required}
                  onChange={(e) =>
                    setEditForm((prev) => ({ ...prev, is_required: e.target.checked }))
                  }
                />
                Required
              </label>
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <Button variant="outline" onClick={() => setEditingRow(null)}>
                Cancel
              </Button>
              <Button onClick={handleSaveEdit} disabled={savingEdit}>
                {savingEdit ? "Saving..." : "Save"}
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};

export default StatementColumnsConfigPage;

