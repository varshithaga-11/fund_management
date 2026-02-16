import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  getFinancialPeriod,
  FinancialPeriodData,
} from "./api";
import TradingAccountForm from "./TradingAccountForm";
import ProfitLossForm from "./ProfitLossForm";
import BalanceSheetForm from "./BalanceSheetForm";
import OperationalMetricsForm from "./OperationalMetricsForm";
import Button from "../../components/ui/button/Button";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";


const FinancialPeriodPage: React.FC = () => {
  const { periodId } = useParams<{ periodId: string }>();
  const navigate = useNavigate();
  const [period, setPeriod] = useState<FinancialPeriodData | null>(null);
  const [activeTab, setActiveTab] = useState("trading");
  const [loading, setLoading] = useState(false);

  // All data is read-only - no updates allowed
  useEffect(() => {
    if (periodId) {
      loadPeriod();
    }
  }, [periodId]);



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

  return (
    <div className="p-6 space-y-6">
      <ToastContainer position="bottom-right" autoClose={3000} />

      {/* Header */}
      <div className="flex justify-between items-center bg-white dark:bg-gray-800 p-4 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
        <div>
          <h1 className="text-3xl font-extrabold text-gray-900 dark:text-white">
            {period.label}
          </h1>
          <p className="text-lg font-bold text-gray-800 dark:text-gray-200 mt-1">
            <span className="uppercase tracking-wider">{period.period_type}</span>
          </p>
        </div>
        <div className="flex gap-3">
          <Button
            onClick={() => navigate(`/ratio-analysis/${periodId}`)}
            className="font-bold shadow-md bg-blue-600 dark:bg-blue-700 text-white hover:bg-blue-700 dark:hover:bg-blue-800"
          >
            View Dashboard
          </Button>
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200 dark:border-gray-700 mt-6">
        <nav className="-mb-px flex space-x-8">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`py-4 px-1 border-b-2 font-bold text-base transition-colors ${activeTab === tab.id
                ? "border-brand-600 text-brand-700 dark:text-brand-400"
                : "border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-200"
                }`}
            >
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      <div className="mb-4 p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 text-blue-900 dark:text-blue-100 font-semibold text-sm mt-4">
        Info: Financial statements are read-only and cannot be updated.
      </div>
      <div className="mt-6 bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
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
      <div className="mt-6 p-6 bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
        <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4 border-b pb-2">
          Completion Status
        </h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          <div className="flex items-center p-3 bg-gray-50 dark:bg-gray-900 rounded-md">
            <div
              className={`w-4 h-4 rounded-full mr-3 shadow-sm ${period.trading_account
                ? "bg-green-600"
                : "bg-gray-300 dark:bg-gray-600"
                }`}
            />
            <span className="font-bold text-gray-800 dark:text-gray-200">
              Trading Account
            </span>
          </div>
          <div className="flex items-center p-3 bg-gray-50 dark:bg-gray-900 rounded-md">
            <div
              className={`w-4 h-4 rounded-full mr-3 shadow-sm ${period.profit_loss
                ? "bg-green-600"
                : "bg-gray-300 dark:bg-gray-600"
                }`}
            />
            <span className="font-bold text-gray-800 dark:text-gray-200">
              Profit & Loss
            </span>
          </div>
          <div className="flex items-center p-3 bg-gray-50 dark:bg-gray-900 rounded-md">
            <div
              className={`w-4 h-4 rounded-full mr-3 shadow-sm ${period.balance_sheet
                ? "bg-green-600"
                : "bg-gray-300 dark:bg-gray-600"
                }`}
            />
            <span className="font-bold text-gray-800 dark:text-gray-200">
              Balance Sheet
            </span>
          </div>
          <div className="flex items-center p-3 bg-gray-50 dark:bg-gray-900 rounded-md">
            <div
              className={`w-4 h-4 rounded-full mr-3 shadow-sm ${period.operational_metrics
                ? "bg-green-600"
                : "bg-gray-300 dark:bg-gray-600"
                }`}
            />
            <span className="font-bold text-gray-800 dark:text-gray-200">
              Operational Metrics
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FinancialPeriodPage;
