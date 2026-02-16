import React, { useState, useEffect } from "react";
import { BeatLoader } from "react-spinners";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import PageBreadcrumb from "../../components/common/PageBreadCrumb";
import PageMeta from "../../components/common/PageMeta";
import { getPeriodsList, getRatioTrends, RatioCategory, PeriodWithRatiosData } from "./api";
import { getRatioResults, RatioResultData } from "../FinancialStatements/api";
import RatioCard from "../../components/RatioCard";
import { ArrowLeft, Download, TrendingUp } from "lucide-react";
import { exportRatioAnalysisToExcel, exportRatioAnalysisToPDF } from "../../utils/exportUtils";
import PeriodDataEditForm from "./PeriodDataEditForm";
import TrendAnalysisChart from "./TrendAnalysisChart";

const CompanyRatioAnalysis: React.FC = () => {

  const [periods, setPeriods] = useState<PeriodWithRatiosData[]>([]);
  const [selectedPeriod, setSelectedPeriod] = useState<PeriodWithRatiosData | null>(null);
  const [ratios, setRatios] = useState<RatioResultData | null>(null);
  const [ratioTrends, setRatioTrends] = useState<any[]>([]);
  const [showTrendAnalysis, setShowTrendAnalysis] = useState(false);

  const [loading, setLoading] = useState(true); // Used for initial load of periods now

  const [loadingRatios, setLoadingRatios] = useState(false);
  const [loadingTrends, setLoadingTrends] = useState(false);
  const [isExporting, setIsExporting] = useState(false);

  // Load periods on component mount
  useEffect(() => {
    loadPeriods();
  }, []);

  const loadPeriods = async () => {
    try {
      setLoading(true);
      const data = await getPeriodsList();
      setPeriods(data);

      if (data.length === 0) {
        toast.info("No financial periods found.");
      } else if (data.filter(p => p.ratios != null).length === 0) {
        toast.warning("Periods found but ratio data is not available yet. Please calculate ratios first.");
      }

    } catch (error) {
      console.error("Error loading periods:", error);
      toast.error("Failed to load periods");
    } finally {
      setLoading(false);
    }
  };



  // Fetch ratio trends only when "View Trend Analysis" is clicked
  const handleViewTrendAnalysis = async (category?: RatioCategory) => {


    // Validate we have enough periods with ratio data
    if (periods.length < 2) {
      toast.error("At least 2 periods are required for trend analysis");
      return;
    }

    const periodsWithRatios = periods.filter(p => p.ratios != null);
    console.log(`Trend analysis validation: ${periodsWithRatios.length} periods with ratios out of ${periods.length} total`);
    console.log("Periods with ratios:", periodsWithRatios);

    if (periodsWithRatios.length < 2) {
      toast.error("At least 2 periods with ratio data are required for trend analysis");
      return;
    }

    try {
      setLoadingTrends(true);
      setShowTrendAnalysis(true);
      // Call API with optional category filter
      const trendsData = await getRatioTrends(category);
      console.log("Trend data received from API:", trendsData);

      if (!trendsData || trendsData.length < 2) {
        console.warn("Insufficient trend data received:", trendsData);
        toast.warning("Insufficient data to display trends. Please ensure multiple periods are available.");
        setShowTrendAnalysis(false);
        return;
      }

      setRatioTrends(trendsData);
    } catch (error) {
      console.error("Error loading trends:", error);
      toast.error("Failed to load trend data");
      setShowTrendAnalysis(false);
    } finally {
      setLoadingTrends(false);
    }
  };

  const handleSelectPeriod = async (period: PeriodWithRatiosData) => {
    try {
      setSelectedPeriod(period);
      setLoadingRatios(true);

      // Ratios are already loaded with the period data from the optimized dashboard API
      // No additional API call needed - significant performance improvement!
      if (period.ratios) {
        setRatios(period.ratios);
      } else {
        // Fallback to old API in case ratios are missing (backward compatibility)
        console.warn("Ratios not found in period data, falling back to separate API call");
        const ratioData = await getRatioResults(period.id);
        setRatios(ratioData);
      }
    } catch (error) {
      console.error("Error loading ratio data:", error);
      toast.error("Failed to load ratio data");
    } finally {
      setLoadingRatios(false);
    }
  };



  const handleBackToPeriods = () => {
    setSelectedPeriod(null);
    setRatios(null);
  };

  const handleExportToExcel = async () => {
    if (!ratios || !selectedPeriod) {
      toast.warning("No ratio data to export");
      return;
    }

    try {
      setIsExporting(true);
      exportRatioAnalysisToExcel(
        ratios,
        "Financial Ratio Analysis",
        selectedPeriod.label,
        "Ratio_Analysis"
      );
      toast.success("Ratio analysis exported to Excel successfully!");
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Failed to export to Excel");
    } finally {
      setIsExporting(false);
    }
  };

  const handleExportToPDF = async () => {
    if (!ratios || !selectedPeriod) {
      toast.warning("No ratio data to export");
      return;
    }

    try {
      setIsExporting(true);
      exportRatioAnalysisToPDF(
        ratios,
        "Financial Ratio Analysis",
        selectedPeriod.label,
        "Ratio_Analysis"
      );
      toast.success("Ratio analysis exported to PDF successfully!");
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Failed to export to PDF");
    } finally {
      setIsExporting(false);
    }
  };

  return (
    <>
      <PageMeta
        title="Ratio Analysis"
        description="Analyze financial ratios by period"
      />
      <PageBreadcrumb pageTitle="Ratio Analysis" />

      <div className="p-6">
        <ToastContainer position="top-right" autoClose={3000} />

        {/* Periods Selection Screen - Default View */}
        {!selectedPeriod && !showTrendAnalysis && (
          <div>
            <div className="flex items-center justify-end gap-3 mb-6">
              {periods.length > 1 && periods.filter(p => p.ratios != null).length >= 2 && (
                <button
                  onClick={() => handleViewTrendAnalysis()}
                  disabled={loadingTrends}
                  className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  title="Compare ratio metrics across multiple periods"
                >
                  <TrendingUp className="w-4 h-4" />
                  {loadingTrends ? "Loading..." : "View Trend Analysis"}
                </button>
              )}
            </div>

            <h1 className="text-2xl font-bold mb-2 text-gray-900 dark:text-white">
              Financial Periods
            </h1>
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-6">
              Select a period to view ratio analysis
              {periods.length > 0 && (
                <span className="ml-2 text-xs bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200 px-2 py-1 rounded inline-block">
                  {periods.filter(p => p.ratios != null).length}/{periods.length} with ratios
                </span>
              )}
            </p>

            {loading ? (
              <div className="flex items-center justify-center h-64">
                <BeatLoader color="#3b82f6" />
              </div>
            ) : periods.length === 0 ? (
              <div className="p-6 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
                <p className="text-yellow-800 dark:text-yellow-200">
                  No financial periods found.
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {periods.map((period) => (
                  <div
                    key={period.id}
                    onClick={() => handleSelectPeriod(period)}
                    className="p-4 bg-white dark:bg-gray-800 rounded-lg shadow cursor-pointer hover:shadow-lg hover:scale-105 transition-all"
                  >
                    <div className="flex justify-between items-start mb-2">
                      <h3 className="font-semibold text-lg text-gray-900 dark:text-white">
                        {period.label}
                      </h3>
                      <span
                        className={`text-xs px-2 py-1 rounded ${period.period_type === "YEARLY"
                          ? "bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200"
                          : period.period_type === "QUARTERLY"
                            ? "bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200"
                            : "bg-purple-100 dark:bg-purple-900 text-purple-800 dark:text-purple-200"
                          }`}
                      >
                        {period.period_type}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">
                      {new Date(period.start_date).toLocaleDateString()} -{" "}
                      {new Date(period.end_date).toLocaleDateString()}
                    </p>
                    <p
                      className={`text-xs font-medium ${period.is_finalized
                        ? "text-green-600 dark:text-green-400"
                        : "text-gray-500 dark:text-gray-500"
                        }`}
                    >
                      {period.is_finalized ? "✓ Finalized" : "Draft"}
                    </p>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Ratio Analysis Screen */}
        {selectedPeriod && (
          <div>
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <button
                  onClick={handleBackToPeriods}
                  className="flex items-center gap-2 px-4 py-2 text-blue-600 dark:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                >
                  <ArrowLeft className="w-5 h-5" />
                  Back to Periods
                </button>
              </div>

              {/* Export and Update buttons */}
              <div className="flex items-center gap-3">
                {ratios && (
                  <div className="relative group">
                    <button
                      disabled={isExporting}
                      className="flex items-center gap-2 px-4 py-2 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      <Download className="w-4 h-4" />
                      Export
                      <svg className="w-4 h-4 text-gray-500 group-hover:text-gray-700 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                      </svg>
                    </button>
                    <div className="absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50">
                      <button
                        onClick={handleExportToExcel}
                        disabled={isExporting}
                        className="w-full px-4 py-2 text-left text-sm hover:bg-gray-50 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 first:rounded-t-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                      >
                        <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6z"></path>
                        </svg>
                        Export to Excel
                      </button>
                      <button
                        onClick={handleExportToPDF}
                        disabled={isExporting}
                        className="w-full px-4 py-2 text-left text-sm hover:bg-gray-50 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 last:rounded-b-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                      >
                        <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                          <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                          <polyline points="13 2 13 9 20 9"></polyline>
                        </svg>
                        Export to PDF
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>

            <div className="mb-6">
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                Ratio Analysis
              </h1>
              <p className="text-gray-600 dark:text-gray-400">
                {selectedPeriod.label} ({selectedPeriod.period_type})
              </p>

              {/* Uploaded File Section */}
              {selectedPeriod.uploaded_file && (() => {
                // Construct the file URL - check if it's already a full URL
                const fileUrl = selectedPeriod.uploaded_file.startsWith('http')
                  ? selectedPeriod.uploaded_file
                  : `http://127.0.0.1:8000/${selectedPeriod.uploaded_file}`;

                return (
                  <div className="mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                    <a
                      href={fileUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center gap-3 hover:opacity-80 transition-opacity cursor-pointer"
                    >
                      {/* File Icon based on type */}
                      {selectedPeriod.file_type === 'excel' && (
                        <svg className="w-8 h-8 text-green-600 dark:text-green-400 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24">
                          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6z"></path>
                          <path d="M14 2v6h6"></path>
                          <path d="M9 15l2 2 4-4" stroke="white" strokeWidth="1.5" fill="none"></path>
                        </svg>
                      )}
                      {selectedPeriod.file_type === 'docx' && (
                        <svg className="w-8 h-8 text-blue-600 dark:text-blue-400 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24">
                          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6z"></path>
                          <path d="M14 2v6h6"></path>
                        </svg>
                      )}
                      {selectedPeriod.file_type === 'pdf' && (
                        <svg className="w-8 h-8 text-red-600 dark:text-red-400 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24">
                          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6z"></path>
                          <path d="M14 2v6h6"></path>
                        </svg>
                      )}
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                          {selectedPeriod.uploaded_file.split('/').pop()?.split('_').slice(1).join('_') || 'Financial Document'}
                        </p>
                        <p className="text-xs text-gray-600 dark:text-gray-400">
                          {selectedPeriod.file_type?.toUpperCase()} file • Click to open
                        </p>
                      </div>
                    </a>
                  </div>
                );
              })()}
            </div>

            {loadingRatios ? (
              <div className="flex items-center justify-center h-64">
                <BeatLoader color="#3b82f6" />
              </div>
            ) : !ratios ? (
              <div className="p-6 bg-red-50 dark:bg-red-900/20 rounded-lg">
                <p className="text-red-600 dark:text-red-400">
                  No ratio data found. Enter period data below and click Update to calculate ratios.
                </p>
              </div>
            ) : (
              <RatioAnalysisDisplay ratios={ratios} />
            )}

            {/* Edit period data (all 4 tables) and single Update → recalculate → store RatioResult */}
            <div className="mt-10 p-6 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
                Edit period data & recalculate ratios
              </h2>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                Update Trading Account, Profit & Loss, Balance Sheet, and Operational Metrics. Then click &quot;Update data & recalculate ratios&quot; to save and store updated ratio results.
              </p>
              <PeriodDataEditForm
                periodId={selectedPeriod.id}
                onSuccess={async () => {
                  const ratioData = await getRatioResults(selectedPeriod.id);
                  setRatios(ratioData);
                  toast.success("Period data updated and ratio results recalculated and saved.");
                }}
              />
            </div>
          </div>
        )}

        {/* Trend Analysis Screen */}
        {showTrendAnalysis && (
          <div>
            <div className="flex items-center gap-3 mb-6">
              <button
                onClick={() => setShowTrendAnalysis(false)}
                className="flex items-center gap-2 px-4 py-2 text-blue-600 dark:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
              >
                <ArrowLeft className="w-5 h-5" />
                Back to Periods
              </button>
            </div>

            {loadingTrends ? (
              <div className="flex items-center justify-center h-64">
                <BeatLoader color="#3b82f6" />
              </div>
            ) : !ratioTrends || ratioTrends.length < 2 ? (
              <div className="p-6 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg border border-yellow-200 dark:border-yellow-800">
                <p className="text-yellow-800 dark:text-yellow-200 font-medium mb-2">
                  ⚠️ Insufficient Data
                </p>
                <p className="text-yellow-700 dark:text-yellow-300 text-sm mb-3">
                  At least 2 periods with ratio data are required for trend analysis.
                </p>
                <div className="bg-yellow-100 dark:bg-yellow-900/40 p-3 rounded text-xs text-yellow-700 dark:text-yellow-300">
                  <p><strong>Available periods:</strong> {ratioTrends?.length || 0} of {periods.length}</p>
                  <p className="mt-2">
                    {periods.filter(p => p.ratios != null).length < 2
                      ? "Periods found but ratios not calculated. Select periods above and calculate ratios first."
                      : "Ensure selected periods have completed ratio calculations."}
                  </p>
                </div>
              </div>
            ) : (
              <TrendAnalysisChart
                ratioData={ratioTrends}
                periods={periods}
              />
            )}
          </div>
        )}
      </div>
    </>
  );
};

// Sub-component to display ratios organized by category
const RatioAnalysisDisplay: React.FC<{ ratios: RatioResultData }> = ({
  ratios,
}) => {
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

  const capitalRatios = [
    {
      name: "Capital Ratio",
      value: ratios.own_fund_to_wf || 0,
      unit: "%",
      idealValue: 8.0,
      status: ratios.traffic_light_status?.own_fund_to_wf,
    },
  ];

  const fundStructureRatios = [
    {
      name: "Net Own Funds",
      value: ratios.net_own_funds || 0,
      unit: "₹",
      status: ratios.traffic_light_status?.net_own_funds,
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
      status: ratios.traffic_light_status?.earning_assets_to_wf,
    },
    {
      name: "Interest Tagged Funds to WF",
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
      name: "Misc Income to Working Fund",
      value: ratios.misc_income_to_wf || 0,
      unit: "%",
      status: ratios.traffic_light_status?.misc_income_to_wf,
    },
    {
      name: "Interest Exp to Interest Income",
      value: ratios.interest_exp_to_interest_income || 0,
      unit: "%",
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

  const capitalEfficiencyRatios = [
    {
      name: "Capital Turnover Ratio",
      value: ratios.capital_turnover_ratio || 0,
      unit: "times",
      status: ratios.traffic_light_status?.capital_turnover_ratio,
    },
  ];

  const productivityRatios = [
    {
      name: "Per Employee Deposit",
      value: ratios.per_employee_deposit || 0,
      unit: "Lakhs",
      status: ratios.traffic_light_status?.per_employee_deposit,
    },
    {
      name: "Per Employee Loan",
      value: ratios.per_employee_loan || 0,
      unit: "Lakhs",
      status: ratios.traffic_light_status?.per_employee_loan,
    },
    {
      name: "Per Employee Contribution",
      value: ratios.per_employee_contribution || 0,
      unit: "Lakhs",
      status: ratios.traffic_light_status?.per_employee_contribution,
    },
    {
      name: "Per Employee Operating Cost",
      value: ratios.per_employee_operating_cost || 0,
      unit: "Lakhs",
      status: ratios.traffic_light_status?.per_employee_operating_cost,
    },
  ];

  return (
    <div className="space-y-8">
      {/* Working Fund Summary */}
      <div className="bg-blue-50 dark:bg-blue-900/20 p-6 rounded-lg border border-blue-200 dark:border-blue-800">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
          Working Fund
        </h2>
        <p className="text-3xl font-bold text-blue-600 dark:text-blue-400">
          ₹{ratios.working_fund?.toLocaleString("en-IN", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          }) ?? "0.00"}
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

      {/* Trading Ratios */}
      <div>
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
          Trading Ratios
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {tradingRatios.map((ratio, idx) => (
            <RatioCard key={idx} {...ratio} />
          ))}
        </div>
      </div>

      {/* Capital Ratios */}
      <div>
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
          Capital Ratios
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {capitalRatios.map((ratio, idx) => (
            <RatioCard key={idx} {...ratio} />
          ))}
        </div>
      </div>

      {/* Fund Structure Ratios */}
      <div>
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
          Fund Structure
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {fundStructureRatios.map((ratio, idx) => (
            <RatioCard key={idx} {...ratio} />
          ))}
        </div>
      </div>

      {/* Yield & Cost Ratios */}
      <div>
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
          Yield & Cost Analysis
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {yieldCostRatios.map((ratio, idx) => (
            <RatioCard key={idx} {...ratio} />
          ))}
        </div>
      </div>

      {/* Margin Ratios */}
      <div>
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
          Margin Analysis
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {marginRatios.map((ratio, idx) => (
            <RatioCard key={idx} {...ratio} />
          ))}
        </div>
      </div>

      {/* Capital Efficiency Ratios */}
      <div>
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
          Capital Efficiency
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {capitalEfficiencyRatios.map((ratio, idx) => (
            <RatioCard key={idx} {...ratio} />
          ))}
        </div>
      </div>

      {/* Productivity Ratios */}
      <div>
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
          Productivity Analysis
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {productivityRatios.map((ratio, idx) => (
            <RatioCard key={idx} {...ratio} />
          ))}
        </div>
      </div>
    </div>
  );
};

export default CompanyRatioAnalysis;
