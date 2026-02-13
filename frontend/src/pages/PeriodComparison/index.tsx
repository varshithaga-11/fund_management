import React, { useState, useEffect } from "react";
import { BeatLoader } from "react-spinners";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import PageBreadcrumb from "../../components/common/PageBreadCrumb";
import PageMeta from "../../components/common/PageMeta";
import Button from "../../components/ui/button/Button";
import {
  getCompanies,
  getCompanyPeriods,
  comparePeriods,
  CompanyData,
  FinancialPeriodData,
  PeriodComparisonResponse,
} from "./api";
import { ArrowLeft, Search, ChevronDown } from "lucide-react";

const PeriodComparison: React.FC = () => {
  const [companies, setCompanies] = useState<CompanyData[]>([]);
  const [selectedCompany, setSelectedCompany] = useState<CompanyData | null>(null);
  const [periods, setPeriods] = useState<FinancialPeriodData[]>([]);
  const [selectedPeriod1, setSelectedPeriod1] = useState<FinancialPeriodData | null>(null);
  const [selectedPeriod2, setSelectedPeriod2] = useState<FinancialPeriodData | null>(null);
  const [comparisonData, setComparisonData] = useState<PeriodComparisonResponse | null>(null);
  const [searchPeriod1, setSearchPeriod1] = useState("");
  const [searchPeriod2, setSearchPeriod2] = useState("");
  const [openDropdown1, setOpenDropdown1] = useState(false);
  const [openDropdown2, setOpenDropdown2] = useState(false);

  const [loading, setLoading] = useState(true);
  const [loadingPeriods, setLoadingPeriods] = useState(false);
  const [loadingComparison, setLoadingComparison] = useState(false);

  useEffect(() => {
    loadCompanies();
  }, []);

  const loadCompanies = async () => {
    try {
      setLoading(true);
      const data = await getCompanies();
      setCompanies(data);
    } catch (error) {
      console.error("Error loading companies:", error);
      toast.error("Failed to load companies");
    } finally {
      setLoading(false);
    }
  };

  const handleSelectCompany = async (company: CompanyData) => {
    try {
      setSelectedCompany(company);
      setSelectedPeriod1(null);
      setSelectedPeriod2(null);
      setComparisonData(null);
      setLoadingPeriods(true);

      const periodsData = await getCompanyPeriods(company.id);
      setPeriods(periodsData);

      if (periodsData.length === 0) {
        toast.info("No financial periods found for this company");
      }
    } catch (error: any) {
      console.error("Error loading periods:", error);
      toast.error("Failed to load periods");
    } finally {
      setLoadingPeriods(false);
    }
  };

  const handleCompare = async () => {
    if (!selectedCompany || !selectedPeriod1 || !selectedPeriod2) {
      toast.warning("Please select both periods");
      return;
    }

    if (selectedPeriod1.id === selectedPeriod2.id) {
      toast.warning("Please select two different periods");
      return;
    }

    try {
      setLoadingComparison(true);
      const data = await comparePeriods(
        selectedCompany.id,
        selectedPeriod1.label,
        selectedPeriod2.label
      );
      setComparisonData(data);
      toast.success("Comparison loaded successfully");
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

  const handleBack = () => {
    setSelectedCompany(null);
    setSelectedPeriod1(null);
    setSelectedPeriod2(null);
    setComparisonData(null);
    setPeriods([]);
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

  const filterPeriods = (searchTerm: string, excludeId?: number): FinancialPeriodData[] => {
    return periods.filter((period) => {
      const matchesSearch =
        period.label.toLowerCase().includes(searchTerm.toLowerCase()) ||
        period.period_type.toLowerCase().includes(searchTerm.toLowerCase());
      const notExcluded = excludeId ? period.id !== excludeId : true;
      return matchesSearch && notExcluded;
    });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <BeatLoader color="#3b82f6" />
      </div>
    );
  }

  // Step 1: Show companies
  if (!selectedCompany) {
    return (
      <div>
        <PageMeta title="Period Comparison" description="Compare financial periods for companies" />
        <PageBreadcrumb pageTitle="Period Comparison" />

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

        <div className="rounded-sm border border-stroke bg-white px-5 pt-6 pb-2.5 shadow-default dark:border-strokedark dark:bg-boxdark sm:px-7.5 xl:pb-1">
          <h3 className="mb-6 text-xl font-semibold text-black dark:text-white">
            Select Company
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {companies.map((company) => (
              <button
                key={company.id}
                onClick={() => handleSelectCompany(company)}
                className="p-4 border border-gray-300 rounded-lg hover:border-blue-500 hover:bg-blue-50 dark:border-gray-600 dark:hover:bg-gray-700 transition text-left"
              >
                <h4 className="font-semibold text-gray-900 dark:text-white">
                  {company.name}
                </h4>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                  Reg: {company.registration_no}
                </p>
              </button>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // Step 2: Show period selection
  if (!comparisonData) {
    return (
      <div>
        <PageMeta title="Period Comparison" description="Select periods and compare financial ratios" />
        <PageBreadcrumb pageTitle="Period Comparison" />

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

        <div className="rounded-sm border border-stroke bg-white px-5 pt-6 pb-2.5 shadow-default dark:border-strokedark dark:bg-boxdark sm:px-7.5 xl:pb-1">
          <button
            onClick={handleBack}
            className="mb-6 flex items-center gap-2 text-blue-600 hover:text-blue-800"
          >
            <ArrowLeft className="w-4 h-4" />
            Back
          </button>

          <h3 className="mb-6 text-xl font-semibold text-black dark:text-white">
            Compare Periods for {selectedCompany.name}
          </h3>

          {loadingPeriods ? (
            <div className="flex items-center justify-center h-96">
              <BeatLoader color="#3b82f6" />
            </div>
          ) : periods.length === 0 ? (
            <p className="text-gray-500 dark:text-gray-400">
              No financial periods available for this company
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
                      className={`w-5 h-5 transition-transform ${
                        openDropdown1 ? "rotate-180" : ""
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
                        {filterPeriods(searchPeriod1, selectedPeriod2?.id).length > 0 ? (
                          filterPeriods(searchPeriod1, selectedPeriod2?.id).map((period) => (
                            <button
                              key={period.id}
                              onClick={() => {
                                setSelectedPeriod1(period);
                                setOpenDropdown1(false);
                                setSearchPeriod1("");
                              }}
                              className={`w-full p-3 text-left border-b border-gray-200 dark:border-gray-700 transition ${
                                selectedPeriod1?.id === period.id
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
                      className={`w-5 h-5 transition-transform ${
                        openDropdown2 ? "rotate-180" : ""
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
                        {filterPeriods(searchPeriod2, selectedPeriod1?.id).length > 0 ? (
                          filterPeriods(searchPeriod2, selectedPeriod1?.id).map((period) => (
                            <button
                              key={period.id}
                              onClick={() => {
                                setSelectedPeriod2(period);
                                setOpenDropdown2(false);
                                setSearchPeriod2("");
                              }}
                              className={`w-full p-3 text-left border-b border-gray-200 dark:border-gray-700 transition ${
                                selectedPeriod2?.id === period.id
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

              {/* Selected Periods Display */}
              {(selectedPeriod1 || selectedPeriod2) && (
                <div className="bg-gray-50 dark:bg-gray-800 p-4 rounded-lg mb-6">
                  <p className="text-sm text-gray-600 dark:text-gray-400">
                    {selectedPeriod1 && (
                      <span className="font-semibold">Period 1: {selectedPeriod1.label}</span>
                    )}
                    {selectedPeriod1 && selectedPeriod2 && <span className="mx-2">→</span>}
                    {selectedPeriod2 && (
                      <span className="font-semibold">Period 2: {selectedPeriod2.label}</span>
                    )}
                  </p>
                </div>
              )}

              {/* Compare Button */}
              <div className="flex gap-2">
                <Button
                  onClick={handleCompare}
                  disabled={!selectedPeriod1 || !selectedPeriod2 || loadingComparison}
                  className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg"
                >
                  {loadingComparison ? "Comparing..." : "Compare Periods"}
                </Button>
              </div>
            </div>
          )}
        </div>
      </div>
    );
  }

  // Step 3: Show comparison results
  return (
    <div>
      <PageMeta title="Period Comparison Results" description="View detailed comparison of financial periods" />
      <PageBreadcrumb pageTitle="Period Comparison Results" />

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

      <div className="rounded-sm border border-stroke bg-white px-5 pt-6 pb-2.5 shadow-default dark:border-strokedark dark:bg-boxdark sm:px-7.5 xl:pb-1">
        <button
          onClick={handleBackFromComparison}
          className="mb-6 flex items-center gap-2 text-blue-600 hover:text-blue-800"
        >
          <ArrowLeft className="w-4 h-4" />
          Back
        </button>

        <div className="mb-6">
          <h3 className="text-2xl font-semibold text-black dark:text-white mb-2">
            {comparisonData.data.company}
          </h3>
          <p className="text-gray-600 dark:text-gray-400">
            Comparing <span className="font-semibold">{comparisonData.data.period1}</span> vs{" "}
            <span className="font-semibold">{comparisonData.data.period2}</span>
          </p>
        </div>

        {/* Ratios Table */}
        <div className="overflow-x-auto">
          <table className="w-full table-auto border-collapse">
            <thead>
              <tr className="bg-gray-100 dark:bg-gray-800">
                <th className="border border-gray-300 dark:border-gray-600 px-4 py-3 text-left font-semibold text-gray-900 dark:text-white">
                  Ratio
                </th>
                <th className="border border-gray-300 dark:border-gray-600 px-4 py-3 text-right font-semibold text-gray-900 dark:text-white">
                  {comparisonData.data.period1}
                </th>
                <th className="border border-gray-300 dark:border-gray-600 px-4 py-3 text-right font-semibold text-gray-900 dark:text-white">
                  {comparisonData.data.period2}
                </th>
                <th className="border border-gray-300 dark:border-gray-600 px-4 py-3 text-right font-semibold text-gray-900 dark:text-white">
                  Difference
                </th>
                <th className="border border-gray-300 dark:border-gray-600 px-4 py-3 text-right font-semibold text-gray-900 dark:text-white">
                  % Change
                </th>
              </tr>
            </thead>
            <tbody>
              {Object.entries(comparisonData.data.ratios).map(([ratioName, ratioData]) => (
                <tr
                  key={ratioName}
                  className="border-b border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700"
                >
                  <td className="border border-gray-300 dark:border-gray-600 px-4 py-3 text-gray-900 dark:text-white font-medium">
                    {formatRatioName(ratioName)}
                  </td>
                  <td className="border border-gray-300 dark:border-gray-600 px-4 py-3 text-right text-gray-700 dark:text-gray-300">
                    {ratioData.period1 !== null ? ratioData.period1.toFixed(2) : "-"}
                  </td>
                  <td className="border border-gray-300 dark:border-gray-600 px-4 py-3 text-right text-gray-700 dark:text-gray-300">
                    {ratioData.period2 !== null ? ratioData.period2.toFixed(2) : "-"}
                  </td>
                  <td className="border border-gray-300 dark:border-gray-600 px-4 py-3 text-right font-semibold">
                    <span className={getChangeColor(ratioData.difference)}>
                      {ratioData.difference !== null
                        ? ratioData.difference > 0
                          ? `+${ratioData.difference.toFixed(2)}`
                          : ratioData.difference.toFixed(2)
                        : "-"}
                    </span>
                  </td>
                  <td className="border border-gray-300 dark:border-gray-600 px-4 py-3 text-right font-semibold">
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

        {Object.keys(comparisonData.data.ratios).length === 0 && (
          <p className="text-center text-gray-500 dark:text-gray-400 py-8">
            No ratio data available for comparison
          </p>
        )}
      </div>
    </div>
  );
};

export default PeriodComparison;
