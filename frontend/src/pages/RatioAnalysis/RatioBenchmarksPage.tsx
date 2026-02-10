import React, { useState, useEffect } from "react";
import {
  getRatioBenchmarks,
  updateRatioBenchmarks,
  RatioBenchmarksResponse,
} from "./benchmarksApi";
import Button from "../../components/ui/button/Button";
import Input from "../../components/form/input/InputField";
import Label from "../../components/form/Label";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

const CATEGORIES: Record<string, string[]> = {
  Trading: ["stock_turnover", "gross_profit_ratio_min", "gross_profit_ratio_max"],
  "Fund Structure": [
    "own_fund_to_wf",
    "loans_to_wf_min",
    "loans_to_wf_max",
    "investments_to_wf_min",
    "investments_to_wf_max",
  ],
  "Yield & Cost": ["avg_cost_of_wf", "avg_yield_on_wf"],
  Margins: [
    "gross_financial_margin",
    "operating_cost_to_wf_min",
    "operating_cost_to_wf_max",
    "net_financial_margin",
    "risk_cost_to_wf_max",
    "net_margin",
  ],
  "Credit Deposit": ["credit_deposit_ratio_min"],
};

const RatioBenchmarksPage: React.FC = () => {
  const [data, setData] = useState<RatioBenchmarksResponse | null>(null);
  const [values, setValues] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const userRole =
    typeof window !== "undefined" ? localStorage.getItem("userRole") || "" : "";
  const canUpdate = userRole === "master";

  useEffect(() => {
    load();
  }, []);

  const load = async () => {
    setLoading(true);
    try {
      const res = await getRatioBenchmarks();
      setData(res);
      const initial: Record<string, string> = {};
      (res.keys_order || Object.keys(res.benchmarks || {})).forEach((k) => {
        const v = res.benchmarks?.[k];
        initial[k] = v != null ? String(v) : "";
      });
      setValues(initial);
    } catch (e) {
      toast.error("Failed to load benchmarks");
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (key: string, value: string) => {
    setValues((prev) => ({ ...prev, [key]: value }));
  };

  const handleSave = async () => {
    if (!data || !canUpdate) return;
    setSaving(true);
    try {
      const benchmarks: Record<string, number | null> = {};
      Object.entries(values).forEach(([k, v]) => {
        const trimmed = v.trim();
        if (trimmed === "") benchmarks[k] = null;
        else {
          const num = parseFloat(trimmed);
          benchmarks[k] = isNaN(num) ? null : num;
        }
      });
      await updateRatioBenchmarks(benchmarks);
      toast.success("Benchmarks updated.");
      await load();
    } catch (e: any) {
      toast.error(e?.message || "Failed to update benchmarks");
    } finally {
      setSaving(false);
    }
  };

  if (loading || !data) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-gray-600 dark:text-gray-400">Loading benchmarks...</p>
      </div>
    );
  }

  const labels = data.labels || {};
  const allKeys = data.keys_order?.length
    ? data.keys_order
    : Object.keys(data.benchmarks || {});

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <ToastContainer position="bottom-right" autoClose={3000} />
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Ratio Benchmarks
        </h1>
        {canUpdate ? (
          <Button onClick={handleSave} disabled={saving}>
            {saving ? "Saving..." : "Save changes"}
          </Button>
        ) : (
          <p className="text-sm text-amber-600 dark:text-amber-400">
            Only Master role can update benchmarks.
          </p>
        )}
      </div>
      <p className="text-sm text-gray-600 dark:text-gray-400 mb-6">
        These values are used for traffic light status (green/yellow/red) in the
        Ratio Dashboard. Leave blank where no fixed benchmark applies.
      </p>

      <div className="space-y-8">
        {Object.entries(CATEGORIES).map(([categoryName, keys]) => {
          const visibleKeys = keys.filter((k) => allKeys.includes(k));
          if (visibleKeys.length === 0) return null;
          return (
            <div
              key={categoryName}
              className="border border-gray-200 dark:border-gray-700 rounded-lg p-4"
            >
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                {categoryName}
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {visibleKeys.map((key) => (
                  <div key={key}>
                    <Label htmlFor={key}>
                      {labels[key] || key.replace(/_/g, " ")}
                    </Label>
                    <Input
                      id={key}
                      type="number"
                      step="any"
                      value={values[key] ?? ""}
                      onChange={(e) => handleChange(key, e.target.value)}
                      disabled={!canUpdate}
                      placeholder="—"
                    />
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>

      {/* Any keys not in CATEGORIES */}
      {allKeys.filter((k) => !Object.values(CATEGORIES).flat().includes(k))
        .length > 0 && (
        <div className="mt-8 border border-gray-200 dark:border-gray-700 rounded-lg p-4">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Other
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {allKeys
              .filter((k) => !Object.values(CATEGORIES).flat().includes(k))
              .map((key) => (
                <div key={key}>
                  <Label htmlFor={key}>{labels[key] || key}</Label>
                  <Input
                    id={key}
                    type="number"
                    step="any"
                    value={values[key] ?? ""}
                    onChange={(e) => handleChange(key, e.target.value)}
                    disabled={!canUpdate}
                    placeholder="—"
                  />
                </div>
              ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default RatioBenchmarksPage;
