import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  getFinancialPeriod,
  getRatioResults,
  RatioResultData,
  FinancialPeriodData,
} from "../FinancialStatements/api";
import RatioCard from "../../components/RatioCard";
import RatioAnalysisTable from "../../components/RatioAnalysisTable";
import { BeatLoader } from "react-spinners";
import { toast, ToastContainer } from "react-toastify";
import { LayoutGrid, Table, ArrowLeft } from "lucide-react";
import "react-toastify/dist/ReactToastify.css";
import PeriodDataEditForm from "../CompanyRatioAnalysis/PeriodDataEditForm";

const RatioDashboard: React.FC = () => {
  const { periodId } = useParams<{ periodId: string }>();
  const navigate = useNavigate();
  const [ratios, setRatios] = useState<RatioResultData | null>(null);
  const [period, setPeriod] = useState<FinancialPeriodData | null>(null);
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState<"cards" | "table">("cards");

  useEffect(() => {
    if (periodId) {
      loadData();
    }
  }, [periodId]);

  const loadData = async () => {
    if (!periodId) return;
    setLoading(true);
    try {
      const [ratioData, periodData] = await Promise.all([
        getRatioResults(parseInt(periodId)),
        getFinancialPeriod(parseInt(periodId)),
      ]);
      setRatios(ratioData);
      setPeriod(periodData);
    } catch (error) {
      console.error("Error loading ratio data:", error);
      toast.error("Failed to load ratio data");
    } finally {
      setLoading(false);
    }
  };

  const handleDataUpdate = () => {
    loadData();
    toast.success("Period data updated and ratio results recalculated.");
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <BeatLoader color="#3b82f6" />
      </div>
    );
  }

  if (!ratios) {
    return (
      <div className="p-6">
        <p className="text-red-600 dark:text-red-400">
          No ratio data found. Please calculate ratios first.
        </p>
      </div>
    );
  }

  const tradingRatios = [
    {
      name: "Stock Turnover",
      value: ratios.stock_turnover,
      unit: "times",
      idealValue: 15.0,
      status: ratios.traffic_light_status?.stock_turnover,
    },
    {
      name: "Gross Profit Ratio",
      value: ratios.gross_profit_ratio || 0,
      unit: "%",
      idealValue: 10.0,
      status: ratios.traffic_light_status?.gross_profit_ratio,
    },
    {
      name: "Net Profit Ratio",
      value: ratios.net_profit_ratio || 0,
      unit: "%",
      status: ratios.traffic_light_status?.net_profit_ratio,
    },
  ];

  const capitalEfficiencyRatios = [
    {
      name: "Capital Turnover Ratio",
      value: ratios.capital_turnover_ratio || 0,
      unit: "times",
      idealValue: 6.0,
      status: ratios.traffic_light_status?.capital_turnover_ratio,
    },
  ];

  const fundStructureRatios = [
    {
      name: "Net Own Funds",
      value: ratios.net_own_funds || 0,
      unit: "",
      status: (ratios.net_own_funds && ratios.net_own_funds > 0 ? "green" : "red") as "green" | "red",
    },
    {
      name: "Own Fund to Working Fund",
      value: ratios.own_fund_to_wf || 0,
      unit: "%",
      idealValue: 8.0,
      status: ratios.traffic_light_status?.own_fund_to_wf,
    },
    {
      name: "Deposits to Working Fund",
      value: ratios.deposits_to_wf || 0,
      unit: "%",
      status: ratios.traffic_light_status?.deposits_to_wf,
    },
    {
      name: "Borrowings to Working Fund",
      value: ratios.borrowings_to_wf || 0,
      unit: "%",
      status: ratios.traffic_light_status?.borrowings_to_wf,
    },
    {
      name: "Loans to Working Fund",
      value: ratios.loans_to_wf || 0,
      unit: "%",
      idealValue: 70.0,
      status: ratios.traffic_light_status?.loans_to_wf,
    },
    {
      name: "Investments to Working Fund",
      value: ratios.investments_to_wf || 0,
      unit: "%",
      idealValue: 25.0,
      status: ratios.traffic_light_status?.investments_to_wf,
    },
    {
      name: "Earning Assets to Working Fund",
      value: ratios.earning_assets_to_wf || 0,
      unit: "%",
      idealValue: 80.0,
      status: ratios.traffic_light_status?.earning_assets_to_wf,
    },
    {
      name: "Interest Tagged Funds to Working Fund",
      value: ratios.interest_tagged_funds_to_wf || 0,
      unit: "%",
      status: ratios.traffic_light_status?.interest_tagged_funds_to_wf,
    },
  ];

  const yieldCostRatios = [
    {
      name: "Cost of Deposits",
      value: ratios.cost_of_deposits,
      unit: "%",
      status: ratios.traffic_light_status?.cost_of_deposits,
    },
    {
      name: "Yield on Loans",
      value: ratios.yield_on_loans,
      unit: "%",
      status: ratios.traffic_light_status?.yield_on_loans,
    },
    {
      name: "Yield on Investments",
      value: ratios.yield_on_investments || 0,
      unit: "%",
      status: ratios.traffic_light_status?.yield_on_investments,
    },
    {
      name: "Credit Deposit Ratio",
      value: ratios.credit_deposit_ratio,
      unit: "%",
      idealValue: 70.0,
      status: ratios.traffic_light_status?.credit_deposit_ratio,
    },
    {
      name: "Avg Cost of Working Fund",
      value: ratios.avg_cost_of_wf || 0,
      unit: "%",
      idealValue: 3.5,
      status: ratios.traffic_light_status?.avg_cost_of_wf,
    },
    {
      name: "Avg Yield on Working Fund",
      value: ratios.avg_yield_on_wf || 0,
      unit: "%",
      idealValue: 3.5,
      status: ratios.traffic_light_status?.avg_yield_on_wf,
    },
    {
      name: "Miscellaneous Income to WF",
      value: ratios.misc_income_to_wf || 0,
      unit: "%",
      idealValue: 0.50,
      status: ratios.traffic_light_status?.misc_income_to_wf,
    },
    {
      name: "Interest Expenses to Interest Income",
      value: ratios.interest_exp_to_interest_income || 0,
      unit: "%",
      idealValue: 62.0,
      status: ratios.traffic_light_status?.interest_exp_to_interest_income,
    },
  ];

  const marginRatios = [
    {
      name: "Gross Financial Margin",
      value: ratios.gross_fin_margin,
      unit: "%",
      idealValue: 3.5,
      status: ratios.traffic_light_status?.gross_fin_margin,
    },
    {
      name: "Operating Cost to Working Fund",
      value: ratios.operating_cost_to_wf || 0,
      unit: "%",
      idealValue: 2.5,
      status: ratios.traffic_light_status?.operating_cost_to_wf,
    },
    {
      name: "Net Financial Margin",
      value: ratios.net_fin_margin,
      unit: "%",
      idealValue: 1.5,
      status: ratios.traffic_light_status?.net_fin_margin,
    },
    {
      name: "Risk Cost to Working Fund",
      value: ratios.risk_cost_to_wf || 0,
      unit: "%",
      idealValue: 0.25,
      status: ratios.traffic_light_status?.risk_cost_to_wf,
    },
    {
      name: "Net Margin",
      value: ratios.net_margin,
      unit: "%",
      idealValue: 1.0,
      status: ratios.traffic_light_status?.net_margin,
    },
  ];

  const productivityRatios = [
    {
      name: "Per Employee Deposit",
      value: ratios.per_employee_deposit || 0,
      unit: " Lakhs",
      idealValue: 200.0,
      status: ratios.traffic_light_status?.per_employee_deposit,
    },
    {
      name: "Per Employee Loan",
      value: ratios.per_employee_loan || 0,
      unit: " Lakhs",
      idealValue: 150.0,
      status: ratios.traffic_light_status?.per_employee_loan,
    },
    {
      name: "Per Employee Contribution",
      value: ratios.per_employee_contribution || 0,
      unit: " Lakhs",
      status: ratios.traffic_light_status?.per_employee_contribution,
    },
    {
      name: "Per Employee Operating Cost",
      value: ratios.per_employee_operating_cost || 0,
      unit: " Lakhs",
      status: ratios.traffic_light_status?.per_employee_operating_cost,
    },
  ];

  return (
    <div className="p-6 space-y-6">
      <ToastContainer position="bottom-right" autoClose={3000} />

      {/* Header */}
      <div className="flex justify-between items-start">
        <div>
          <button
            onClick={() => navigate('/ratio-analysis')}
            className="flex items-center gap-2 text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 mb-2 transition-colors"
          >
            <ArrowLeft size={20} />
            <span>Back to Periods</span>
          </button>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Ratio Analysis Dashboard
          </h1>
          {period && (
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
              {period.label} - Calculated on{" "}
              {new Date(ratios.calculated_at).toLocaleDateString()}
            </p>
          )}
        </div>

        {/* View Toggle */}
        <div className="flex gap-2 bg-gray-100 dark:bg-gray-800 rounded-lg p-1">
          <button
            onClick={() => setViewMode("cards")}
            className={`px-4 py-2 rounded flex items-center gap-2 transition-colors ${viewMode === "cards"
              ? "bg-blue-600 text-white"
              : "bg-transparent text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
              }`}
          >
            <LayoutGrid className="w-4 h-4" />
            Cards
          </button>
          <button
            onClick={() => setViewMode("table")}
            className={`px-4 py-2 rounded flex items-center gap-2 transition-colors ${viewMode === "table"
              ? "bg-blue-600 text-white"
              : "bg-transparent text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
              }`}
          >
            <Table className="w-4 h-4" />
            Table
          </button>
        </div>
      </div>

      {/* Working Fund Summary - Always Show */}
      <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
          Working Fund
        </h2>
        <p className="text-3xl font-bold text-blue-600 dark:text-blue-400">
          ₹{ratios.working_fund.toLocaleString("en-IN", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          })}
        </p>
      </div>

      {/* Interpretation Section */}
      {ratios.interpretation && (
        <div className="bg-blue-50 dark:bg-blue-900/20 p-6 rounded-lg border border-blue-200 dark:border-blue-800">
          <h2 className="text-xl font-bold mb-2 text-gray-900 dark:text-white">
            Interpretation
          </h2>
          <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
            {ratios.interpretation}
          </p>
        </div>
      )}

      {/* View-based Content */}
      {viewMode === "table" ? (
        <RatioAnalysisTable ratios={ratios} period={period?.label} />
      ) : (
        <>
          {/* Trading Ratios */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              Trading Ratios
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {tradingRatios.map((ratio) => (
                <RatioCard key={ratio.name} {...ratio} />
              ))}
            </div>
          </div>

          {/* Capital Efficiency Ratios */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              Capital Efficiency
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {capitalEfficiencyRatios.map((ratio) => (
                <RatioCard key={ratio.name} {...ratio} />
              ))}
            </div>
          </div>

          {/* Fund Structure Ratios */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              Fund Structure Ratios
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {fundStructureRatios.map((ratio) => (
                <RatioCard key={ratio.name} {...ratio} />
              ))}
            </div>
          </div>

          {/* Yield & Cost Ratios */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              Yield & Cost Ratios
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {yieldCostRatios.map((ratio) => (
                <RatioCard key={ratio.name} {...ratio} />
              ))}
            </div>
          </div>

          {/* Margin Ratios */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              Margin Ratios
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {marginRatios.map((ratio) => (
                <RatioCard key={ratio.name} {...ratio} />
              ))}
            </div>
          </div>

          {/* Productivity Ratios */}
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              Productivity Ratios
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {productivityRatios.map((ratio) => (
                <RatioCard key={ratio.name} {...ratio} />
              ))}
            </div>
          </div>
        </>
      )}

      {/* Legend - Only show in card view */}
      {viewMode === "cards" && (
        <div className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
          <h3 className="text-sm font-semibold text-gray-900 dark:text-white mb-3">
            Status Legend
          </h3>
          <div className="flex flex-wrap gap-4">
            <div className="flex items-center">
              <div className="w-3 h-3 rounded-full bg-green-500 mr-2" />
              <span className="text-sm text-gray-600 dark:text-gray-400">
                Meets or exceeds ideal
              </span>
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 rounded-full bg-yellow-500 mr-2" />
              <span className="text-sm text-gray-600 dark:text-gray-400">
                Sub-optimal but acceptable
              </span>
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 rounded-full bg-red-500 mr-2" />
              <span className="text-sm text-gray-600 dark:text-gray-400">
                Critical - requires attention
              </span>
            </div>
          </div>
        </div>
      )}

      {/* Edit period data */}
      <div className="mt-10 p-6 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
          Edit period data & recalculate ratios
        </h2>
        <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
          Update Trading Account, Profit & Loss, Balance Sheet, and Operational Metrics. Then click &quot;Update data & recalculate ratios&quot; to save and store updated ratio results.
        </p>
        <PeriodDataEditForm
          periodId={parseInt(periodId!)}
          onSuccess={handleDataUpdate}
        />
      </div>
    </div>
  );
};
export default RatioDashboard;
