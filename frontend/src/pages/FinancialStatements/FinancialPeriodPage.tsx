import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  getFinancialPeriod,
  FinancialPeriodData,
  calculateRatios,
} from "./api";
import TradingAccountForm from "./TradingAccountForm";
import ProfitLossForm from "./ProfitLossForm";
import BalanceSheetForm from "./BalanceSheetForm";
import OperationalMetricsForm from "./OperationalMetricsForm";
import Button from "../../components/ui/button/Button";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import { getCompanyList as getCompanies, CompanyData } from "../Companies/api";

const FinancialPeriodPage: React.FC = () => {
  const { periodId } = useParams<{ periodId: string }>();
  const navigate = useNavigate();
  const [period, setPeriod] = useState<FinancialPeriodData | null>(null);
  const [companies, setCompanies] = useState<CompanyData[]>([]);
  const [activeTab, setActiveTab] = useState("trading");
  const [loading, setLoading] = useState(false);
  const [calculating, setCalculating] = useState(false);

  // All data is read-only - no updates allowed

  useEffect(() => {
    if (periodId) {
      loadPeriod();
    }
    loadCompanies();
  }, [periodId]);

  const loadCompanies = async () => {
    try {
      const data = await getCompanies();
      setCompanies(data);
    } catch (error) {
      console.error("Error loading companies:", error);
    }
  };

  const loadPeriod = async () => {
    if (!periodId) return;
    setLoading(true);
    try {
      const data = await getFinancialPeriod(parseInt(periodId));
      setPeriod(data);
    } catch (error) {
      console.error("Error loading period:", error);
      toast.error("Failed to load financial period");
    } finally {
      setLoading(false);
    }
  };

  const handleCalculateRatios = async () => {
    if (!periodId) return;

    // Check if all required data exists
    if (!period?.trading_account) {
      toast.error("Please complete Trading Account first");
      return;
    }
    if (!period?.profit_loss) {
      toast.error("Please complete Profit & Loss first");
      return;
    }
    if (!period?.balance_sheet) {
      toast.error("Please complete Balance Sheet first");
      return;
    }
    if (!period?.operational_metrics) {
      toast.error("Please complete Operational Metrics first");
      return;
    }

    setCalculating(true);
    try {
      await calculateRatios(parseInt(periodId));
      toast.success("Ratios calculated successfully!");
      await loadPeriod();
      // Navigate to ratio dashboard
      navigate(`/ratio-analysis/${periodId}`);
    } catch (error: any) {
      console.error("Error calculating ratios:", error);
      if (error.response?.data?.message) {
        toast.error(error.response.data.message);
      } else {
        toast.error("Failed to calculate ratios");
      }
    } finally {
      setCalculating(false);
    }
  };

  const tabs = [
    { id: "trading", label: "Trading Account" },
    { id: "profit-loss", label: "Profit & Loss" },
    { id: "balance-sheet", label: "Balance Sheet" },
    { id: "operational", label: "Operational Metrics" },
  ];

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-gray-600 dark:text-gray-400">Loading...</p>
      </div>
    );
  }

  if (!period) {
    return (
      <div className="p-6">
        <p className="text-red-600 dark:text-red-400">
          Financial Period not found
        </p>
      </div>
    );
  }

  const canCalculateRatios =
    period.trading_account &&
    period.profit_loss &&
    period.balance_sheet &&
    period.operational_metrics;

  return (
    <div className="p-6 space-y-6">
      <ToastContainer position="bottom-right" autoClose={3000} />
      
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Financial Statements - {period.label}
          </h1>
          <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
            {companies.find((c) => c.id === period.company)?.name || ""} -{" "}
            {period.period_type}
          </p>
        </div>
        <Button
          onClick={handleCalculateRatios}
          disabled={!canCalculateRatios || calculating}
        >
          {calculating ? "Calculating..." : "Calculate Ratios"}
        </Button>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200 dark:border-gray-700">
        <nav className="-mb-px flex space-x-8">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`py-4 px-1 border-b-2 font-medium text-sm ${
                activeTab === tab.id
                  ? "border-brand-500 text-brand-600 dark:text-brand-400"
                  : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      <div className="mb-4 p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 text-blue-800 dark:text-blue-200 text-sm">
        View only mode - Financial statements are read-only and cannot be updated.
      </div>
      <div className="mt-6">
        {activeTab === "trading" && (
          <TradingAccountForm
            periodId={parseInt(periodId!)}
            onSave={loadPeriod}
            canUpdate={false}
          />
        )}
        {activeTab === "profit-loss" && (
          <ProfitLossForm
            periodId={parseInt(periodId!)}
            onSave={loadPeriod}
            canUpdate={false}
          />
        )}
        {activeTab === "balance-sheet" && (
          <BalanceSheetForm
            periodId={parseInt(periodId!)}
            onSave={loadPeriod}
            canUpdate={false}
          />
        )}
        {activeTab === "operational" && (
          <OperationalMetricsForm
            periodId={parseInt(periodId!)}
            onSave={loadPeriod}
            canUpdate={false}
          />
        )}
      </div>

      {/* Status Indicators */}
      <div className="mt-6 p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
        <h3 className="text-sm font-medium text-gray-900 dark:text-white mb-2">
          Completion Status
        </h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="flex items-center">
            <div
              className={`w-3 h-3 rounded-full mr-2 ${
                period.trading_account
                  ? "bg-green-500"
                  : "bg-gray-300 dark:bg-gray-600"
              }`}
            />
            <span className="text-sm text-gray-600 dark:text-gray-400">
              Trading Account
            </span>
          </div>
          <div className="flex items-center">
            <div
              className={`w-3 h-3 rounded-full mr-2 ${
                period.profit_loss
                  ? "bg-green-500"
                  : "bg-gray-300 dark:bg-gray-600"
              }`}
            />
            <span className="text-sm text-gray-600 dark:text-gray-400">
              Profit & Loss
            </span>
          </div>
          <div className="flex items-center">
            <div
              className={`w-3 h-3 rounded-full mr-2 ${
                period.balance_sheet
                  ? "bg-green-500"
                  : "bg-gray-300 dark:bg-gray-600"
              }`}
            />
            <span className="text-sm text-gray-600 dark:text-gray-400">
              Balance Sheet
            </span>
          </div>
          <div className="flex items-center">
            <div
              className={`w-3 h-3 rounded-full mr-2 ${
                period.operational_metrics
                  ? "bg-green-500"
                  : "bg-gray-300 dark:bg-gray-600"
              }`}
            />
            <span className="text-sm text-gray-600 dark:text-gray-400">
              Operational Metrics
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FinancialPeriodPage;
