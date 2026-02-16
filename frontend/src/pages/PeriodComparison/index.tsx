import React, { useState, useEffect } from "react";
import { BeatLoader } from "react-spinners";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import PageBreadcrumb from "../../components/common/PageBreadCrumb";
import PageMeta from "../../components/common/PageMeta";
import Button from "../../components/ui/button/Button";
import {
  getPeriodsList,
  comparePeriodsById,
  PeriodListData,
  PeriodComparisonResponse,
} from "./api";
import { Search, ChevronDown, ArrowRightLeft } from "lucide-react";

const PeriodComparison: React.FC = () => {
  const [periods, setPeriods] = useState<PeriodListData[]>([]);
  const [selectedPeriod1, setSelectedPeriod1] = useState<PeriodListData | null>(null);
  const [selectedPeriod2, setSelectedPeriod2] = useState<PeriodListData | null>(null);
  const [comparisonData, setComparisonData] = useState<PeriodComparisonResponse | null>(null);
  const [searchPeriod1, setSearchPeriod1] = useState("");
  const [searchPeriod2, setSearchPeriod2] = useState("");
  const [openDropdown1, setOpenDropdown1] = useState(false);
  const [openDropdown2, setOpenDropdown2] = useState(false);

  const [loading, setLoading] = useState(true);
  const [loadingComparison, setLoadingComparison] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showTableView, setShowTableView] = useState(true);
  const [spinCount, setSpinCount] = useState(0);

  useEffect(() => {
    loadPeriods();
  }, []);

  const loadPeriods = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getPeriodsList();
      console.log("Periods loaded:", data);
      setPeriods(data);
    } catch (error: any) {
      console.error("Error loading periods:", error);
      const errorMessage = error?.response?.data?.message || error?.message || "Failed to load periods";
      setError(errorMessage);
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleCompare = async () => {
    if (!selectedPeriod1 || !selectedPeriod2) {
      toast.warning("Please select both periods");
      return;
    }

    if (selectedPeriod1.id === selectedPeriod2.id) {
      toast.warning("Please select two different periods");
      return;
    }

    try {
      setLoadingComparison(true);
      // Use period IDs instead of labels for faster API calls
      const rawData = await comparePeriodsById(
        selectedPeriod1.id,
        selectedPeriod2.id
      );

      console.log("Raw API response:", rawData);

      // Transform API response to match component expectations
      if (rawData.data && rawData.data.period_1 && rawData.data.period_2 && rawData.data.difference) {
        const period1 = rawData.data.period_1;
        const period2 = rawData.data.period_2;
        const difference = rawData.data.difference;

        // List of all ratio fields to compare - ONLY fields that exist in RatioResult model
        const ratioFields = [
          // Trading Ratios (3)
          'stock_turnover', 'gross_profit_ratio', 'net_profit_ratio',
          // Fund Structure Ratios (8)
          'net_own_funds', 'own_fund_to_wf', 'deposits_to_wf', 'borrowings_to_wf',
          'loans_to_wf', 'investments_to_wf', 'earning_assets_to_wf', 'interest_tagged_funds_to_wf',
          // Yield & Cost Ratios (8)
          'cost_of_deposits', 'yield_on_loans', 'yield_on_investments', 'credit_deposit_ratio',
          'avg_cost_of_wf', 'avg_yield_on_wf', 'misc_income_to_wf', 'interest_exp_to_interest_income',
          // Margin Ratios (5)
          'gross_fin_margin', 'operating_cost_to_wf', 'net_fin_margin', 'risk_cost_to_wf', 'net_margin',
          // Capital Efficiency (1)
          'capital_turnover_ratio',
          // Productivity Ratios (4)
          'per_employee_deposit', 'per_employee_loan', 'per_employee_contribution', 'per_employee_operating_cost',
          // Working Fund (1)
          'working_fund'
        ];

        // Build ratios object for component
        const ratios: any = {};
        ratioFields.forEach((field) => {
          const p1Value = period1[field] !== undefined ? period1[field] : null;
          const p2Value = period2[field] !== undefined ? period2[field] : null;
          const diff = difference[field];

          ratios[field] = {
            period1: p1Value,
            period2: p2Value,
            difference: diff ? diff.value : null,
            percentage_change: diff ? diff.percentage_change : null
          };
        });

        // Transform to component format
        const transformedData: PeriodComparisonResponse = {
          status: rawData.status,
          response_code: rawData.response_code,
          data: {
            period1: selectedPeriod1.label,
            period2: selectedPeriod2.label,
            ratios
          }
        };

        console.log("Transformed comparison data:", transformedData);
        setComparisonData(transformedData);
        toast.success("Comparison loaded successfully");
      } else {
        throw new Error("Invalid response structure from API");
      }
    } catch (error: any) {
      console.error("Error comparing periods:", error);
      const errorMessage =
        error?.response?.data?.message ||
        error?.message ||
        "Failed to compare periods";
      toast.error(errorMessage);
    } finally {
      setLoadingComparison(false);
    }
  };



  const handleBackFromComparison = () => {
    setSelectedPeriod1(null);
    setSelectedPeriod2(null);
    setComparisonData(null);
  };

  const formatRatioName = (name: string): string => {
    // Convert snake_case to Title Case
    return name
      .split("_")
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(" ");
  };

  const getChangeColor = (change: number | null): string => {
    if (change === null) return "text-gray-500";
    if (change > 0) return "text-green-600";
    if (change < 0) return "text-red-600";
    return "text-gray-500";
  };

  function filterPeriods({ searchTerm, excludeId }: { searchTerm: string; excludeId?: number; }): PeriodListData[] {
    return periods.filter((period) => {
      const matchesSearch = period.label.toLowerCase().includes(searchTerm.toLowerCase()) ||
        period.period_type.toLowerCase().includes(searchTerm.toLowerCase());
      const notExcluded = excludeId ? period.id !== excludeId : true;
      return matchesSearch && notExcluded;
    });
  }

  if (loading) {
    return (
      <>
        <PageMeta title="Period Comparison" description="Compare financial periods" />
        <PageBreadcrumb pageTitle="Period Comparison" />
        <div className="flex items-center justify-center h-96">
          <BeatLoader color="#3b82f6" />
        </div>
      </>
    );
  }

  if (error) {
    return (
      <>
        <PageMeta title="Period Comparison" description="Compare financial periods" />
        <PageBreadcrumb pageTitle="Period Comparison" />
        <div className="p-6">
          <ToastContainer
            position="top-right"
            autoClose={3000}
            hideProgressBar={false}
            newestOnTop={false}
            closeOnClick
            rtl={false}
            pauseOnFocusLoss
            draggable
            pauseOnHover
          />
          <div className="rounded-sm border border-red-500 bg-red-50 dark:bg-red-900/20 px-5 py-6 shadow-default dark:border-red-800 dark:bg-red-900/10">
            <h3 className="mb-2 text-xl font-semibold text-red-800 dark:text-red-300">
              Error Loading Data
            </h3>
            <p className="text-red-700 dark:text-red-400 mb-4">{error}</p>
            <button
              onClick={() => {
                setError(null);
                loadPeriods();
              }}
              className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg transition"
            >
              Retry
            </button>
          </div>
        </div>
      </>
    );
  }



  // Step 2: Show period selection (with results below if available)
  return (
    <>
      <PageMeta
        title={"Period Comparison"}
        description={"Compare financial periods and analyze ratio changes"}
      />
      <PageBreadcrumb pageTitle={"Period Comparison"} />

      <ToastContainer
        position="top-right"
        autoClose={3000}
        hideProgressBar={false}
        newestOnTop={false}
        closeOnClick
        rtl={false}
        pauseOnFocusLoss
        draggable
        pauseOnHover
      />

      <div className="p-6">
        <div className="rounded-sm border border-stroke bg-white px-5 pt-6 pb-2.5 shadow-default dark:border-strokedark dark:bg-boxdark sm:px-7.5 xl:pb-1">
          {/* <button
            onClick={handleBack}
            className="mb-6 flex items-center gap-2 text-blue-600 hover:text-blue-800"
          >
            <ArrowLeft className="w-4 h-4" />
            Back
          </button> */}

          <h3 className="mb-6 text-xl font-semibold text-black dark:text-white">
            {comparisonData ? `Comparison Results` : `Compare Periods`}
          </h3>

          {loading ? (
            <div className="flex items-center justify-center h-96">
              <BeatLoader color="#3b82f6" />
            </div>
          ) : periods.length === 0 ? (
            <p className="text-gray-500 dark:text-gray-400">
              No financial periods available
            </p>
          ) : (
            <div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                {/* Period 1 Dropdown */}
                <div className="relative">
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Period 1
                  </label>
                  <button
                    onClick={() => setOpenDropdown1(!openDropdown1)}
                    className="w-full p-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white flex items-center justify-between hover:border-blue-500 focus:border-blue-500 focus:outline-none"
                  >
                    <span>
                      {selectedPeriod1 ? (
                        <div>
                          <p className="font-medium">{selectedPeriod1.label}</p>
                          <p className="text-xs text-gray-500 dark:text-gray-400">
                            {selectedPeriod1.period_type}
                          </p>
                        </div>
                      ) : (
                        "Select a period..."
                      )}
                    </span>
                    <ChevronDown
                      className={`w-5 h-5 transition-transform ${openDropdown1 ? "rotate-180" : ""
                        }`}
                    />
                  </button>
                  {openDropdown1 && (
                    <div className="absolute top-full left-0 right-0 mt-1 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 shadow-lg z-10">
                      <div className="p-2 border-b border-gray-200 dark:border-gray-700">
                        <div className="relative">
                          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
                          <input
                            type="text"
                            placeholder="Search periods..."
                            value={searchPeriod1}
                            onChange={(e) => setSearchPeriod1(e.target.value)}
                            className="w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:outline-none focus:border-blue-500"
                          />
                        </div>
                      </div>
                      <div className="max-h-64 overflow-y-auto">
                        {filterPeriods({ searchTerm: searchPeriod1, excludeId: selectedPeriod2?.id }).length > 0 ? (
                          filterPeriods({ searchTerm: searchPeriod1, excludeId: selectedPeriod2?.id }).map((period) => (
                            <button
                              key={period.id}
                              onClick={() => {
                                setSelectedPeriod1(period);
                                setOpenDropdown1(false);
                                setSearchPeriod1("");
                              }}
                              className={`w-full p-3 text-left border-b border-gray-200 dark:border-gray-700 transition ${selectedPeriod1?.id === period.id
                                ? "bg-blue-100 dark:bg-blue-900 text-blue-900 dark:text-blue-200"
                                : "hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-900 dark:text-white"
                                }`}
                            >
                              <p className="font-medium">{period.label}</p>
                              <p className="text-xs text-gray-500 dark:text-gray-400">
                                {period.period_type}
                              </p>
                            </button>
                          ))
                        ) : (
                          <p className="p-3 text-center text-gray-500 dark:text-gray-400">
                            No periods found
                          </p>
                        )}
                      </div>
                    </div>
                  )}
                </div>

                {/* Period 2 Dropdown */}
                <div className="relative">
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Period 2
                  </label>
                  <button
                    onClick={() => setOpenDropdown2(!openDropdown2)}
                    className="w-full p-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white flex items-center justify-between hover:border-blue-500 focus:border-blue-500 focus:outline-none"
                  >
                    <span>
                      {selectedPeriod2 ? (
                        <div>
                          <p className="font-medium">{selectedPeriod2.label}</p>
                          <p className="text-xs text-gray-500 dark:text-gray-400">
                            {selectedPeriod2.period_type}
                          </p>
                        </div>
                      ) : (
                        "Select a period..."
                      )}
                    </span>
                    <ChevronDown
                      className={`w-5 h-5 transition-transform ${openDropdown2 ? "rotate-180" : ""
                        }`}
                    />
                  </button>
                  {openDropdown2 && (
                    <div className="absolute top-full left-0 right-0 mt-1 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 shadow-lg z-10">
                      <div className="p-2 border-b border-gray-200 dark:border-gray-700">
                        <div className="relative">
                          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
                          <input
                            type="text"
                            placeholder="Search periods..."
                            value={searchPeriod2}
                            onChange={(e) => setSearchPeriod2(e.target.value)}
                            className="w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:outline-none focus:border-blue-500"
                          />
                        </div>
                      </div>
                      <div className="max-h-64 overflow-y-auto">
                        {filterPeriods({ searchTerm: searchPeriod2, excludeId: selectedPeriod1?.id }).length > 0 ? (
                          filterPeriods({ searchTerm: searchPeriod2, excludeId: selectedPeriod1?.id }).map((period) => (
                            <button
                              key={period.id}
                              onClick={() => {
                                setSelectedPeriod2(period);
                                setOpenDropdown2(false);
                                setSearchPeriod2("");
                              }}
                              className={`w-full p-3 text-left border-b border-gray-200 dark:border-gray-700 transition ${selectedPeriod2?.id === period.id
                                ? "bg-blue-100 dark:bg-blue-900 text-blue-900 dark:text-blue-200"
                                : "hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-900 dark:text-white"
                                }`}
                            >
                              <p className="font-medium">{period.label}</p>
                              <p className="text-xs text-gray-500 dark:text-gray-400">
                                {period.period_type}
                              </p>
                            </button>
                          ))
                        ) : (
                          <p className="p-3 text-center text-gray-500 dark:text-gray-400">
                            No periods found
                          </p>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {/* Selected Periods Display with Interchange Button */}
              {(selectedPeriod1 || selectedPeriod2) && (
                <div className="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 p-6 rounded-lg mb-6 border border-blue-200 dark:border-blue-800">
                  <div className="flex flex-col lg:flex-row items-center justify-center gap-4">
                    {selectedPeriod1 && (
                      <div className="flex-1 w-full text-center">
                        <p className="text-xs text-gray-600 dark:text-gray-400 mb-1 uppercase tracking-wide font-semibold">Period 1</p>
                        <p className="font-bold text-gray-900 dark:text-white text-lg">{selectedPeriod1.label}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{selectedPeriod1.period_type}</p>
                      </div>
                    )}

                    {selectedPeriod1 && selectedPeriod2 && (
                      <button
                        onClick={() => {
                          // Animate spin
                          setSpinCount(prev => prev + 1);
                          // Interchange periods
                          setSelectedPeriod1(selectedPeriod2);
                          setSelectedPeriod2(selectedPeriod1);
                          setComparisonData(null); // Clear previous comparison
                        }}
                        className="flex items-center justify-center w-12 h-12 rounded-full border-2 border-blue-400 dark:border-blue-600 bg-white dark:bg-gray-800 hover:bg-blue-50 dark:hover:bg-blue-900/30 transition-all group"
                        title="Swap periods"
                      >
                        <div className="rotate-90 lg:rotate-0 transition-none">
                          <ArrowRightLeft
                            className="w-5 h-5 text-blue-600 dark:text-blue-400 transition-transform duration-500 ease-in-out"
                            style={{ transform: `rotate(${spinCount * 180}deg)` }}
                          />
                        </div>
                      </button>
                    )}

                    {selectedPeriod2 && (
                      <div className="flex-1 w-full text-center">
                        <p className="text-xs text-gray-600 dark:text-gray-400 mb-1 uppercase tracking-wide font-semibold">Period 2</p>
                        <p className="font-bold text-gray-900 dark:text-white text-lg">{selectedPeriod2.label}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{selectedPeriod2.period_type}</p>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* Compare Button */}
              <div className="flex gap-2 mb-8">
                <Button
                  onClick={handleCompare}
                  disabled={!selectedPeriod1 || !selectedPeriod2 || loadingComparison}
                  className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg"
                >
                  {loadingComparison ? "Comparing..." : "Compare Periods"}
                </Button>
              </div>

              {/* Comparison Results - displayed on same page below selection */}
              {comparisonData && (
                <>
                  <div className="border-t border-gray-300 dark:border-gray-600 pt-8 mt-8">
                    <div className="flex items-center justify-between mb-8">
                      <div>
                        <h4 className="text-2xl font-bold text-black dark:text-white mb-2">
                          Comparison Results
                        </h4>
                        <p className="text-gray-600 dark:text-gray-400">
                          Comparing <span className="font-semibold text-blue-600 dark:text-blue-400">{comparisonData.data.period1}</span> vs{" "}
                          <span className="font-semibold text-indigo-600 dark:text-indigo-400">{comparisonData.data.period2}</span>
                        </p>
                      </div>
                      <Button
                        onClick={handleBackFromComparison}
                        className="bg-gray-600 hover:bg-gray-700 text-white px-6 py-2 rounded-lg"
                      >
                        Clear Results
                      </Button>
                    </div>

                    {Object.keys(comparisonData.data.ratios).length === 0 ? (
                      <p className="text-center text-gray-500 dark:text-gray-400 py-8">
                        No ratio data available for comparison
                      </p>
                    ) : (
                      <>
                        {/* Summary Stats */}
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
                          <div className="bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 p-6 rounded-xl border border-green-200 dark:border-green-800">
                            <p className="text-sm font-semibold text-gray-600 dark:text-gray-400 mb-2 uppercase">Improved Ratios</p>
                            <p className="text-3xl font-bold text-green-600 dark:text-green-400">
                              {Object.values(comparisonData.data.ratios).filter(
                                (r) => r.percentage_change && r.percentage_change > 0
                              ).length}
                            </p>
                          </div>
                          <div className="bg-gradient-to-br from-red-50 to-rose-50 dark:from-red-900/20 dark:to-rose-900/20 p-6 rounded-xl border border-red-200 dark:border-red-800">
                            <p className="text-sm font-semibold text-gray-600 dark:text-gray-400 mb-2 uppercase">Declined Ratios</p>
                            <p className="text-3xl font-bold text-red-600 dark:text-red-400">
                              {Object.values(comparisonData.data.ratios).filter(
                                (r) => r.percentage_change && r.percentage_change < 0
                              ).length}
                            </p>
                          </div>
                          <div className="bg-gradient-to-br from-blue-50 to-cyan-50 dark:from-blue-900/20 dark:to-cyan-900/20 p-6 rounded-xl border border-blue-200 dark:border-blue-800">
                            <p className="text-sm font-semibold text-gray-600 dark:text-gray-400 mb-2 uppercase">Total Ratios</p>
                            <p className="text-3xl font-bold text-blue-600 dark:text-blue-400">
                              {Object.keys(comparisonData.data.ratios).length}
                            </p>
                          </div>
                        </div>

                        {/* Tabs for different views */}
                        <div className="mb-6 flex gap-2 border-b border-gray-300 dark:border-gray-600">
                          <button
                            onClick={() => setShowTableView(true)}
                            className={`px-4 py-3 font-semibold transition-colors ${showTableView
                              ? "border-b-2 border-blue-600 text-blue-600 dark:text-blue-400"
                              : "text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200"
                              }`}
                          >
                            📊 Table View
                          </button>
                          <button
                            onClick={() => setShowTableView(false)}
                            className={`px-4 py-3 font-semibold transition-colors ${!showTableView
                              ? "border-b-2 border-blue-600 text-blue-600 dark:text-blue-400"
                              : "text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200"
                              }`}
                          >
                            🎴 Card View
                          </button>
                        </div>

                        {/* Table View */}
                        {showTableView && (
                          <div className="overflow-x-auto rounded-lg border border-gray-300 dark:border-gray-600">
                            <table className="w-full table-auto">
                              <thead>
                                <tr className="bg-gray-100 dark:bg-gray-800">
                                  <th className="px-4 py-3 text-left font-semibold text-gray-900 dark:text-white">Ratio</th>
                                  <th className="px-4 py-3 text-right font-semibold text-gray-900 dark:text-white">{comparisonData.data.period1}</th>
                                  <th className="px-4 py-3 text-right font-semibold text-gray-900 dark:text-white">{comparisonData.data.period2}</th>
                                  <th className="px-4 py-3 text-right font-semibold text-gray-900 dark:text-white">Difference</th>
                                  <th className="px-4 py-3 text-right font-semibold text-gray-900 dark:text-white">% Change</th>
                                </tr>
                              </thead>
                              <tbody>
                                {Object.entries(comparisonData.data.ratios).map(([ratioName, ratioData]) => (
                                  <tr key={ratioName} className="border-b border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800/50">
                                    <td className="px-4 py-3 text-gray-900 dark:text-white font-medium">{formatRatioName(ratioName)}</td>
                                    <td className="px-4 py-3 text-right text-gray-700 dark:text-gray-300">
                                      {ratioData.period1 !== null ? ratioData.period1.toFixed(2) : "-"}
                                    </td>
                                    <td className="px-4 py-3 text-right text-gray-700 dark:text-gray-300">
                                      {ratioData.period2 !== null ? ratioData.period2.toFixed(2) : "-"}
                                    </td>
                                    <td className="px-4 py-3 text-right font-semibold">
                                      <span className={getChangeColor(ratioData.difference)}>
                                        {ratioData.difference !== null
                                          ? ratioData.difference > 0
                                            ? `+${ratioData.difference.toFixed(2)}`
                                            : ratioData.difference.toFixed(2)
                                          : "-"}
                                      </span>
                                    </td>
                                    <td className="px-4 py-3 text-right font-semibold">
                                      <span className={getChangeColor(ratioData.percentage_change)}>
                                        {ratioData.percentage_change !== null
                                          ? ratioData.percentage_change > 0
                                            ? `+${ratioData.percentage_change.toFixed(2)}%`
                                            : `${ratioData.percentage_change.toFixed(2)}%`
                                          : "-"}
                                      </span>
                                    </td>
                                  </tr>
                                ))}
                              </tbody>
                            </table>
                          </div>
                        )}

                        {/* Card View */}
                        {!showTableView && (
                          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                            {Object.entries(comparisonData.data.ratios).map(([ratioName, ratioData]) => {
                              const changePercentage = ratioData.percentage_change || 0;
                              const isPositive = changePercentage > 0;
                              const isNeutral = changePercentage === 0;

                              return (
                                <div
                                  key={ratioName}
                                  className={`p-5 rounded-xl border-2 transition-all hover:shadow-lg ${isPositive
                                    ? "bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 border-green-200 dark:border-green-800"
                                    : isNeutral
                                      ? "bg-gradient-to-br from-gray-50 to-slate-50 dark:from-gray-900/20 dark:to-slate-900/20 border-gray-200 dark:border-gray-700"
                                      : "bg-gradient-to-br from-red-50 to-rose-50 dark:from-red-900/20 dark:to-rose-900/20 border-red-200 dark:border-red-800"
                                    }`}
                                >
                                  <h5 className="font-semibold text-gray-900 dark:text-white text-sm mb-3 uppercase tracking-wide">
                                    {formatRatioName(ratioName)}
                                  </h5>
                                  <div className="space-y-2">
                                    <div className="flex justify-between items-end">
                                      <span className="text-xs text-gray-600 dark:text-gray-400">{comparisonData.data.period1}</span>
                                      <span className="text-lg font-bold text-gray-900 dark:text-white">
                                        {ratioData.period1 !== null ? ratioData.period1.toFixed(2) : "-"}
                                      </span>
                                    </div>
                                    <div className="flex justify-between items-end">
                                      <span className="text-xs text-gray-600 dark:text-gray-400">{comparisonData.data.period2}</span>
                                      <span className="text-lg font-bold text-gray-900 dark:text-white">
                                        {ratioData.period2 !== null ? ratioData.period2.toFixed(2) : "-"}
                                      </span>
                                    </div>
                                  </div>
                                  <div className={`mt-3 pt-3 border-t-2 ${isPositive ? "border-green-200 dark:border-green-800" : isNeutral ? "border-gray-200 dark:border-gray-700" : "border-red-200 dark:border-red-800"}`}>
                                    <div className="flex items-center justify-between">
                                      <span className="text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase">Change</span>
                                      <span className={`text-sm font-bold ${getChangeColor(ratioData.percentage_change)}`}>
                                        {isPositive && "+"}
                                        {ratioData.percentage_change !== null ? `${ratioData.percentage_change.toFixed(2)}%` : "-"}
                                      </span>
                                    </div>
                                    {ratioData.difference !== null && (
                                      <p className={`text-xs mt-1 ${getChangeColor(ratioData.difference)} font-semibold`}>
                                        {ratioData.difference > 0 ? "+" : ""}{ratioData.difference.toFixed(2)}
                                      </p>
                                    )}
                                  </div>
                                </div>
                              );
                            })}
                          </div>
                        )}
                      </>
                    )}
                  </div>
                </>
              )}
            </div>
          )}
        </div>
      </div>
    </>
  );
};

export default PeriodComparison;
